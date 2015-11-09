/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "MessageListViewController.h"
#import "MessageViewController.h"
#import "PeerMessageDB.h"
#import "GroupMessageDB.h"
#import "IMessage.h"
#import "PeerMessageViewController.h"
#import "GroupMessageViewController.h"
#import "Constants.h"

#import "MessageConversationCell.h"
#import <imsdk/IMService.h>

#if 0
#import "pinyin.h"
#import "MessageGroupConversationCell.h"
#import "NewGroupViewController.h"
#import "UserDB.h"
#import "UIImageView+WebCache.h"
#import "UserPresent.h"
#import "JSBadgeView.h"

#import "APIRequest.h"
#import "LevelDB.h"
#import "GroupDB.h"
#endif


#define kConversationCellHeight         60

@interface MessageListViewController()<UITableViewDelegate, UITableViewDataSource,
    TCPConnectionObserver, PeerMessageObserver, GroupMessageObserver>
@property (strong , nonatomic) NSMutableArray *conversations;
@property (strong , nonatomic) UITableView *tableview;
@end

@implementation MessageListViewController

-(id)init {
    self = [super init];
    if (self) {
        self.conversations = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect rect = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    self.tableview = [[UITableView alloc]initWithFrame:rect style:UITableViewStylePlain];
  	self.tableview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.tableview.delegate = self;
	self.tableview.dataSource = self;
	self.tableview.scrollEnabled = YES;
	self.tableview.showsVerticalScrollIndicator = NO;
	self.tableview.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableview.backgroundColor = RGBACOLOR(235, 235, 237, 1);
    self.tableview.separatorColor = RGBCOLOR(208, 208, 208);
	[self.view addSubview:self.tableview];
    
    [[IMService instance] addPeerMessageObserver:self];
    [[IMService instance] addGroupMessageObserver:self];
    [[IMService instance] addConnectionObserver:self];

    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(newGroupMessage:) name:LATEST_GROUP_MESSAGE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(newMessage:) name:LATEST_PEER_MESSAGE object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(clearSinglePeerNewState:) name:CLEAR_PEER_NEW_MESSAGE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(clearSingleGroupNewState:) name:CLEAR_GROUP_NEW_MESSAGE object:nil];

    id<ConversationIterator> iterator =  [[PeerMessageDB instance] newConversationIterator];
    
    Conversation * conversation = [iterator next];
    while (conversation) {
        conversation.name = [self getUserName:conversation.cid];
        conversation.avatarURL = @"";
        [self.conversations addObject:conversation];
        conversation = [iterator next];
    }
    
    iterator = [[GroupMessageDB instance] newConversationIterator];
    conversation = [iterator next];
    while (conversation) {
        conversation.name = [self getGroupName:conversation.cid];;
        conversation.avatarURL = @"";
        if (conversation.message.content.type == MESSAGE_GROUP_NOTIFICATION) {
            [self updateNotificationDesc:conversation.message];
        }
        [self.conversations addObject:conversation];
        conversation = [iterator next];
    }
 
    self.title = @"对话";
    if ([[IMService instance] connectState] == STATE_CONNECTING) {
        self.navigationItem.title = @"连接中...";
    }
}

- (void)updateNotificationDesc:(IMessage*)message {
    if (message.content.type == MESSAGE_GROUP_NOTIFICATION) {
        GroupNotification *notification = message.content.notification;
        int type = notification.type;
        if (type == NOTIFICATION_GROUP_CREATED) {
            if (self.currentUID == notification.master) {
                NSString *desc = [NSString stringWithFormat:@"您创建了\"%@\"群组", notification.groupName];
                message.content.notificationDesc = desc;
            } else {
                NSString *desc = [NSString stringWithFormat:@"您加入了\"%@\"群组", notification.groupName];
                message.content.notificationDesc = desc;
            }
        } else if (type == NOTIFICATION_GROUP_DISBANDED) {
            message.content.notificationDesc = @"群组已解散";
        } else if (type == NOTIFICATION_GROUP_MEMBER_ADDED) {
            NSString *name = [self getUserName:notification.member];
            NSString *desc = [NSString stringWithFormat:@"%@加入群", name];
            message.content.notificationDesc = desc;
        } else if (type == NOTIFICATION_GROUP_MEMBER_LEAVED) {
            NSString *name = [self getUserName:notification.member];
            NSString *desc = [NSString stringWithFormat:@"%@离开群", name];
            message.content.notificationDesc = desc;
        }
    }
}

- (NSString*)getUserName:(int64_t)uid {
    return [NSString stringWithFormat:@"user:%lld", uid];
}

- (NSString*)getGroupName:(int64_t)groupID {
    return [NSString stringWithFormat:@"group:%lld", groupID];;
}

+ (NSString *)getConversationTimeString:(NSDate *)date{
    NSMutableString *outStr;
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [gregorian components:NSUIntegerMax fromDate:date];
    NSDateComponents *todayComponents = [gregorian components:NSIntegerMax fromDate:[NSDate date]];
    
    if (components.year == todayComponents.year &&
        components.day == todayComponents.day &&
        components.month == todayComponents.month) {
        NSString *format = @"HH:mm";
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
        [formatter setDateFormat:format];
        [formatter setTimeZone:[NSTimeZone systemTimeZone]];
        
        NSString *timeStr = [formatter stringFromDate:date];
        
        if (components.hour > 11) {
            outStr = [NSMutableString stringWithFormat:@"%@ %@",@"下午",timeStr];
        } else {
            outStr = [NSMutableString stringWithFormat:@"%@ %@",@"上午",timeStr];
        }
        return outStr;
    } else {
        NSString *format = @"MM-dd HH:mm";
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
        [formatter setDateFormat:format];
        [formatter setTimeZone:[NSTimeZone systemTimeZone]];
        
        return [formatter stringFromDate:date];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.conversations count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kConversationCellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MessageConversationCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MessageConversationCell"];
    
    if (cell == nil) {
        cell = [[[NSBundle mainBundle]loadNibNamed:@"MessageConversationCell" owner:self options:nil] lastObject];
    }
    Conversation * conv = nil;
    conv = (Conversation*)[self.conversations objectAtIndex:(indexPath.row)];

    if(conv.type == CONVERSATION_PEER){
        [cell.headView sd_setImageWithURL: [NSURL URLWithString:conv.avatarURL] placeholderImage:[UIImage imageNamed:@"PersonalChat"]];
    }else if (conv.type == CONVERSATION_GROUP){
        [cell.headView sd_setImageWithURL:[NSURL URLWithString:conv.avatarURL] placeholderImage:[UIImage imageNamed:@"GroupChat"]];
    }
    if (conv.message.content.type == MESSAGE_IMAGE) {
        cell.messageContent.text = @"一张图片";
    }else if(conv.message.content.type == MESSAGE_TEXT){
       cell.messageContent.text = conv.message.content.text;
    }else if(conv.message.content.type == MESSAGE_LOCATION){
        cell.messageContent.text = @"一个地理位置";
    }else if (conv.message.content.type == MESSAGE_AUDIO){
       cell.messageContent.text = @"一个音频";
    } else if (conv.message.content.type == MESSAGE_GROUP_NOTIFICATION) {
        cell.messageContent.text = conv.message.content.notificationDesc;
    }
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970: conv.message.timestamp];
    NSString *str = [[self class] getConversationTimeString:date ];
    cell.timelabel.text = str;
    cell.namelabel.text = conv.name;
   
    if (conv.newMsgCount > 0) {
        [cell showNewMessage:conv.newMsgCount];
    }
    
    return cell;
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView == self.tableview) {
        return YES;
    }
    return NO;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //add code here for when you hit delete
        Conversation *con = [self.conversations objectAtIndex:indexPath.row];
        if (con.type == CONVERSATION_PEER) {
            [[PeerMessageDB instance] clearConversation:con.cid];
        } else {
            [[GroupMessageDB instance] clearConversation:con.cid];
        }
        [self.conversations removeObject:con];
        
        /*IOS8中删除最后一个cell的时，报一个错误
         [RemindersCell _setDeleteAnimationInProgress:]: message sent to deallocated instance
         在重新刷新tableView的时候延迟一下*/
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.tableview reloadData];
        });
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    Conversation *con = [self.conversations objectAtIndex:indexPath.row];
    if (con.type == CONVERSATION_PEER) {
        PeerMessageViewController* msgController = [[PeerMessageViewController alloc] init];
        msgController.peerUID = con.cid;
        msgController.peerName = con.name;
        msgController.currentUID = self.currentUID;
        msgController.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:msgController animated:YES];
    } else {
        GroupMessageViewController* msgController = [[GroupMessageViewController alloc] init];
        msgController.isShowUserName = YES;

        msgController.getUserName = ^ NSString*(int64_t uid) {
            return [NSString stringWithFormat:@"%lld", uid];
        };
        
        msgController.groupID = con.cid;
        msgController.groupName = con.name;
        msgController.currentUID = self.currentUID;
        msgController.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:msgController animated:YES];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


- (void)newGroupMessage:(NSNotification*)notification {
    IMessage *m = notification.object;
    NSLog(@"new message:%lld, %lld", m.sender, m.receiver);
    [self onNewGroupMessage:m cid:m.receiver];
}

- (void)newMessage:(NSNotification*) notification {
    IMessage *m = notification.object;
    NSLog(@"new message:%lld, %lld", m.sender, m.receiver);
    [self onNewMessage:m cid:m.receiver];
}

- (void)clearSinglePeerNewState:(NSNotification*) notification {
    int64_t usrid = [(NSNumber*)notification.object longLongValue];
    for (int index = 0 ; index < [self.conversations count] ; index++) {
        Conversation *conv = [self.conversations objectAtIndex:index];
        if (conv.type == CONVERSATION_PEER && conv.cid == usrid) {
            if (conv.newMsgCount > 0) {
                conv.newMsgCount = 0;
                NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:0];
                MessageConversationCell *cell = (MessageConversationCell*)[self.tableview cellForRowAtIndexPath:path];
                [cell clearNewMessage];
                [self resetConversationsViewControllerNewState];
            }
        }
    }
}

- (void)clearSingleGroupNewState:(NSNotification*) notification{
    int64_t groupID = [(NSNumber*)notification.object longLongValue];
    for (int index = 0 ; index < [self.conversations count] ; index++) {
        Conversation *conv = [self.conversations objectAtIndex:index];
        if (conv.type == CONVERSATION_GROUP && conv.cid == groupID) {
            if (conv.newMsgCount > 0) {
                conv.newMsgCount = 0;
                 NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:0];
                 MessageConversationCell *cell = (MessageConversationCell*)[self.tableview cellForRowAtIndexPath:path];
                [cell clearNewMessage];
                [self resetConversationsViewControllerNewState];
            }
        }
    }
}

-(void)onNewGroupMessage:(IMessage*)msg cid:(int64_t)cid{
    int index = -1;
    for (int i = 0; i < [self.conversations count]; i++) {
        Conversation *con = [self.conversations objectAtIndex:i];
        if (con.type == CONVERSATION_GROUP && con.cid == cid) {
            con.message = msg;
            index = i;
            break;
        }
    }
    
    if (index != -1) {
        Conversation *con = [self.conversations objectAtIndex:index];
        con.message = msg;
        if (self.currentUID != msg.sender) {
            con.newMsgCount += 1;
            [self setNewOnTabBar];
        }
        NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:0];
        [self.tableview reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationNone];
    } else {
        Conversation *con = [[Conversation alloc] init];
        con.message = msg;
        
        if (self.currentUID != msg.sender) {
            con.newMsgCount += 1;
            [self setNewOnTabBar];
        }
        
        con.type = CONVERSATION_GROUP;
        con.cid = cid;
        con.name = [self getGroupName:cid];
        con.avatarURL = @"";
        [self.conversations insertObject:con atIndex:0];
        NSIndexPath *path = [NSIndexPath indexPathForRow:0 inSection:0];
        NSArray *array = [NSArray arrayWithObject:path];
        [self.tableview insertRowsAtIndexPaths:array withRowAnimation:UITableViewRowAnimationMiddle];
    }
}


-(void)onNewMessage:(IMessage*)msg cid:(int64_t)cid{
    int index = -1;
    for (int i = 0; i < [self.conversations count]; i++) {
        Conversation *con = [self.conversations objectAtIndex:i];
        if (con.type == CONVERSATION_PEER && con.cid == cid) {
            con.message = msg;
            index = i;
            break;
        }
    }
    
    if (index != -1) {
        Conversation *con = [self.conversations objectAtIndex:index];
        con.message = msg;
        if (self.currentUID == msg.receiver) {
            con.newMsgCount += 1;
            [self setNewOnTabBar];
        }
        NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:0];
        [self.tableview reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationNone];
    } else {
        Conversation *con = [[Conversation alloc] init];
        con.message = msg;
       
        if (self.currentUID == msg.receiver) {
            con.newMsgCount += 1;
            [self setNewOnTabBar];
        }
        
        con.type = CONVERSATION_PEER;
        con.cid = cid;
        con.name = [self getUserName:cid];
        con.avatarURL = @"";
        
        [self.conversations insertObject:con atIndex:0];
        NSIndexPath *path = [NSIndexPath indexPathForRow:0 inSection:0];
        NSArray *array = [NSArray arrayWithObject:path];
        [self.tableview insertRowsAtIndexPaths:array withRowAnimation:UITableViewRowAnimationMiddle];
    }
}

-(void)onPeerMessage:(IMMessage*)im {
    IMessage *m = [[IMessage alloc] init];
    m.sender = im.sender;
    m.receiver = im.receiver;
    m.msgLocalID = im.msgLocalID;
    MessageContent *content = [[MessageContent alloc] init];
    content.raw = im.content;
    m.content = content;
    m.timestamp = (int)time(NULL);
    
    MessageContent *c = m.content;
    if (c.type == MESSAGE_TEXT) {
        NSLog(@"message:%@", c.text);
    }
    [self onNewMessage:m cid:m.sender];
}

-(void)onGroupMessage:(IMMessage *)im {
    IMessage *m = [[IMessage alloc] init];
    m.sender = im.sender;
    m.receiver = im.receiver;
    m.msgLocalID = im.msgLocalID;
    MessageContent *content = [[MessageContent alloc] init];
    content.raw = im.content;
    m.content = content;
    m.timestamp = (int)time(NULL);
    
    MessageContent *c = m.content;
    if (c.type == MESSAGE_TEXT) {
        NSLog(@"message:%@", c.text);
    }
    [self onNewGroupMessage:m cid:m.receiver];
}

-(void)onGroupNotification:(NSString*)text {
    GroupNotification *notification = [[GroupNotification alloc] initWithRaw:text];
    if (notification.type == NOTIFICATION_GROUP_CREATED) {
        [self onGroupCreated:notification];
    } else if (notification.type == NOTIFICATION_GROUP_DISBANDED) {
        [self onGroupDisband:notification];
    } else if (notification.type == NOTIFICATION_GROUP_MEMBER_ADDED) {
        [self onGroupMemberAdd:notification];
    } else if (notification.type == NOTIFICATION_GROUP_MEMBER_LEAVED) {
        [self onGroupMemberLeave:notification];
    }
}
-(void)onGroupCreated:(GroupNotification*)notification {
    int64_t groupID = notification.groupID;

    IMessage *msg = [[IMessage alloc] init];
    msg.sender = 0;
    msg.receiver = groupID;
    msg.timestamp = (int)time(NULL);
    MessageContent *content = [[MessageContent alloc] initWithNotification:notification];
    msg.content = content;
    
    [self updateNotificationDesc:msg];
    [self onNewGroupMessage:msg cid:msg.receiver];
}

-(void)onGroupDisband:(GroupNotification*)notification {
    int64_t groupID = notification.groupID;
    
    IMessage *msg = [[IMessage alloc] init];
    msg.sender = 0;
    msg.receiver = groupID;
    msg.timestamp = (int)time(NULL);
    MessageContent *content = [[MessageContent alloc] initWithNotification:notification];
    msg.content = content;
    
    [self updateNotificationDesc:msg];
    
    [self onNewGroupMessage:msg cid:msg.receiver];
}

-(void)onGroupMemberAdd:(GroupNotification*)notification {
    int64_t groupID = notification.groupID;
    
    IMessage *msg = [[IMessage alloc] init];
    msg.sender = 0;
    msg.receiver = groupID;
    msg.timestamp = (int)time(NULL);
    MessageContent *content = [[MessageContent alloc] initWithNotification:notification];
    msg.content = content;
    
    [self updateNotificationDesc:msg];
    
    [self onNewGroupMessage:msg cid:msg.receiver];
}

-(void)onGroupMemberLeave:(GroupNotification*)notification {
    int64_t groupID = notification.groupID;
    
    IMessage *msg = [[IMessage alloc] init];
    msg.sender = 0;
    msg.receiver = groupID;
    msg.timestamp = (int)time(NULL);
    MessageContent *content = [[MessageContent alloc] initWithNotification:notification];
    msg.content = content;
    
    [self updateNotificationDesc:msg];
    
    [self onNewGroupMessage:msg cid:msg.receiver];
}


//同IM服务器连接的状态变更通知
-(void)onConnectState:(int)state {
    if (state == STATE_CONNECTING) {
        self.navigationItem.title = @"连接中...";
    } else if (state == STATE_CONNECTED) {
        self.navigationItem.title = @"对话";
    } else if (state == STATE_CONNECTFAIL) {
        
    } else if (state == STATE_UNCONNECTED) {
        
    }
}

#pragma mark - function
-(void) resetConversationsViewControllerNewState{
    BOOL shouldClearNewCount = YES;
    for (Conversation *conv in self.conversations) {
        if (conv.newMsgCount > 0) {
            shouldClearNewCount = NO;
            break;
        }
    }
    
    if (shouldClearNewCount) {
        [self clearNewOnTarBar];
    }
}

- (void)setNewOnTabBar {

}

- (void)clearNewOnTarBar {

}

@end
