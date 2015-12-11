//
//  RoomViewController.m
//  im_demo
//
//  Created by houxh on 15/7/2.
//  Copyright (c) 2015年 beetle. All rights reserved.
//

#import "RoomViewController.h"
#import <imsdk/IMService.h>

@interface RoomViewController()<RoomMessageObserver, TCPConnectionObserver>
@property(nonatomic)int msgID;
@property(nonatomic)NSMutableDictionary *msgs;
@end

@implementation RoomViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"对话"
                                                             style:UIBarButtonItemStyleDone
                                                            target:self
                                                            action:@selector(returnMainTableViewController)];
    
    self.navigationItem.leftBarButtonItem = item;
    self.navigationItem.title = @"聊天室";

    [self addObserver];
    
    [[IMService instance] enterRoom:self.roomID];
    self.msgs = [NSMutableDictionary dictionary];
}

- (void)returnMainTableViewController {
    
    [self removeObserver];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
    
    [[IMService instance] leaveRoom:self.roomID];
}

- (int64_t)sender {
    return self.uid;
}

- (int64_t)receiver {
    return self.roomID;
}

- (void)loadConversationData {
    [self initTableViewData];
}

- (void)loadEarlierData {

}

- (BOOL)isInConversation:(IMessage*)msg {
    return YES;
}

-(void)addObserver {
    [super addObserver];
    [[IMService instance] addConnectionObserver:self];
    [[IMService instance] addRoomMessageObserver:self];
}

-(void)removeObserver {
    [super removeObserver];
    [[IMService instance] removeConnectionObserver:self];
    [[IMService instance] removeRoomMessageObserver:self];

}

//同IM服务器连接的状态变更通知
-(void)onConnectState:(int)state{
    if(state == STATE_CONNECTED){
        [self enableSend];
    } else {
        [self disableSend];
    }
}

-(void)onRoomMessage:(RoomMessage*)rm {
    IMessage *m = [[IMessage alloc] init];
    m.sender = rm.sender;
    m.receiver = rm.receiver;
    self.msgID = self.msgID + 1;
    m.msgLocalID = self.msgID;
    m.rawContent = rm.content;
    m.timestamp = [[NSDate date] timeIntervalSince1970];
    
    [self insertMessage:m];
}

-(void)onRoomMessageACK:(RoomMessage*)rm {
    NSNumber *k = [NSNumber numberWithLongLong:(long long)rm];
    NSNumber *o = [self.msgs objectForKey:k];
    int msgLocalID = [o intValue];
    
    IMessage *msg = [self getMessageWithID:msgLocalID];
    msg.flags = msg.flags|MESSAGE_FLAG_ACK;
}

-(void)onRoomMessageFailure:(RoomMessage*)rm {
    NSNumber *k = [NSNumber numberWithLongLong:(long long)rm];
    NSNumber *o = [self.msgs objectForKey:k];
    int msgLocalID = [o longValue];
    
    IMessage *msg = [self getMessageWithID:msgLocalID];
    msg.flags = msg.flags|MESSAGE_FLAG_FAILURE;
}


-(BOOL)saveMessage:(IMessage*)msg {
    self.msgID = self.msgID + 1;
    msg.msgLocalID = self.msgID;
    return YES;
}


-(BOOL)removeMessage:(IMessage*)msg {
    return YES;
    
}
-(BOOL)markMessageFailure:(IMessage*)msg {
    return YES;
}

-(BOOL)markMesageListened:(IMessage*)msg {
    return YES;
}

-(BOOL)eraseMessageFailure:(IMessage*)msg {
    return YES;
}



- (void)sendMessage:(IMessage*)message {
    RoomMessage *im = [[RoomMessage alloc] init];
    im.sender = message.sender;
    im.receiver = message.receiver;
    im.content = message.rawContent;
    [[IMService instance] sendRoomMessage:im];
    
    NSNumber *o = [NSNumber numberWithLongLong:message.msgLocalID];
    NSNumber *k = [NSNumber numberWithLongLong:(long long)im];
    [self.msgs setObject:o forKey:k];
}

@end
