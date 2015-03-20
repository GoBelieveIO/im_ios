//
//  GroupMessageViewController.m
//  imkit
//
//  Created by houxh on 15/3/19.
//  Copyright (c) 2015年 beetle. All rights reserved.
//

#import "GroupMessageViewController.h"

#import "FileCache.h"
#import "Outbox.h"
#import "AudioDownloader.h"
#import "DraftDB.h"
#import "IMessage.h"
#import "GroupMessageDB.h"
#import "DraftDB.h"
#import "Constants.h"

#define PAGE_COUNT 10

@interface GroupMessageViewController ()

@end

@implementation GroupMessageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setNormalNavigationButtons];
    self.navigationItem.title = self.groupName;
    
    DraftDB *db = [DraftDB instance];
    NSString *draft = [db getGroupDraft:self.groupID];
    [self setDraft:draft];
    
    [self addObserver];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (int64_t)sender {
    return self.currentUID;
}

- (int64_t)receiver {
    return self.groupID;
}

- (BOOL)isInConversation:(IMessage*)msg {
    BOOL r = (msg.receiver == self.groupID);
    return r;
}

-(BOOL)saveMessage:(IMessage*)msg {
    return [[GroupMessageDB instance] insertMessage:msg];
}

-(BOOL)removeMessage:(IMessage*)msg {
    int64_t cid = msg.receiver;
    return [[GroupMessageDB instance] removeMessage:msg.msgLocalID gid:cid];
    
}
-(BOOL)markMessageFailure:(IMessage*)msg {
    int64_t cid = msg.receiver;
    return [[GroupMessageDB instance] markMessageFailure:msg.msgLocalID gid:cid];
}

-(BOOL)markMesageListened:(IMessage*)msg {
    int64_t cid = msg.receiver;
    return [[GroupMessageDB instance] markMesageListened:msg.msgLocalID gid:cid];
}

-(BOOL)eraseMessageFailure:(IMessage*)msg {
    int64_t cid = msg.receiver;
    return [[GroupMessageDB instance] markMessageFailure:msg.msgLocalID gid:cid];
}

-(void) setNormalNavigationButtons{
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"对话"
                                                             style:UIBarButtonItemStyleDone
                                                            target:self
                                                            action:@selector(returnMainTableViewController)];
    
    self.navigationItem.leftBarButtonItem = item;
}

- (void)returnMainTableViewController {
    DraftDB *db = [DraftDB instance];
    [db setGroupDraft:self.groupID draft:[self getDraft]];
    
    [self removeObserver];
    
    if (self.messages.count > 0) {
        IMessage *msg = [self.messages lastObject];
        if (msg.sender == self.currentUID || msg.content.type == MESSAGE_GROUP_NOTIFICATION) {
            NSNotification* notification = [[NSNotification alloc] initWithName:LATEST_GROUP_MESSAGE object: msg userInfo:nil];
            
            [[NSNotificationCenter defaultCenter] postNotification:notification];
        }
    }
    
    NSNotification* notification = [[NSNotification alloc] initWithName:CLEAR_GROUP_NEW_MESSAGE
                                                                 object:[NSNumber numberWithLongLong:self.groupID]
                                                               userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];

    
    [self.navigationController popToRootViewControllerAnimated:YES];
}


#pragma mark - MessageObserver
-(void)onGroupMessage:(IMMessage*)im {
    if (im.receiver != self.groupID) {
        return;
    }
    [[self class] playMessageReceivedSound];
    
    NSLog(@"receive msg:%@",im);
    //加载第三方应用的用户名到缓存中
    [self getUserName:im.sender];
    
    IMessage *m = [[IMessage alloc] init];
    m.sender = im.sender;
    m.receiver = im.receiver;
    m.msgLocalID = im.msgLocalID;
    MessageContent *content = [[MessageContent alloc] initWithRaw:im.content];
    m.content = content;
    m.timestamp = (int)time(NULL);
    
    if (self.textMode && m.content.type != MESSAGE_TEXT && m.content.type != MESSAGE_GROUP_NOTIFICATION) {
        return;
    }
    
    if (m.content.type == MESSAGE_AUDIO) {
        AudioDownloader *downloader = [AudioDownloader instance];
        [downloader downloadAudio:m];
    }
    
    [self insertMessage:m];
}

-(void)onGroupMessageACK:(int)msgLocalID gid:(int64_t)gid {
    if (gid != self.groupID) {
        return;
    }
    IMessage *msg = [self getMessageWithID:msgLocalID];
    msg.flags = msg.flags|MESSAGE_FLAG_ACK;
    [self reloadMessage:msgLocalID];
}

-(void)onGroupMessageFailure:(int)msgLocalID gid:(int64_t)gid {
    if (gid != self.groupID) {
        return;
    }
    IMessage *msg = [self getMessageWithID:msgLocalID];
    msg.flags = msg.flags|MESSAGE_FLAG_FAILURE;
    [self reloadMessage:msgLocalID];
}


-(void)onGroupNotification:(NSString *)text {
    GroupNotification *notification = [[GroupNotification alloc] initWithRaw:text];
    
    if (notification.type == NOTIFICATION_GROUP_CREATED) {

    } else if (notification.type == NOTIFICATION_GROUP_DISBANDED) {
        [self onGroupDisband:notification];
    } else if (notification.type == NOTIFICATION_GROUP_MEMBER_ADDED) {
        [self onGroupMemberAdd:notification];
    } else if (notification.type == NOTIFICATION_GROUP_MEMBER_LEAVED) {
        [self onGroupMemberLeave:notification];
    }
}

-(void)onGroupDisband:(GroupNotification*)notification {
    int64_t groupID = notification.groupID;
    if (groupID != self.groupID) {
        return;
    }
    
    IMessage *msg = [[IMessage alloc] init];
    msg.sender = 0;
    msg.receiver = groupID;
    msg.timestamp = (int)time(NULL);
    MessageContent *content = [[MessageContent alloc] initWithNotification:notification];
    msg.content = content;
    [self updateNotificationDesc:msg];
    [self insertMessage:msg];
}

-(void)onGroupMemberAdd:(GroupNotification*)notification {
    int64_t groupID = notification.groupID;
    if (groupID != self.groupID) {
        return;
    }
    IMessage *msg = [[IMessage alloc] init];
    
    msg.sender = 0;
    msg.receiver = groupID;
    msg.timestamp = (int)time(NULL);
    MessageContent *content = [[MessageContent alloc] initWithNotification:notification];
    msg.content = content;
    [self updateNotificationDesc:msg];

    [self insertMessage:msg];
}

-(void)onGroupMemberLeave:(GroupNotification*)notification {
    int64_t groupID = notification.groupID;
    if (groupID != self.groupID) {
        return;
    }
    
    IMessage *msg = [[IMessage alloc] init];
    msg.sender = 0;
    msg.receiver = groupID;
    msg.timestamp = (int)time(NULL);
    MessageContent *content = [[MessageContent alloc] initWithNotification:notification];
    msg.content = content;
    
    [self updateNotificationDesc:msg];
    [self insertMessage:msg];
}

-(NSString*)getUserName:(int64_t)uid {
    NSNumber *key = [NSNumber numberWithLongLong:uid];
    
    if ([self.names objectForKey:key]) {
        return [self.names objectForKey:key];
    }

    NSString *name = self.getUserName(uid);
    if (name.length > 0) {
        [self.names setObject:name forKey:key];
    }
    return name;
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


- (void)loadConversationData {
    int count = 0;
    id<IMessageIterator> iterator =  [[GroupMessageDB instance] newMessageIterator: self.groupID];
    IMessage *msg = [iterator next];
    while (msg) {
        if (self.textMode) {
            if (msg.content.type == MESSAGE_TEXT || msg.content.type == MESSAGE_GROUP_NOTIFICATION) {
                [self getUserName:msg.sender];
                [self updateNotificationDesc:msg];
                [self.messages insertObject:msg atIndex:0];
                if (++count >= PAGE_COUNT) {
                    break;
                }
            }
        } else {
            [self getUserName:msg.sender];
            [self updateNotificationDesc:msg];
            [self.messages insertObject:msg atIndex:0];
            if (++count >= PAGE_COUNT) {
                break;
            }
        }
        msg = [iterator next];
    }
    
    [self initTableViewData];
}


- (void)loadEarlierData {
    
    IMessage *last = [self.messages firstObject];
    if (last == nil) {
        return;
    }
    id<IMessageIterator> iterator =  [[GroupMessageDB instance] newMessageIterator:self.groupID last:last.msgLocalID];
    
    int count = 0;
    IMessage *msg = [iterator next];
    while (msg) {
        if (self.textMode) {
            if (msg.content.type == MESSAGE_TEXT || msg.content.type == MESSAGE_GROUP_NOTIFICATION) {
                [self getUserName:msg.sender];
                [self.messages insertObject:msg atIndex:0];
                if (++count >= PAGE_COUNT) {
                    break;
                }
            }
        } else {
            [self getUserName:msg.sender];
            [self.messages insertObject:msg atIndex:0];
            if (++count >= PAGE_COUNT) {
                break;
            }
        }
        msg = [iterator next];
    }
    if (count == 0) {
        return;
    }
    
    [self initTableViewData];
    
    [self.tableView reloadData];
    
    int section = 0;
    int row = 0;
    for (NSArray *block in self.messageArray) {
        if (count < block.count) {
            row = count;
            break;
        }
        count -= [block count];
        section++;
    }
    NSLog(@"scroll to row:%d section:%d", row, section);
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
}


- (void)sendMessage:(IMessage*)message {
    if (message.content.type == MESSAGE_AUDIO) {
        [[Outbox instance] uploadGroupAudio:message];
    } else if (message.content.type == MESSAGE_IMAGE) {
        [[Outbox instance] uploadGroupImage:message];
    } else {
        IMMessage *im = [[IMMessage alloc] init];
        im.sender = message.sender;
        im.receiver = message.receiver;
        im.msgLocalID = message.msgLocalID;
        im.content = message.content.raw;
        [[IMService instance] sendGroupMessage:im];
    }
}



@end
