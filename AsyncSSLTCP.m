/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "AsyncSSLTCP.h"
#import "util.h"
#include <netinet/in.h>
#include <netdb.h>
#include <arpa/inet.h>

#import <Security/Security.h>
#import <Security/SecureTransport.h>


#define BUF_SIZE (64*1024)

enum AsyncTCPState{
    TCP_CONNECTING,
    TCP_SSL_CONNECTING,
    TCP_READING,
    TCP_WRITING
};


@interface AsyncSSLTCP()
@property(nonatomic, strong)ConnectCB connect_cb;
@property(nonatomic, strong)ReadCB read_cb;
@property(nonatomic, strong)dispatch_source_t readSource;
@property(nonatomic, strong)dispatch_source_t writeSource;
@property(nonatomic)BOOL writeSourceActive;
@property(nonatomic)BOOL readSourceActive;
@property(nonatomic)int sock;
@property(nonatomic)NSMutableData *data;
@property(nonatomic, strong)dispatch_queue_t queue;

@property(nonatomic, assign) SSLContextRef sslContext;
@property(nonatomic, assign) int state;
@end

@implementation AsyncSSLTCP

-(id)init {
    self = [super init];
    if (self) {
        self.queue = dispatch_get_main_queue();
        self.data = [NSMutableData data];
        self.sock = -1;
    }
    return self;
}

-(id)initWithQueue:(dispatch_queue_t)queue {
    self = [super init];
    if (self) {
        self.queue = queue;
        self.data = [NSMutableData data];
        self.sock = -1;
    }
    return self;
}



-(void)dealloc {
    NSLog(@"async tcp dealloc");
    self.readSource = nil;
    self.writeSource = nil;
    self.connect_cb = nil;
    self.read_cb = nil;
    
}

-(BOOL)connect:(struct sockaddr*)addr cb:(ConnectCB)cb {
    int r;
    int sockfd;
    
    sockfd = socket(addr->sa_family, SOCK_STREAM, IPPROTO_TCP);
    sock_nonblock(sockfd, 1);
    
    int value = 1;
    setsockopt(sockfd, SOL_SOCKET, SO_NOSIGPIPE, &value, sizeof(value));
    
    do {
        if (addr->sa_family == AF_INET) {
            r = connect(sockfd, (struct sockaddr*)addr, sizeof(struct sockaddr_in));
        } else {
            //ipv6
            r = connect(sockfd, (struct sockaddr*)addr, sizeof(struct sockaddr_in6));
        }
    } while (r == -1 && errno == EINTR);
    if (r == -1) {
        if (errno != EINPROGRESS) {
            close(sockfd);
            NSLog(@"connect error:%s", strerror(errno));
            return FALSE;
        }
    }
    
    SSLContextRef sslContext = SSLCreateContext(kCFAllocatorDefault, kSSLClientSide, kSSLStreamType);
    OSStatus status = SSLSetIOFuncs(sslContext, &SSLReadFunction, &SSLWriteFunction);
    
    if (status != noErr) {
        NSLog(@"ssl error:%d", status);
    }
    status = SSLSetConnection(sslContext, (__bridge SSLConnectionRef)self);
    if (status != noErr) {
        NSLog(@"ssl error:%d", status);
        return NO;
    }
    
    //must set
    status = SSLSetProtocolVersionMin(sslContext,kSSLProtocol3);
    if (status != noErr) {
        NSLog(@"ssl error:%d", status);
        return NO;
    }
    
    dispatch_queue_t queue = self.queue;
    self.writeSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_WRITE, sockfd, 0, queue);
    __weak AsyncSSLTCP *wself = self;
    dispatch_source_set_event_handler(self.writeSource, ^{
        NSLog(@"socket writable");
        [wself onSocketEvent];
    });
    
    dispatch_resume(self.writeSource);
    self.writeSourceActive = YES;
    
    self.readSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, sockfd, 0, queue);
    dispatch_source_set_event_handler(self.readSource, ^{
        NSLog(@"socket readable");
        [wself onSocketEvent];
    });
    dispatch_resume(self.readSource);
    self.readSourceActive = YES;
    
    self.sslContext = sslContext;
    self.state = TCP_CONNECTING;
    self.connect_cb = cb;
    self.sock = sockfd;
    return TRUE;
}

-(BOOL)connect:(NSString*)host port:(int)port cb:(ConnectCB)cb {
    struct sockaddr_in6 addr;
    struct addrinfo addrinfo;
    
    BOOL res = [self synthesizeIPv6:host port:port addr:(struct sockaddr*)&addr addrinfo:&addrinfo];
    if (!res) {
        NSLog(@"synthesize ipv6 fail");
        return NO;
    }
    
    return [self connect:(struct sockaddr*)&addr cb:cb];
}

-(void)resumeWriteSource {
    if (!self.writeSourceActive) {
        NSLog(@"resume write source");
        dispatch_resume(self.writeSource);
        self.writeSourceActive = YES;
    }
}

-(void)suspendWriteSource {
    if (self.writeSourceActive) {
        NSLog(@"suspend write source");
        dispatch_suspend(self.writeSource);
        self.writeSourceActive = NO;
    }
}

-(void)onSocketEvent {
    if (self.state == TCP_CONNECTING) {
        int error;
        socklen_t errorsize = sizeof(int);
        getsockopt(self.sock, SOL_SOCKET, SO_ERROR, &error, &errorsize);
        if (error == EINPROGRESS)
            return;
        
        if (error != 0) {
            self.connect_cb(self, error);
            return;
        }
        
        self.state = TCP_SSL_CONNECTING;
        OSStatus status = SSLHandshake(self.sslContext);
        if (status == noErr) {
            NSLog(@"ssl handshake complete:%d", status);
            [self suspendWriteSource];
            self.state = TCP_READING;
            self.connect_cb(self, 0);
        } else if (status == errSSLWouldBlock) {
            NSLog(@"ssl handshake continues...");
        } else if (status == errSSLPeerAuthCompleted) {
            NSLog(@"errSSLPeerAuthCompleted, ssl handshake continues...");
        } else {
            NSLog(@"ssl handshake error:%d", status);
            self.connect_cb(self, status);
        }
        return;
    } else if (self.state == TCP_SSL_CONNECTING) {
        OSStatus status = SSLHandshake(self.sslContext);
        if (status == noErr) {
            NSLog(@"ssl handshake complete:%d", status);
            [self suspendWriteSource];
            self.state = TCP_READING;
            self.connect_cb(self, 0);
        } else if (status == errSSLWouldBlock) {
            NSLog(@"ssl handshake continues...");
        } else if (status == errSSLPeerAuthCompleted) {
            NSLog(@"errSSLPeerAuthCompleted, ssl handshake continues...");
        } else {
            NSLog(@"ssl handshake error:%d", status);
            self.connect_cb(self, status);
        }
    } else if (self.state == TCP_WRITING) {
        if (self.data.length == 0) {
            [self suspendWriteSource];
            self.state = TCP_READING;
            return;
        }
        
        size_t processed = 0;
        const char *p = [self.data bytes];
        OSStatus status = SSLWrite(self.sslContext, p, (int)self.data.length, &processed);
        if (status == noErr){
            self.data = [NSMutableData dataWithBytes:p+processed length:self.data.length - processed];
            if (self.data.length == 0) {
                [self suspendWriteSource];
                self.state = TCP_READING;
            }
        } else if (status == errSSLWouldBlock) {
            [self resumeWriteSource];
            return;
        } else {
            NSLog(@"ssl sock write error:%d", status);
            self.read_cb(self, nil, status);
        }
    } else if (self.state == TCP_READING) {
        while (1) {
            char buf[BUF_SIZE];
            size_t processed = 0;
            OSStatus r = SSLRead(self.sslContext, buf, BUF_SIZE, &processed);
            if (r == noErr) {
                NSData *data = [NSData dataWithBytes:buf length:processed];
                self.read_cb(self, data, 0);
            } else if (r == errSSLWouldBlock) {
                break;
            } else {
                NSLog(@"sock read error:%d", r);
                self.read_cb(self, nil, r);
                return;
            }
        }
    }
}


-(void)close {
    __block int count = 0;
    
    void (^on_cancel)(void) = ^{
        --count;
        if (count == 0) {
            NSLog(@"async tcp closed");
        }
    };
    
    if (self.writeSource) count++;
    if (self.readSource) count++;
    if (self.writeSource) {
        NSLog(@"cancel write source");
        if (!self.writeSourceActive) {
            dispatch_resume(self.writeSource);
            self.writeSourceActive = YES;
        }
        dispatch_source_set_cancel_handler(self.writeSource, on_cancel);
        dispatch_source_cancel(self.writeSource);
    }
    
    if (self.readSource) {
        NSLog(@"cancel read source");
        if (!self.readSourceActive) {
            dispatch_resume(self.readSource);
            self.readSourceActive = YES;
        }
        dispatch_source_set_cancel_handler(self.readSource, on_cancel);
        dispatch_source_cancel(self.readSource);
    }
    
    if (self.sslContext) {
        SSLClose(self.sslContext);
        CFRelease(self.sslContext);
        self.sslContext = NULL;
    }
    
    if (self.sock != -1) {
        NSLog(@"close socket");
        //because event handler and close both be called on main thread
        //here can safely close socket
        close(self.sock);
        self.sock = -1;
    }
    
}

-(void)write:(NSData*)data {
    [self.data appendData:data];
    
    if (self.state != TCP_READING) {
        return;
    }
    
    [self flush];
    
    if (self.data.length > 0) {
        [self resumeWriteSource];
        self.state = TCP_WRITING;
    }
}

-(void)flush {
    if (self.data.length == 0) {
        return;
    }
    const char *p = [self.data bytes];
    size_t processed = 0;
    int r = SSLWrite(self.sslContext, p, (int)self.data.length, &processed);
    if (r != noErr) {
        NSLog(@"ssl sock write error:%d", r);
        return;
    }
    self.data = [NSMutableData dataWithBytes:p+processed length:self.data.length - processed];
}


-(void)startRead:(ReadCB)cb {
    self.read_cb = cb;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Security via SecureTransport
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (OSStatus)sslReadWithBuffer:(void *)buffer length:(size_t *)bufferLength {
    int socketFD = self.sock;
    
    BOOL done = NO;
    BOOL socketError = NO;
    size_t bytesToRead;
    
    bytesToRead = *bufferLength;
    
    ssize_t result;
    do {
        result = read(socketFD, buffer, bytesToRead);
    } while (result < 0 && errno == EINTR);
    
    if (result < 0) {
        //before access errno, do not call any function
        int err = errno;
        if (errno != EWOULDBLOCK) {
            socketError = YES;
            NSLog(@"socket read errno:%d, %s", err, strerror(err));
        }
        *bufferLength = 0;
        
    } else if (result == 0) {
        socketError = YES;
        *bufferLength = 0;
    } else {
        done = (*bufferLength == result);
        *bufferLength = result;
    }
    
    if (done) {
        return noErr;
    }
    
    if (socketError) {
        return errSSLClosedAbort;
    }
    
    [self suspendWriteSource];
    return errSSLWouldBlock;
}

- (OSStatus)sslWriteWithBuffer:(const void *)buffer length:(size_t *)bufferLength {
    size_t bytesToWrite = *bufferLength;
    size_t bytesWritten = 0;
    
    BOOL done = NO;
    BOOL socketError = NO;
    int socketFD = self.sock;
    
    ssize_t result = write(socketFD, buffer, bytesToWrite);
    if (result < 0) {
        //before access errno, do not call any function
        int err = errno;
        if (errno != EWOULDBLOCK) {
            socketError = YES;
            NSLog(@"socket write errno:%d, %s", err, strerror(err));
        }
    } else {
        bytesWritten = result;
        done = (bytesWritten == bytesToWrite);
    }
    
    *bufferLength = bytesWritten;
    if (done) {
        return noErr;
    }
    if (socketError) {
        return errSSLClosedAbort;
    }
    [self resumeWriteSource];
    return errSSLWouldBlock;
}

static OSStatus SSLReadFunction(SSLConnectionRef connection, void *data, size_t *dataLength) {
    AsyncSSLTCP *asyncSocket = (__bridge AsyncSSLTCP *)connection;
    return [asyncSocket sslReadWithBuffer:data length:dataLength];
}

static OSStatus SSLWriteFunction(SSLConnectionRef connection, const void *data, size_t *dataLength) {
    AsyncSSLTCP *asyncSocket = (__bridge AsyncSSLTCP *)connection;
    return [asyncSocket sslWriteWithBuffer:data length:dataLength];
}


@end
