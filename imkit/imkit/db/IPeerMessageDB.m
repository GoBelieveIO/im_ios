//
//  IPeerMessageDB.m
//  gobelieve
//
//  Created by houxh on 2017/11/12.
//

#import "IPeerMessageDB.h"
#import "PeerMessageDB.h"
#import "EPeerMessageDB.h"

#define PAGE_COUNT 10

@interface IPeerMessageDB()
@property(nonatomic, weak) SQLPeerMessageDB *db;
@end
@implementation IPeerMessageDB

-(id)initWithSecret:(BOOL)secret {
    self = [super init];
    if (self) {
        self.attachments = [NSMutableDictionary dictionary];
        self.secret = secret;
        if (self.secret) {
            self.db = [EPeerMessageDB instance];
        } else {
            self.db = [PeerMessageDB instance];
        }
    }
    return self;
}

- (NSArray*)loadConversationData {
    
    NSMutableArray *messages = [NSMutableArray array];
    
    NSMutableSet *uuidSet = [NSMutableSet set];
    int count = 0;
    int pageSize;
    id<IMessageIterator> iterator;

    iterator = [self.db newMessageIterator: self.peerUID];
    pageSize = PAGE_COUNT;
    
    
    IMessage *msg = [iterator next];
    while (msg) {
        //重复的消息
        if (msg.uuid.length > 0 && [uuidSet containsObject:msg.uuid]) {
            msg = [iterator next];
            continue;
        }
        
        if (msg.uuid.length > 0){
            [uuidSet addObject:msg.uuid];
        }
        
        if (msg.type == MESSAGE_ATTACHMENT) {
            MessageAttachmentContent *att = msg.attachmentContent;
            [self.attachments setObject:att
                                 forKey:[NSNumber numberWithInt:att.msgLocalID]];
        } else {
            msg.isOutgoing = (msg.sender == self.currentUID);
            [messages insertObject:msg atIndex:0];
            if (++count >= pageSize) {
                break;
            }
        }
        
        msg = [iterator next];
    }
    
    
    return messages;
}

//navigator from search
- (NSArray*)loadConversationData:(int)messageID {
    NSMutableArray *messages = [NSMutableArray array];
    int count = 0;
    id<IMessageIterator> iterator;
    
    IMessage *msg = [self.db getMessage:messageID];
    if (!msg) {
        return nil;
    }
    [messages addObject:msg];
    
    iterator = [self.db newBackwardMessageIterator:self.peerUID messageID:messageID];
    msg = [iterator next];
    while (msg) {
        if (msg.type == MESSAGE_ATTACHMENT) {
            MessageAttachmentContent *att = msg.attachmentContent;
            [self.attachments setObject:att
                                 forKey:[NSNumber numberWithInt:att.msgLocalID]];
        } else {
            msg.isOutgoing = (msg.sender == self.currentUID);
            [messages addObject:msg];
            if (++count >= PAGE_COUNT) {
                break;
            }
        }
        
        msg = [iterator next];
    }

    count = 0;
    iterator = [self.db newMessageIterator:self.peerUID last:messageID];
    msg = [iterator next];
    while (msg) {
        if (msg.type == MESSAGE_ATTACHMENT) {
            MessageAttachmentContent *att = msg.attachmentContent;
            [self.attachments setObject:att
                                 forKey:[NSNumber numberWithInt:att.msgLocalID]];
        } else {
            msg.isOutgoing = (msg.sender == self.currentUID);
            [messages insertObject:msg atIndex:0];
            if (++count >= PAGE_COUNT) {
                break;
            }
        }
        msg = [iterator next];
    }
    return messages;
}


- (NSArray*)loadEarlierData:(int)messageID {
    NSMutableArray *messages = [NSMutableArray array];
    
    id<IMessageIterator> iterator =  [self.db newMessageIterator:self.peerUID last:messageID];
    
    int count = 0;
    IMessage *msg = [iterator next];
    while (msg) {
        if (msg.type == MESSAGE_ATTACHMENT) {
            MessageAttachmentContent *att = msg.attachmentContent;
            [self.attachments setObject:att
                                 forKey:[NSNumber numberWithInt:att.msgLocalID]];
            
        } else {
            msg.isOutgoing = (msg.sender == self.currentUID);
            [messages insertObject:msg atIndex:0];
            if (++count >= PAGE_COUNT) {
                break;
            }
        }
        msg = [iterator next];
    }
    NSLog(@"load earlier messages:%d", count);
    return messages;
}

//加载后面的聊天记录
-(NSArray*)loadLateData:(int)messageID {
    id<IMessageIterator> iterator = [self.db newBackwardMessageIterator:self.peerUID messageID:messageID];
    NSMutableArray *newMessages = [NSMutableArray array];
    int count = 0;
    IMessage *msg = [iterator next];
    while (msg) {
        if (msg.type == MESSAGE_ATTACHMENT) {
            MessageAttachmentContent *att = msg.attachmentContent;
            [self.attachments setObject:att
                                 forKey:[NSNumber numberWithInt:att.msgLocalID]];
            
        } else {
            msg.isOutgoing = (msg.sender == self.currentUID);
            [newMessages addObject:msg];
            if (++count >= PAGE_COUNT) {
                break;
            }
        }
        msg = [iterator next];
    }
    
    NSLog(@"load late messages:%d", count);
    return newMessages;
}


-(void)saveMessageAttachment:(IMessage*)msg address:(NSString*)address {
    //以附件的形式存储，以免第二次查询
    [self.db updateMessageContent:msg.msgLocalID content:msg.rawContent];
}

-(BOOL)saveMessage:(IMessage*)msg {
    return [self.db insertMessage:msg uid:self.peerUID];
}

-(BOOL)removeMessage:(IMessage*)msg {
    return [self.db removeMessage:msg.msgLocalID uid:self.peerUID];
    
}
-(BOOL)markMessageFailure:(IMessage*)msg {
    int64_t cid = 0;
    if (msg.sender == self.currentUID) {
        cid = msg.receiver;
    } else {
        cid = msg.sender;
    }
    return [self.db markMessageFailure:msg.msgLocalID uid:cid];
}

-(BOOL)markMesageListened:(IMessage*)msg {
    return [self.db markMesageListened:msg.msgLocalID uid:self.peerUID];
}

-(BOOL)eraseMessageFailure:(IMessage*)msg {
    return [self.db eraseMessageFailure:msg.msgLocalID uid:self.peerUID];
}

-(IMessage*)newMessage {
    IMessage *msg = [[IMessage alloc] init];
    return msg;
}
-(IMessage*)newOutMessage {
    IMessage *msg = [[IMessage alloc] init];
    msg.sender = self.currentUID;
    msg.receiver = self.peerUID;
    msg.secret = self.secret;
    return msg;
}
@end
