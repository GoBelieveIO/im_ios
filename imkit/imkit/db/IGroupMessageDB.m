//
//  IGroupMessageDB.m
//  gobelieve
//
//  Created by houxh on 2017/11/12.
//

#import "IGroupMessageDB.h"
#import "GroupMessageDB.h"

@implementation IGroupMessageDB

- (NSArray*)loadConversationData {
    
    NSMutableArray *messages = [NSMutableArray array];
    NSMutableSet *uuidSet = [NSMutableSet set];
    int count = 0;
    int pageSize;
    id<IMessageIterator> iterator;
 
    iterator =  [[GroupMessageDB instance] newMessageIterator: self.groupID];
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

- (NSArray*)loadConversationData:(int)messageID {
    NSMutableArray *messages = [NSMutableArray array];
    int count = 0;
    id<IMessageIterator> iterator;
    
    IMessage *msg = [[GroupMessageDB instance] getMessage:messageID];
    if (!msg) {
        return nil;
    }
    
    [messages addObject:msg];
    iterator =  [[GroupMessageDB instance] newBackwardMessageIterator:self.groupID messageID:messageID];
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
    
    iterator =  [[GroupMessageDB instance] newMessageIterator:self.groupID last:messageID];
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
    id<IMessageIterator> iterator =  [[GroupMessageDB instance] newMessageIterator:self.groupID last:messageID];
    
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
    return messages;
}

- (NSArray*)loadLateData:(int)messageID {
    id<IMessageIterator> iterator = [[GroupMessageDB instance] newBackwardMessageIterator:self.groupID messageID:messageID];
    
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
    return newMessages;
}

-(void)saveMessageAttachment:(IMessage*)msg address:(NSString*)address {
    //以附件的形式存储，以免第二次查询
    MessageAttachmentContent *att = [[MessageAttachmentContent alloc] initWithAttachment:msg.msgLocalID address:address];
    IMessage *attachment = [[IMessage alloc] init];
    attachment.sender = msg.sender;
    attachment.receiver = msg.receiver;
    attachment.rawContent = att.raw;
    [self saveMessage:attachment];
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

-(IMessage*)newMessage {
    IMessage *msg = [[IMessage alloc] init];
    return msg;
}

-(IMessage*)newOutMessage {
    IMessage *msg = [[IMessage alloc] init];
    msg.sender = self.currentUID;
    msg.receiver = self.groupID;
    return msg;
}
@end
