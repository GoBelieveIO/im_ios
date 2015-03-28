//
//  IMService.m
//  im
//
//  Created by houxh on 14-6-26.
//  Copyright (c) 2014年 potato. All rights reserved.
//
#include <netdb.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#import "IMService.h"
#import "AsyncTCP.h"
#import "Message.h"
#import "util.h"
#import "GOReachability.h"

#define HEARTBEAT (180ull*NSEC_PER_SEC)

#define HOST  @"imnode.gobelieve.io"
#define PORT 23000

@interface IMService()
@property(nonatomic)int port;
@property(atomic, copy) NSString *hostIP;
@property(atomic, assign) time_t timestmap;

@property(nonatomic, assign)BOOL stopped;
@property(nonatomic, assign)BOOL suspended;
@property(nonatomic, assign)BOOL isBackground;

@property(nonatomic)AsyncTCP *tcp;
@property(nonatomic, strong)dispatch_source_t connectTimer;

@property(nonatomic, strong)dispatch_source_t heartbeatTimer;
@property(nonatomic)time_t pingTimestamp;

@property(nonatomic)int connectFailCount;
@property(nonatomic)int seq;
@property(nonatomic)NSMutableArray *observers;
@property(nonatomic)NSMutableData *data;
@property(nonatomic)NSMutableDictionary *peerMessages;
@property(nonatomic)NSMutableDictionary *groupMessages;

@property(nonatomic)GOReachability *reach;
@property(nonatomic)BOOL reachable;
@end

@implementation IMService
+(IMService*)instance {
    static IMService *im;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!im) {
            im = [[IMService alloc] init];
        }
    });
    return im;
}

-(id)init {
    self = [super init];
    if (self) {
        dispatch_queue_t queue = dispatch_get_main_queue();
        self.connectTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,queue);
        dispatch_source_set_event_handler(self.connectTimer, ^{
            [self connect];
        });

        self.heartbeatTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,queue);
        dispatch_source_set_event_handler(self.heartbeatTimer, ^{
            [self sendHeartbeat];
        });
        self.observers = [NSMutableArray array];
        self.data = [NSMutableData data];
        self.peerMessages = [NSMutableDictionary dictionary];
        self.groupMessages = [NSMutableDictionary dictionary];
        self.connectState = STATE_UNCONNECTED;
        self.stopped = YES;
        self.suspended = YES;
        self.reachable = YES;
        self.isBackground = NO;
        self.host = HOST;
        self.port = PORT;
    }
    return self;
}

-(void)startRechabilityNotifier {
    IMService *wself = self;
    self.reach = [GOReachability reachabilityForInternetConnection];
    
    self.reach.reachableBlock = ^(GOReachability*reach) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"internet reachable");
            wself.reachable = YES;
            if (wself != nil && !wself.stopped && !wself.isBackground) {
                [wself resume];
            }
        });
    };
    
    self.reach.unreachableBlock = ^(GOReachability*reach) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"internet unreachable");
            wself.reachable = NO;
            if (wself != nil && !wself.stopped) {
                [wself suspend];
            }
        });
    };
    
    [self.reach startNotifier];
}

-(void)enterForeground {
    NSLog(@"im service enter foreground");
    self.isBackground = NO;
    if (!self.stopped && self.reachable) {
        [self resume];
    }
}

-(void)enterBackground {
    NSLog(@"im service enter background");
    self.isBackground = YES;
    if (!self.stopped) {
        [self suspend];
    }
}

-(void)start {
    if (!self.host || !self.port) {
        NSLog(@"should init im server host and port");
        exit(1);
    }
    if (!self.stopped) {
        return;
    }
    NSLog(@"start im service");
    self.stopped = NO;
    if (self.reachable) {
        [self resume];
    }
}

-(void)stop {
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
    
    w = dispatch_walltime(NULL, HEARTBEAT);
    dispatch_source_set_timer(self.heartbeatTimer, w, HEARTBEAT, HEARTBEAT/2);
    dispatch_resume(self.heartbeatTimer);
    
    [self refreshHostIP];
}

-(void)close {
    if (self.tcp) {
        NSLog(@"im service on close");
        [self.tcp close];
        self.tcp = nil;
    }
}

-(void)startConnectTimer {
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
    self.connectState = STATE_UNCONNECTED;
    [self publishConnectState:STATE_UNCONNECTED];
    
    for (NSNumber *seq in self.peerMessages) {
        IMMessage *msg = [self.peerMessages objectForKey:seq];
        [self.peerMessageHandler handleMessageFailure:msg.msgLocalID uid:msg.receiver];
        [self publishPeerMessageFailure:msg];
    }
    
    for (NSNumber *seq in self.groupMessages) {
        IMMessage *msg = [self.peerMessages objectForKey:seq];
        [self.groupMessageHandler handleMessageFailure:msg.msgLocalID gid:msg.receiver];
        [self publishGroupMessageFailure:msg];
    }
    [self.peerMessages removeAllObjects];
    [self.groupMessages removeAllObjects];
    [self close];
    [self startConnectTimer];
}

-(void)handleACK:(Message*)msg {
    NSNumber *seq = (NSNumber*)msg.body;
    IMMessage *m = (IMMessage*)[self.peerMessages objectForKey:seq];
    IMMessage *m2 = (IMMessage*)[self.groupMessages objectForKey:seq];
    if (!m && !m2) {
        return;
    }
    if (m) {
        [self.peerMessageHandler handleMessageACK:m.msgLocalID uid:m.receiver];
        [self.peerMessages removeObjectForKey:seq];
        [self publishPeerMessageACK:m.msgLocalID uid:m.receiver];
    } else if (m2) {
        [self.groupMessageHandler handleMessageACK:m2.msgLocalID gid:m2.receiver];
        [self.groupMessages removeObjectForKey:seq];
        [self publishGroupMessageACK:m2.msgLocalID gid:m2.receiver];
    }
}

-(void)handleIMMessage:(Message*)msg {
    IMMessage *im = (IMMessage*)msg.body;
    [self.peerMessageHandler handleMessage:im];
    NSLog(@"peer message sender:%lld receiver:%lld content:%s", im.sender, im.receiver, [im.content UTF8String]);
    
    Message *ack = [[Message alloc] init];
    ack.cmd = MSG_ACK;
    ack.body = [NSNumber numberWithInt:msg.seq];
    [self sendMessage:ack];
    [self publishPeerMessage:im];
}

-(void)handleGroupIMMessage:(Message*)msg {
    IMMessage *im = (IMMessage*)msg.body;
    [self.groupMessageHandler handleMessage:im];
    NSLog(@"group message sender:%lld receiver:%lld content:%s", im.sender, im.receiver, [im.content UTF8String]);
    Message *ack = [[Message alloc] init];
    ack.cmd = MSG_ACK;
    ack.body = [NSNumber numberWithInt:msg.seq];
    [self sendMessage:ack];
    [self publishGroupMessage:im];
}

-(void)handleAuthStatus:(Message*)msg {
    int status = [(NSNumber*)msg.body intValue];
    NSLog(@"auth status:%d", status);
    if (status != 0) {
        //失效的accesstoken,2s后重新连接
        self.connectFailCount = 2;
        [self close];
        [self startConnectTimer];
        self.connectState = STATE_UNCONNECTED;
        [self publishConnectState:STATE_UNCONNECTED];
    }
}

-(void)handleInputing:(Message*)msg {
    MessageInputing *inputing = (MessageInputing*)msg.body;
    for (id<MessageObserver> ob in self.observers) {
        if ([ob respondsToSelector:@selector(onPeerInputing:)]) {
            [ob onPeerInputing:inputing.sender];
        }
    }
}

-(void)handlePeerACK:(Message*)msg {
    MessagePeerACK *ack = (MessagePeerACK*)msg.body;
    [self.peerMessageHandler handleMessageRemoteACK:ack.msgLocalID uid:ack.sender];
    
    for (id<MessageObserver> ob in self.observers) {
        if ([ob respondsToSelector:@selector(onPeerMessageRemoteACK:uid:)]) {
            [ob onPeerMessageRemoteACK:ack.msgLocalID uid:ack.sender];
        }
    }
}

-(void)handlePong:(Message*)msg {
    self.pingTimestamp = 0;
}

-(void)handleGroupNotification:(Message*)msg {
    NSString *notification = (NSString*)msg.body;
    NSLog(@"group notification:%@", notification);
    [self.groupMessageHandler handleGroupNotification:notification];
    for (id<MessageObserver> ob in self.observers) {
        if ([ob respondsToSelector:@selector(onGroupNotification:)]) {
            [ob onGroupNotification:notification];
        }
    }
    
    Message *ack = [[Message alloc] init];
    ack.cmd = MSG_ACK;
    ack.body = [NSNumber numberWithInt:msg.seq];
    [self sendMessage:ack];
}

-(void)publishPeerMessage:(IMMessage*)msg {
    for (id<MessageObserver> ob in self.observers) {
        if ([ob respondsToSelector:@selector(onPeerMessage:)]) {
            [ob onPeerMessage:msg];
        }
    }
}

-(void)publishPeerMessageACK:(int)msgLocalID uid:(int64_t)uid {
    for (id<MessageObserver> ob in self.observers) {
        if ([ob respondsToSelector:@selector(onPeerMessageACK:uid:)]) {
            [ob onPeerMessageACK:msgLocalID uid:uid];
        }
    }
}

-(void)publishPeerMessageFailure:(IMMessage*)msg {
    for (id<MessageObserver> ob in self.observers) {
        if ([ob respondsToSelector:@selector(onPeerMessageFailure:uid:)]) {
            [ob onPeerMessageFailure:msg.msgLocalID uid:msg.receiver];
        }
    }
}

-(void)publishGroupMessage:(IMMessage*)msg {
    for (id<MessageObserver> ob in self.observers) {
        if ([ob respondsToSelector:@selector(onGroupMessage:)]) {
            [ob onGroupMessage:msg];
        }
    }
}

-(void)publishGroupMessageACK:(int)msgLocalID gid:(int64_t)gid {
    for (id<MessageObserver> ob in self.observers) {
        if ([ob respondsToSelector:@selector(onGroupMessageACK:gid:)]) {
            [ob onGroupMessageACK:msgLocalID gid:gid];
        }
    }
}

-(void)publishGroupMessageFailure:(IMMessage*)msg {
    for (id<MessageObserver> ob in self.observers) {
        [ob onGroupMessageFailure:msg.msgLocalID gid:msg.receiver];
    }
}

-(void)publishConnectState:(int)state {
    for (id<MessageObserver> ob in self.observers) {
        if ([ob respondsToSelector:@selector(onConnectState:)]) {
            [ob onConnectState:state];
        }
    }
}

-(void)handleMessage:(Message*)msg {
    if (msg.cmd == MSG_AUTH_STATUS) {
        [self handleAuthStatus:msg];
    } else if (msg.cmd == MSG_ACK) {
        [self handleACK:msg];
    } else if (msg.cmd == MSG_IM) {
        [self handleIMMessage:msg];
    } else if (msg.cmd == MSG_GROUP_IM) {
        [self handleGroupIMMessage:msg];
    } else if (msg.cmd == MSG_INPUTING) {
        [self handleInputing:msg];
    } else if (msg.cmd == MSG_PEER_ACK) {
        [self handlePeerACK:msg];
    } else if (msg.cmd == MSG_PONG) {
        [self handlePong:msg];
    } else if (msg.cmd == MSG_GROUP_NOTIFICATION) {
        [self handleGroupNotification:msg];
    }
}

-(BOOL)handleData:(NSData*)data {
    [self.data appendData:data];
    int pos = 0;
    const uint8_t *p = [self.data bytes];
    while (YES) {
        if (self.data.length < pos + 4) {
            break;
        }
        int len = readInt32(p+pos);
        if (self.data.length < 4 + 8 + pos + len) {
            break;
        }
        NSData *tmp = [NSData dataWithBytes:p+4+pos length:len + 8];
        Message *msg = [[Message alloc] init];
        if (![msg unpack:tmp]) {
            NSLog(@"unpack message fail");
            return NO;
        }
        [self handleMessage:msg];
        pos += 4+8+len;
    }
    self.data = [NSMutableData dataWithBytes:p+pos length:self.data.length - pos];
    return YES;
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
        BOOL r = [self handleData:data];
        if (!r) {
            [self handleClose];
        }
    }
}

-(NSString*)resolveIP:(NSString*)host {
    struct addrinfo hints;
    struct addrinfo *result, *rp;
    int s;
    
    char buf[32];
    snprintf(buf, 32, "%d", 0);
    
    memset(&hints, 0, sizeof(struct addrinfo));
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = IPPROTO_TCP;
    hints.ai_flags = 0;
    
    s = getaddrinfo([host UTF8String], buf, &hints, &result);
    if (s != 0) {
        return nil;
    }
    NSString *ip = nil;
    if (result != NULL) {
        rp = result;
        struct sockaddr_in *addr = (struct sockaddr_in*)rp->ai_addr;
        const char *str = inet_ntoa(addr->sin_addr);
        ip = [NSString stringWithUTF8String:str];
    }
    
    freeaddrinfo(result);
    return ip;
}

-(void)refreshHostIP {
   
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSLog(@"refresh host ip...");
        NSString *ip = [self resolveIP:self.host];
        NSLog(@"host:%@ ip:%@", self.host, ip);
        if ([ip length] > 0) {
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
    
    self.connectState = STATE_CONNECTING;
    [self publishConnectState:STATE_CONNECTING];
    self.tcp = [[AsyncTCP alloc] init];
    __weak IMService *wself = self;
    BOOL r = [self.tcp connect:self.hostIP port:self.port cb:^(AsyncTCP *tcp, int err) {
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
            [self sendAuth];
            [wself.tcp startRead:^(AsyncTCP *tcp, NSData *data, int err) {
                [wself onRead:data error:err];
            }];
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

-(void)addMessageObserver:(id<MessageObserver>)ob {
    [self.observers addObject:ob];
}

-(void)removeMessageObserver:(id<MessageObserver>)ob {
    [self.observers removeObject:ob];
}

-(BOOL)sendPeerMessage:(IMMessage *)im {
    Message *m = [[Message alloc] init];
    m.cmd = MSG_IM;
    m.body = im;
    BOOL r = [self sendMessage:m];

    if (!r) {
        return r;
    }
    [self.peerMessages setObject:im forKey:[NSNumber numberWithInt:m.seq]];
    return r;
}

-(BOOL)sendGroupMessage:(IMMessage *)im {
    Message *m = [[Message alloc] init];
    m.cmd = MSG_GROUP_IM;
    m.body = im;
    BOOL r = [self sendMessage:m];
    
    if (!r) return r;
    [self.groupMessages setObject:im forKey:[NSNumber numberWithInt:m.seq]];
    return r;
}

-(BOOL)sendMessage:(Message *)msg {
    if (!self.tcp || self.connectState != STATE_CONNECTED) return NO;
    self.seq = self.seq + 1;
    msg.seq = self.seq;

    NSMutableData *data = [NSMutableData data];
    NSData *p = [msg pack];
    if (!p) {
        NSLog(@"message pack error");
        return NO;
    }
    char b[4];
    writeInt32(p.length-8, b);
    [data appendBytes:(void*)b length:4];
    [data appendData:p];
    [self.tcp write:data];
    return YES;
}

-(void)sendHeartbeat {
    time_t now = time(NULL);
    if (self.pingTimestamp > 0 && now - self.pingTimestamp > 60) {
        NSLog(@"ping timeout");
        [self handleClose];
        return;
    }
    
    NSLog(@"send ping");
    Message *msg = [[Message alloc] init];
    msg.cmd = MSG_PING;
    BOOL r = [self sendMessage:msg];
    if (r && self.pingTimestamp == 0) {
        self.pingTimestamp = now;
    }
}

-(void)sendAuth {
    NSLog(@"send auth");
    Message *msg = [[Message alloc] init];
    msg.cmd = MSG_AUTH_TOKEN;
    AuthenticationToken *auth = [[AuthenticationToken alloc] init];
    auth.token = self.token;
    auth.platformID = PLATFORM_IOS;
    auth.deviceID = self.deviceID;
    msg.body = auth;
    [self sendMessage:msg];
}

//正在输入
-(void)sendInputing:(MessageInputing*)inputing {
    Message *msg = [[Message alloc] init];
    msg.cmd = MSG_INPUTING;
    msg.body = inputing;
    [self sendMessage:msg];
}



@end
