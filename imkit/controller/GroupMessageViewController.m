/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "GroupMessageViewController.h"

#import "FileCache.h"
#import "GroupOutbox.h"
#import "AudioDownloader.h"
#import "IMessage.h"
#import "GroupMessageDB.h"
#import "UIImage+Resize.h"
#import <SDWebImage/SDImageCache.h>
#import "GroupMessageDB.h"
#import "UIView+Toast.h"


@interface GroupMessageViewController ()

@end

@implementation GroupMessageViewController

- (void)viewDidLoad {
    self.messageDB = [GroupMessageDB instance];
    self.callEnabled = NO;
    self.isShowReaded = NO;
    self.isShowUserName = YES;
    [super viewDidLoad];
    
    self.navigationItem.title = self.groupName;
}


-(void)addObserver {
    [super addObserver];
    [[GroupOutbox instance] addBoxObserver:self];
    [[IMService instance] addConnectionObserver:self];
    [[IMService instance] addGroupMessageObserver:self];
}

-(void)removeObserver {
    [super removeObserver];
    [[GroupOutbox instance] removeBoxObserver:self];
    [[IMService instance] removeGroupMessageObserver:self];
    [[IMService instance] removeConnectionObserver:self];
}

-(void)onBack {
    [super onBack];
    NSNotification* notification = [[NSNotification alloc] initWithName:CLEAR_GROUP_NEW_MESSAGE
                                                                 object:[NSNumber numberWithLongLong:self.groupID]
                                                               userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

//同IM服务器连接的状态变更通知
-(void)onConnectState:(int)state{
    if(state == STATE_CONNECTED){
        [self enableSend];
    } else {
        [self disableSend];
    }
}



#pragma mark - GroupMessageObserver
-(void)onGroupMessages:(NSArray*)msgs {
    for (IMMessage *im in msgs) {
        if (im.isGroupNotification) {
            [self onGroupNotification:im.content];
        } else {
            [self onGroupMessage:im];
        }
    }
}

-(void)onGroupMessage:(IMMessage*)im {
    if (im.receiver != self.groupID) {
        return;
    }

    IMessage *m = [[IMessage alloc] init];
    m.sender = im.sender;
    m.receiver = im.receiver;
    m.msgId = im.msgLocalID;
    m.rawContent = im.content;
    m.timestamp = im.timestamp;
    m.isOutgoing = (im.sender == self.currentUID);
    if (im.sender == self.currentUID) {
        m.flags = m.flags | MESSAGE_FLAG_ACK;
    }
    IMessage *mm = [self getMessageWithUUID:m.uuid];
    if (mm) {
        NSLog(@"receive repeat group msg:%@", m.uuid);
        //清空消息失败标志位
        if (im.sender == self.currentUID) {
            int flags = mm.flags;
            flags = flags & ~MESSAGE_FLAG_FAILURE;
            flags = flags | MESSAGE_FLAG_ACK;
            mm.flags = flags;
        }
        return;
    }
    if (im.isSelf) {
        return;
    }

    [self loadSenderInfo:m];
    [self downloadMessageContent:m];
    [self updateNotificationDesc:m];

    if (m.type == MESSAGE_REVOKE) {
        MessageRevoke *r = m.revokeContent;
        IMessage *revokedMsg = [self getMessageWithUUID:r.msgid];
        [self replaceMessage:revokedMsg dest:m];
    } else {
        [self insertMessage:m];
    }
}

-(void)onGroupMessageACK:(IMMessage*)im error:(int)error {
    int msgLocalID = im.msgLocalID;
    int64_t gid = im.receiver;
    
    if (gid != self.groupID) {
        return;
    }
    if (error == MSG_ACK_SUCCESS) {
        if (im.msgLocalID > 0) {
            IMessage *msg = [self getMessageWithID:msgLocalID];
            msg.flags = msg.flags|MESSAGE_FLAG_ACK;
        } else {
            MessageContent *content = [IMessage fromRaw:im.content];
            if (content.type == MESSAGE_REVOKE) {
                MessageRevoke *r = (MessageRevoke*)content;
                IMessage *revokedMsg = [self getMessageWithUUID:r.msgid];
                if (!revokedMsg) {
                    return;
                }
                IMessage *revokeMsg = [revokedMsg copy];
                revokeMsg.content = r;
                [self updateNotificationDesc:revokeMsg];
                [self replaceMessage:revokedMsg dest:revokeMsg];
            }
        }
    } else {
        if (im.msgLocalID > 0) {
            IMessage *msg = [self getMessageWithID:msgLocalID];
            msg.flags = msg.flags|MESSAGE_FLAG_FAILURE;
        } else {
            MessageContent *content = [IMessage fromRaw:im.content];
            if (content.type == MESSAGE_REVOKE) {
                [self.view makeToast:@"撤回失败" duration:0.7 position:@"bottom"];
            }
        }
    }
}

-(void)onGroupMessageFailure:(IMMessage*)im {
    int msgLocalID = im.msgLocalID;
    int64_t gid = im.receiver;
    
    if (gid != self.groupID) {
        return;
    }
    if (im.msgLocalID > 0) {
        IMessage *msg = [self getMessageWithID:msgLocalID];
        msg.flags = msg.flags|MESSAGE_FLAG_FAILURE;
    } else {
        MessageContent *content = [IMessage fromRaw:im.content];
        if (content.type == MESSAGE_REVOKE) {
            [self.view makeToast:@"撤回失败" duration:0.7 position:@"bottom"];
        }
    }
}


-(void)onGroupNotification:(NSString *)text {
    MessageGroupNotificationContent *notification = [[MessageGroupNotificationContent alloc] initWithNotification:text];
    int64_t groupID = notification.groupID;
    if (groupID != self.groupID) {
        return;
    }
    
    IMessage *msg = [[IMessage alloc] init];
    msg.sender = 0;
    msg.receiver = groupID;
    if (notification.timestamp > 0) {
        msg.timestamp = notification.timestamp;
    } else {
        msg.timestamp = (int)time(NULL);
    }
    msg.rawContent = notification.raw;
    
    [self updateNotificationDesc:msg];
    
    [self insertMessage:msg];
}


-(BOOL)getMessageOutgoing:(IMessage*)msg {
    return (msg.sender == self.currentUID);
}

-(id<IMessageIterator>)newMessageIterator {
    return [self.messageDB newMessageIterator: self.groupID];
}

//下拉刷新
-(id<IMessageIterator>)newForwardMessageIterator:(int64_t)messageID {
    return [self.messageDB newForwardMessageIterator:self.groupID messageID:messageID];
}

//上拉刷新
-(id<IMessageIterator>)newBackwardMessageIterator:(int64_t)messageID {
    return [self.messageDB newBackwardMessageIterator:self.groupID messageID:messageID];
}



- (void)sendMessage:(IMessage*)message {
    if (message.type == MESSAGE_AUDIO) {
        message.uploading = YES;
        [[GroupOutbox instance] uploadAudio:message];
    } else if (message.type == MESSAGE_IMAGE) {
        message.uploading = YES;
        [[GroupOutbox instance] uploadImage:message];
    } else if (message.type == MESSAGE_VIDEO) {
        message.uploading = YES;
        [[GroupOutbox instance] uploadVideo:message];
    } else if (message.type == MESSAGE_FILE) {
        message.uploading = YES;
        [[GroupOutbox instance] uploadFile:message];
    } else {
        IMMessage *im = [[IMMessage alloc] init];
        im.sender = message.sender;
        im.receiver = message.receiver;
        im.msgLocalID = message.msgId;
        im.isText = YES;
        im.content = message.rawContent;
        [[IMService instance] sendGroupMessageAsync:im];
    }
    
    NSNotification* notification = [[NSNotification alloc] initWithName:LATEST_GROUP_MESSAGE
                                                                 object:message userInfo:nil];
    
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)sendMessage:(IMessage *)msg withImage:(UIImage*)image {
    msg.uploading = YES;
    [[GroupOutbox instance] uploadImage:msg withImage:image];
    
    NSNotification* notification = [[NSNotification alloc] initWithName:LATEST_GROUP_MESSAGE
                                                                 object:msg userInfo:nil];
    
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

-(IMessage*)newOutMessage:(MessageContent*)content {
    IMessage *msg = [[IMessage alloc] init];
    msg.sender = self.currentUID;
    msg.receiver = self.groupID;
    msg.uuid = [[NSUUID UUID] UUIDString];
    msg.content = content;
    msg.timestamp = (int)time(NULL);
    msg.isOutgoing = YES;
    [msg generateRaw];
    return msg;
}

@end
