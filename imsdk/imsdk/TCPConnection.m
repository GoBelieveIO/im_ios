//
//  TCPConnection.m
//  podcasting
//
//  Created by houxh on 15/6/25.
//  Copyright (c) 2015年 beetle. All rights reserved.
//

#import "TCPConnection.h"
#include <netdb.h>
#include <arpa/inet.h>

#ifdef ENABLE_SSL
#import "AsyncSSLTCP.h"
#else
#import "AsyncRawTCP.h"
#endif
#import "util.h"

@interface TCPConnection()
@property(atomic, copy) NSString *hostIP;
@property(atomic, assign) struct sockaddr_storage hostAddr;
@property(atomic, assign) time_t timestmap;

@property(nonatomic, assign)BOOL stopped;
@property(nonatomic, assign)BOOL isBackground;

@property(nonatomic, strong)dispatch_source_t connectTimer;
@property(nonatomic, strong)dispatch_source_t heartbeatTimer;
@property(nonatomic)time_t pingTimestamp;

@property(nonatomic)int connectFailCount;
@property(nonatomic)NSMutableArray *connectionObservers;

@property(nonatomic, copy) NSString *mainQueueLabel;
@property(nonatomic, copy) NSString *queueLabel;
@end


@implementation TCPConnection
-(id)init {
    self = [super init];
    if (self) {
        self.queue = dispatch_get_main_queue();
        const char *label = dispatch_queue_get_label(dispatch_get_main_queue());
        self.mainQueueLabel = label ? [[NSString alloc] initWithUTF8String:label] : @"";
        self.connectionObservers = [NSMutableArray array];
        self.connectState = STATE_UNCONNECTED;
        self.stopped = YES;
        self.suspended = YES;
        self.reachable = YES;
        self.isBackground = NO;
    }
    return self;
}

-(void)setQueue:(dispatch_queue_t)queue {
    _queue = queue;
    const char *label = dispatch_queue_get_label(queue);
    NSAssert(label && strlen(label) > 0, @"queue label null");
    self.queueLabel = label ? [[NSString alloc] initWithUTF8String:label] : @"";
}

-(void)createTimer {
    if (self.connectTimer != nil && self.heartbeatTimer != nil) {
        return;
    }
    
    dispatch_queue_t queue = self.queue;
    self.connectTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,queue);
    dispatch_source_set_event_handler(self.connectTimer, ^{
        [self connect];
    });
    
    self.heartbeatTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,queue);
    dispatch_source_set_event_handler(self.heartbeatTimer, ^{
        [self ping];
    });
}

-(void)onReachabilityChange:(BOOL)reachable {
    [self runOnWorkQueue:^{
        self.reachable = reachable;
        if (reachable) {
            NSLog(@"internet reachable");
            if (!self.stopped && !self.isBackground) {
                NSLog(@"reconnect im service");
                [self suspend];
                [self resume];
            }
        } else {
            NSLog(@"internet unreachable");
            if (!self.stopped) {
                [self suspend];
            }
        }
    }];
}

-(void)enterForeground {
    [self runOnWorkQueue:^{
        [self _enterForeground];
    }];
}

-(void)_enterForeground {
    NSLog(@"im service enter foreground");
    self.isBackground = NO;
    if (!self.stopped && self.reachable) {
        [self resume];
    }
}

-(void)enterBackground {
    [self runOnWorkQueue:^{
        [self _enterBackground];
    }];
}

-(void)_enterBackground {
    NSLog(@"im service enter background");
    self.isBackground = YES;
    if (!self.stopped) {
        [self suspend];
    }
}

-(void)start {
    [self runOnWorkQueue:^{
        [self _start];
    }];
}

-(void)_start {
    if (!self.host || !self.port) {
        NSLog(@"should init im server host and port");
        exit(1);
    }
    if (!self.stopped) {
        return;
    }
    NSLog(@"start im service");
    self.stopped = NO;
    [self createTimer];
    if (self.reachable) {
        [self resume];
    }
}

-(void)stop {
    [self runOnWorkQueue:^{
        [self _stop];
    }];
}

-(void)_stop {
    if (self.stopped) {
        return;
    }
    NSLog(@"stop im service");
    self.stopped = YES;
    
    [self suspend];
}

-(void)suspend {
    if (self.suspended) {
        return;
    }
    
    NSLog(@"suspend im service");
    self.suspended = YES;
    
    dispatch_suspend(self.connectTimer);
    dispatch_suspend(self.heartbeatTimer);
    
    [self onClose];
    self.connectState = STATE_UNCONNECTED;
    [self publishConnectState:STATE_UNCONNECTED];
    [self close];
}

-(void)resume {
    if (!self.suspended) {
        return;
    }
    NSLog(@"resume im service");
    self.suspended = NO;
    
    dispatch_time_t w = dispatch_walltime(NULL, 0);
    dispatch_source_set_timer(self.connectTimer, w, DISPATCH_TIME_FOREVER, 0);
    dispatch_resume(self.connectTimer);
    
    w = dispatch_walltime(NULL, self.heartbeatHZ);
    dispatch_source_set_timer(self.heartbeatTimer, w, self.heartbeatHZ*NSEC_PER_SEC, self.heartbeatHZ*NSEC_PER_SEC/2);
    dispatch_resume(self.heartbeatTimer);
    
    [self refreshHostIP];
}


-(void)reconnect2S {
    [self onClose];
    self.connectState = STATE_AUTHENTICATION_FAIL;
    [self publishConnectState:STATE_AUTHENTICATION_FAIL];
    
    self.connectFailCount = 2;
    [self close];
    [self startConnectTimer];
}

-(void)close {
    if (self.tcp) {
        NSLog(@"im service on close");
        [self.tcp flush];
        [self.tcp close];
        self.tcp = nil;
    }
}

-(void)startConnectTimer {
    if (self.stopped || self.suspended || self.isBackground) {
        return;
    }
    //重连
    int64_t t = 0;
    if (self.connectFailCount > 60) {
        t = 60ull*NSEC_PER_SEC;
    } else {
        t = self.connectFailCount*NSEC_PER_SEC;
    }
    
    dispatch_time_t w = dispatch_walltime(NULL, t);
    dispatch_source_set_timer(self.connectTimer, w, DISPATCH_TIME_FOREVER, 0);
    
    NSLog(@"start connect timer:%lld", t/NSEC_PER_SEC);
}

-(void)handleClose {
    [self onClose];
    self.connectState = STATE_UNCONNECTED;
    [self publishConnectState:STATE_UNCONNECTED];

    [self close];
    [self startConnectTimer];
}


-(BOOL)handleData:(NSData*)data {
    NSAssert(NO, @"not implmented");
    return NO;
}

-(void)onRead:(NSData*)data error:(int)err {
    if (err) {
        NSLog(@"tcp read err");
        [self handleClose];
        return;
    } else if (!data) {
        NSLog(@"tcp closed");
        [self handleClose];
        return;
    } else {
        self.pingTimestamp = 0;
        BOOL r = [self handleData:data];
        if (!r) {
            [self handleClose];
        }
    }
}

-(NSString*)IP2String:(struct in_addr)addr {
    char buf[64] = {0};
    const char *p = inet_ntop(AF_INET, &addr, buf, 64);
    if (p) {
        return [NSString stringWithUTF8String:p];
    }
    return nil;
}

-(NSString*)IPV62String:(struct in6_addr)addr {
    char buf[64] = {0};
    const char *p = inet_ntop(AF_INET6, &addr, buf, 64);
    if (p) {
        return [NSString stringWithUTF8String:p];
    }
    return nil;
}


-(NSString*)resolveIP:(NSString*)host address:(struct sockaddr*)address {
    struct addrinfo hints;
    struct addrinfo *result, *rp;
    int s;
    
    char buf[32];
    snprintf(buf, 32, "%d", 0);
    
    memset(&hints, 0, sizeof(struct addrinfo));
    hints.ai_family = PF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = IPPROTO_TCP;
    hints.ai_flags = AI_DEFAULT;
    
    NSString *port = [NSString stringWithFormat:@"%d", self.port];
    s = getaddrinfo([host UTF8String], [port UTF8String], &hints, &result);
    if (s != 0) {
        NSLog(@"get addr info error:%s", gai_strerror(s));
        return nil;
    }
    struct addrinfo *res;
    for (res = result; res; res = res->ai_next) {
        NSLog(@"family:%d socktype;%d protocol:%d", res->ai_family, res->ai_socktype, res->ai_protocol);
    }

    NSString *ip = nil;
    rp = result;
    if (rp != NULL) {
        if (rp->ai_family == AF_INET) {
            struct sockaddr_in *addr = (struct sockaddr_in*)rp->ai_addr;
            ip = [self IP2String:addr->sin_addr];
            memcpy(address, addr, sizeof(struct sockaddr_in));
        } else if (rp->ai_family == AF_INET6) {
            struct sockaddr_in6 *addr = (struct sockaddr_in6*)rp->ai_addr;
            ip = [self IPV62String:addr->sin6_addr];
            memcpy(address, addr, sizeof(struct sockaddr_in6));
        }
    }
    freeaddrinfo(result);
    return ip;
}

-(void)refreshHostIP {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSLog(@"refresh host ip...");
        struct sockaddr_storage addr = {0};
        NSString *ip = [self resolveIP:self.host address:(struct sockaddr*)&addr];
        NSLog(@"host:%@ ip:%@", self.host, ip);
        if ([ip length] > 0) {
            self.hostAddr = addr;
            self.hostIP = ip;
            self.timestmap = time(NULL);
        }
    });
}

-(void)connect {
    if (self.tcp) {
        return;
    }
    if (self.stopped) {
        NSLog(@"opps......");
        return;
    }
    
    if (self.hostIP.length == 0) {
        [self refreshHostIP];
        self.connectFailCount = self.connectFailCount + 1;
        [self startConnectTimer];
        return;
    }
    time_t now = time(NULL);
    if (now - self.timestmap > 5*60) {
        [self refreshHostIP];
    }
    
    self.pingTimestamp = 0;
    self.connectState = STATE_CONNECTING;
    [self publishConnectState:STATE_CONNECTING];
#ifdef ENABLE_SSL
    self.tcp = [[AsyncSSLTCP alloc] initWithQueue:self.queue];
#else
    self.tcp = [[AsyncRawTCP alloc] initWithQueue:self.queue];
#endif
    __weak TCPConnection *wself = self;
    struct sockaddr_storage addr = self.hostAddr;
    NSLog(@"tcp connect host:%@ host ip:%@", self.host, self.hostIP);
    BOOL r = [self.tcp connect:(struct sockaddr*)&addr cb:^(AsyncTCP *tcp, int err) {
        if (err) {
            NSLog(@"tcp connect err");
            wself.connectFailCount = wself.connectFailCount + 1;
            [wself close];
            self.connectState = STATE_CONNECTFAIL;
            [self publishConnectState:STATE_CONNECTFAIL];
            [self startConnectTimer];
            return;
        } else {
            NSLog(@"tcp connected");
            wself.connectFailCount = 0;
            self.connectState = STATE_CONNECTED;
            [self publishConnectState:STATE_CONNECTED];
            [wself.tcp startRead:^(AsyncTCP *tcp, NSData *data, int err) {
                [wself onRead:data error:err];
            }];
            [self onConnect];
        }
    }];
    if (!r) {
        NSLog(@"tcp connect err");
        wself.connectFailCount = wself.connectFailCount + 1;
        self.connectState = STATE_CONNECTFAIL;
        [self publishConnectState:STATE_CONNECTFAIL];
        
        self.tcp = nil;
        [self startConnectTimer];
    }
}

-(void)pong {
    self.pingTimestamp = 0;
}

-(BOOL)sendPing {
    NSAssert(NO, @"not implemented");
    return NO;
}

-(void)ping {
    if (self.pingTimestamp == 0 && [self sendPing]) {
        self.pingTimestamp = time(NULL);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            time_t now = time(NULL);
            if (self.pingTimestamp > 0 && now - self.pingTimestamp >= 3) {
                NSLog(@"ping timeout");
                [self handleClose];
            }
        });
    }
}

-(void)onConnect {
    
}
-(void)onClose {
    
}

-(void)addConnectionObserver:(id<TCPConnectionObserver>)ob {
    NSValue *value = [NSValue valueWithNonretainedObject:ob];
    if (![self.connectionObservers containsObject:value]) {
        [self.connectionObservers addObject:value];
    }
}
-(void)removeConnectionObserver:(id<TCPConnectionObserver>)ob {
    NSValue *value = [NSValue valueWithNonretainedObject:ob];
    [self.connectionObservers removeObject:value];
}


-(void)publishConnectState:(int)state {
    [self runOnMainThread:^{
        for (NSValue *value in self.connectionObservers) {
            id<TCPConnectionObserver> ob = [value nonretainedObjectValue];
            if ([ob respondsToSelector:@selector(onConnectState:)]) {
                [ob onConnectState:state];
            }
        }
    }];
}

-(void)runOnQueue:(NSString*)queueLabel block:(dispatch_block_t)block {
    const char *s = dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL);
    NSString *label = s ? [[NSString alloc] initWithUTF8String:s] : @"";
    
    if ([queueLabel isEqualToString:label]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            block();
        });
    }
}
-(void)runOnMainThread:(dispatch_block_t)block {
    [self runOnQueue:self.mainQueueLabel block:block];
}

-(void)runOnWorkQueue:(dispatch_block_t)block {
    [self runOnQueue:self.queueLabel block:block];
}

-(void)assertWorkQueue {
    if (@available(iOS 10.0, *)) {
        dispatch_assert_queue_debug(self.queue);
    } else {
        // Fallback on earlier versions
    }
}
@end
