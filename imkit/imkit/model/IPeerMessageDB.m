//
//  IPeerMessageDB.m
//  gobelieve
//
//  Created by houxh on 2017/11/12.
//

#import "IPeerMessageDB.h"
#import "PeerMessageDB.h"

#define PAGE_COUNT 10

@implementation IPeerMessageDB

-(id)init {
    self = [super init];
    if (self) {
        self.attachments = [NSMutableDictionary dictionary];
    }
    return self;
}


- (NSArray*)loadConversationData {
    
    NSMutableArray *messages = [NSMutableArray array];
    
    NSMutableSet *uuidSet = [NSMutableSet set];
    int count = 0;
    int pageSize;
    id<IMessageIterator> iterator;

    iterator = [[PeerMessageDB instance] newMessageIterator: self.peerUID];
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
    return nil;
}


- (NSArray*)loadEarlierData:(int)messageID {
    NSMutableArray *messages = [NSMutableArray array];
    
    id<IMessageIterator> iterator =  [[PeerMessageDB instance] newMessageIterator:self.peerUID last:messageID];
    
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
    return nil;
}


-(void)saveMessageAttachment:(IMessage*)msg address:(NSString*)address {
    //以附件的形式存储，以免第二次查询
#ifdef SQL_ENGINE_DB
    [[PeerMessageDB instance] updateMessageContent:msg.msgLocalID content:msg.rawContent];
#else
    MessageAttachmentContent *att = [[MessageAttachmentContent alloc] initWithAttachment:msg.msgLocalID address:address];
    IMessage *attachment = [[IMessage alloc] init];
    attachment.sender = msg.sender;
    attachment.receiver = msg.receiver;
    attachment.rawContent = att.raw;
    [self saveMessage:attachment];
#endif
}

-(BOOL)saveMessage:(IMessage*)msg {
    return [[PeerMessageDB instance] insertMessage:msg uid:self.peerUID];
}

-(BOOL)removeMessage:(IMessage*)msg {
    return [[PeerMessageDB instance] removeMessage:msg.msgLocalID uid:self.peerUID];
    
}
-(BOOL)markMessageFailure:(IMessage*)msg {
    int64_t cid = 0;
    if (msg.sender == self.currentUID) {
        cid = msg.receiver;
    } else {
        cid = msg.sender;
    }
    return [[PeerMessageDB instance] markMessageFailure:msg.msgLocalID uid:cid];
}

-(BOOL)markMesageListened:(IMessage*)msg {
    return [[PeerMessageDB instance] markMesageListened:msg.msgLocalID uid:self.peerUID];
}

-(BOOL)eraseMessageFailure:(IMessage*)msg {
    return [[PeerMessageDB instance] eraseMessageFailure:msg.msgLocalID uid:self.peerUID];
}

-(IMessage*)newMessage {
    IMessage *msg = [[IMessage alloc] init];
    return msg;
}
-(IMessage*)newOutMessage {
    IMessage *msg = [[IMessage alloc] init];
    msg.sender = self.currentUID;
    msg.receiver = self.peerUID;
    return msg;
}
@end
