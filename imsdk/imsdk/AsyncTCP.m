/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "AsyncTCP.h"
#import "util.h"
#include <netinet/in.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <openssl/ssl.h>

#define BUF_SIZE (64*1024)

enum AsyncTCPState{
    TCP_CONNECTING,
    TCP_SSL_CONNECTING,
    TCP_READING,
    TCP_WRITING
};


@interface AsyncTCP()
@property(nonatomic, strong)ConnectCB connect_cb;
@property(nonatomic, strong)ReadCB read_cb;
@property(nonatomic, strong)dispatch_source_t readSource;
@property(nonatomic, strong)dispatch_source_t writeSource;
@property(nonatomic)BOOL writeSourceActive;
@property(nonatomic)BOOL readSourceActive;
@property(nonatomic)int sock;
@property(nonatomic)NSMutableData *data;

@property(nonatomic, assign) SSL_CTX *ctx;
@property(nonatomic, assign) SSL *ssl;
@property(nonatomic, assign) int state;
@end

@implementation AsyncTCP

-(id)init {
    self = [super init];
    if (self) {
        self.data = [NSMutableData data];
        self.sock = -1;
        self.ctx = SSL_CTX_new(SSLv23_client_method());
    }
    return self;
}

-(void)dealloc {
    NSLog(@"async tcp dealloc");
    self.readSource = nil;
    self.writeSource = nil;
    self.connect_cb = nil;
    self.read_cb = nil;
    
    SSL_CTX_free(self.ctx);
}

- (BOOL)synthesizeIPv6:(NSString*)host port:(int)port addr:(struct sockaddr*)addr addrinfo:(struct addrinfo*)info {
    int error;
    struct addrinfo hints, *res0, *res;
    const char *ipv4_str = [host UTF8String];
    
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = PF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_DEFAULT;
    error = getaddrinfo(ipv4_str, "", &hints, &res0);
    if (error) {
        NSLog(@"%s", gai_strerror(error));
        return FALSE;
    }

    for (res = res0; res; res = res->ai_next) {
        NSLog(@"family:%d socktype;%d protocol:%d", res->ai_family, res->ai_socktype, res->ai_protocol);
    }
    
    BOOL r = YES;
    //use first
    if (res0) {
        if (res0->ai_family == AF_INET6) {
            struct sockaddr_in6 *addr6 = ((struct sockaddr_in6*)res0->ai_addr);
            addr6->sin6_port = htons(port);
            
            memcpy(addr, res0->ai_addr, res0->ai_addrlen);
            *info = *res0;
        } else if (res0->ai_family == AF_INET) {
            struct sockaddr_in *addr4 = ((struct sockaddr_in*)res0->ai_addr);
            addr4->sin_port = htons(port);
            
            memcpy(addr, res0->ai_addr, res0->ai_addrlen);
            *info = *res0;
        } else {
            r = NO;
        }
    }

    freeaddrinfo(res0);
    return r;
}

-(BOOL)connect:(NSString*)host port:(int)port cb:(ConnectCB)cb {
    struct sockaddr_in6 addr;
    struct addrinfo addrinfo;
    
    BOOL res = [self synthesizeIPv6:host port:port addr:(struct sockaddr*)&addr addrinfo:&addrinfo];
    if (!res) {
        NSLog(@"synthesize ipv6 fail");
        return NO;
    }
    
    int r;
    int sockfd;
    
    sockfd = socket(addrinfo.ai_family, addrinfo.ai_socktype, addrinfo.ai_protocol);
    sock_nonblock(sockfd, 1);
    
    int value = 1;
    setsockopt(sockfd, SOL_SOCKET, SO_NOSIGPIPE, &value, sizeof(value));

    do {
        if (addrinfo.ai_family == AF_INET) {
            r = connect(sockfd, (struct sockaddr*)&addr, sizeof(struct sockaddr_in));
        } else {
            //ipv6
            r = connect(sockfd, (struct sockaddr*)&addr, sizeof(struct sockaddr_in6));
        }
    } while (r == -1 && errno == EINTR);
    if (r == -1) {
        if (errno != EINPROGRESS) {
            close(sockfd);
            NSLog(@"connect error:%s", strerror(errno));
            return FALSE;
        }
    }

    
    dispatch_queue_t queue = dispatch_get_main_queue();
    self.writeSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_WRITE, sockfd, 0, queue);
    __weak AsyncTCP *wself = self;
    dispatch_source_set_event_handler(self.writeSource, ^{
        [wself onSocketEvent];
    });
    
    dispatch_resume(self.writeSource);
    self.writeSourceActive = YES;
    
    self.readSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, sockfd, 0, queue);
    dispatch_source_set_event_handler(self.readSource, ^{
        [wself onSocketEvent];
    });
    dispatch_resume(self.readSource);
    self.readSourceActive = YES;
    
    SSL *ssl = SSL_new(self.ctx);
    SSL_set_mode(ssl, SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER);
    SSL_set_fd(ssl, sockfd);
    self.ssl = ssl;
    self.state = TCP_CONNECTING;
    self.connect_cb = cb;
    self.sock = sockfd;
    return TRUE;
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
        int r = SSL_connect(self.ssl);
        if (r <= 0) {
            int e = SSL_get_error(self.ssl, r);
            if (e == SSL_ERROR_WANT_WRITE) {
                [self resumeWriteSource];
                return;
            }
            if (e == SSL_ERROR_WANT_READ) {
                [self suspendWriteSource];
                return;
            }
            self.connect_cb(self, e);
        } else {
            [self suspendWriteSource];
            self.state = TCP_READING;
            self.connect_cb(self, 0);
        }
        return;
    } else if (self.state == TCP_SSL_CONNECTING) {
        int r = SSL_connect(self.ssl);
        if (r <= 0) {
            int e = SSL_get_error(self.ssl, r);
            if (e == SSL_ERROR_WANT_WRITE) {
                [self resumeWriteSource];
                return;
            }
            if (e == SSL_ERROR_WANT_READ) {
                [self suspendWriteSource];
                return;
            }
            self.connect_cb(self, e);
        } else {
            [self suspendWriteSource];
            self.state = TCP_READING;
            self.connect_cb(self, 0);
        }
    } else if (self.state == TCP_WRITING) {
        if (self.data.length == 0) {
            [self suspendWriteSource];
            self.state = TCP_READING;
            return;
        }
        
        const char *p = [self.data bytes];
        int n = SSL_write(self.ssl, p, (int)self.data.length);
        if (n <= 0) {
            int e = SSL_get_error(self.ssl, n);
            if (e == SSL_ERROR_WANT_WRITE) {
                [self resumeWriteSource];
                return;
            }
            if (e == SSL_ERROR_WANT_READ) {
                //do not support ssl renegotiation, drop connection
                NSLog(@"ssl write, err:want_read, do not support renegotiation, drop connection");
            }
            NSLog(@"sock write error:%d", e);
            self.read_cb(self, nil, e);
            return;
        }
        
        self.data = [NSMutableData dataWithBytes:p+n length:self.data.length - n];
        if (self.data.length == 0) {
            [self suspendWriteSource];
            self.state = TCP_READING;
        }
    } else if (self.state == TCP_READING) {
        while (1) {
            ssize_t nread;
            char buf[BUF_SIZE];
            nread = SSL_read(self.ssl, buf, BUF_SIZE);
            if (nread <= 0) {
                int e = SSL_get_error(self.ssl, (int)nread);
                if (e == SSL_ERROR_WANT_READ) {
                    [self suspendWriteSource];
                    return;
                }
                if (e == SSL_ERROR_WANT_WRITE) {
                    //do not support ssl renegotiation, drop connection
                    NSLog(@"ssl read, err:want write, do not support renegotiation, drop connection");
                }
                NSLog(@"sock read error:%d", e);
                self.read_cb(self, nil, e);
                return;
            } else {
                NSData *data = [NSData dataWithBytes:buf length:nread];
                self.read_cb(self, data, 0);
                if (nread < BUF_SIZE) {
                    return;
                }
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
    
    if (self.sock != -1) {
        NSLog(@"close socket");
        //because event handler and close both be called on main thread
        //here can safely close socket
        close(self.sock);
        self.sock = -1;
    }
    if (self.ssl) {
        SSL_free(self.ssl);
        self.ssl = NULL;
    }
}

-(void)write:(NSData*)data {
    [self.data appendData:data];
    
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
    
    int n = SSL_write(self.ssl, p, (int)self.data.length);
    if (n <= 0) {
        int e = SSL_get_error(self.ssl, n);
        NSLog(@"sock write error:%d", e);
        return;
    }
    self.data = [NSMutableData dataWithBytes:p+n length:self.data.length - n];
}



-(void)startRead:(ReadCB)cb {
    self.read_cb = cb;
}

@end
