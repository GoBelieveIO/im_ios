//
//  AsyncTCP.m
//  im
//
//  Created by houxh on 14-6-26.
//  Copyright (c) 2014年 potato. All rights reserved.
//

#import "AsyncTCP.h"
#import "util.h"
#include <netinet/in.h>
@interface AsyncTCP()
@property(nonatomic, strong)ConnectCB connect_cb;
@property(nonatomic, strong)ReadCB read_cb;
@property(nonatomic, strong)dispatch_source_t readSource;
@property(nonatomic, strong)dispatch_source_t writeSource;
@property(nonatomic)BOOL writeSourceActive;
@property(nonatomic)BOOL readSourceActive;
@property(nonatomic)int sock;
@property(nonatomic)BOOL connecting;
@property(nonatomic)NSMutableData *data;
@end

@implementation AsyncTCP

-(id)init {
    self = [super init];
    if (self) {
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

-(BOOL)connect:(NSString*)host port:(int)port cb:(ConnectCB)cb {
    int r;
    struct sockaddr_in addr;
    //todo nonblock
    NSLog(@"looking...");
    r = lookupAddr([host UTF8String], port, &addr);
    NSLog(@"looked:%d", r);
    int sockfd;

    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    sock_nonblock(sockfd, 1);
    do {
    	r = connect(sockfd, (const struct sockaddr*)&addr, sizeof(addr));
    } while (r == -1 && errno == EINTR);
    if (r == -1) {
        if (errno != EINPROGRESS) {
            close(sockfd);
            return FALSE;
        }
    }
    
    dispatch_queue_t queue = dispatch_get_main_queue();
    self.writeSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_WRITE, sockfd, 0, queue);
    __weak AsyncTCP *wself = self;
    dispatch_source_set_event_handler(self.writeSource, ^{
        [wself onWrite];
    });
    
    dispatch_resume(self.writeSource);
    self.writeSourceActive = YES;

    self.connecting = YES;
    self.connect_cb = cb;
    self.sock = sockfd;
    return TRUE;
}

-(void)onWrite {
    if (self.connecting) {
        int error;
        socklen_t errorsize = sizeof(int);
        getsockopt(self.sock, SOL_SOCKET, SO_ERROR, &error, &errorsize);
        if (error == EINPROGRESS)
            return;
        self.connecting = NO;
        self.connect_cb(self, error);
        return;
    }
    const char *p = [self.data bytes];
    int n = write_data(self.sock, (uint8_t*)p, self.data.length);
    if (n < 0) {
        NSLog(@"sock write error:%d", errno);
        dispatch_suspend(self.writeSource);
        self.writeSourceActive = NO;
        return;
    }
    self.data = [NSMutableData dataWithBytes:p+n length:self.data.length - n];
    if (self.data.length == 0) {
        dispatch_suspend(self.writeSource);
        self.writeSourceActive = NO;
    }
    return;
}

-(void)close {
    __block int count = 0;
    
    void (^on_cancel)() = ^{
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
}

-(void)write:(NSData*)data {
    [self.data appendData:data];
    if (!self.writeSourceActive && self.writeSource) {
        dispatch_resume(self.writeSource);
        self.writeSourceActive = YES;
    }
}

#define BUF_SIZE (64*1024)
-(void)onRead {
    while (1) {
        int nread;
        char buf[BUF_SIZE];
        
        do {
            nread = read(self.sock, buf, BUF_SIZE);
        }while (nread < 0 && errno == EINTR);
        
        if (nread < 0) {
            if (errno == EAGAIN || errno == EWOULDBLOCK) {
                return;
            } else {
                self.read_cb(self, nil, errno);
                return;
            }
        } else if (nread == 0) {
            self.read_cb(self, nil, 0);
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
-(void)startRead:(ReadCB)cb {
    dispatch_queue_t queue = dispatch_get_main_queue();
    self.readSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, self.sock, 0, queue);
    __weak AsyncTCP *wself = self;
    dispatch_source_set_event_handler(self.readSource, ^{
        [wself onRead];
    });
    dispatch_resume(self.readSource);
    self.readSourceActive = YES;
    self.read_cb = cb;
}

@end
