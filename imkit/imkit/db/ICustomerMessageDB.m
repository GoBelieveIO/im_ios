//
//  ICustomerMessageDB.m
//  gobelieve
//
//  Created by houxh on 2017/11/12.
//

#import "ICustomerMessageDB.h"
#import "CustomerMessageDB.h"

@implementation ICustomerMessageDB

- (NSArray*)loadConversationData {
    NSMutableArray *messages = [NSMutableArray array];
    NSMutableSet *uuidSet = [NSMutableSet set];
    int count = 0;
    id<IMessageIterator> iterator =  [[CustomerMessageDB instance] newMessageIterator:self.storeID];
    ICustomerMessage *msg = (ICustomerMessage*)[iterator next];
    while (msg) {
        //重复的消息
        if (msg.uuid.length > 0 && [uuidSet containsObject:msg.uuid]) {
            msg = (ICustomerMessage*)[iterator next];
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
            msg.isOutgoing = !msg.isSupport;
            [messages insertObject:msg atIndex:0];
            if (++count >= PAGE_COUNT) {
                break;
            }
        }
        
        msg = (ICustomerMessage*)[iterator next];
    }
    
    return messages;
}




- (NSArray*)loadConversationData:(int)messageID {
    return nil;
}

- (NSArray*)loadEarlierData:(int)messageID {
    NSMutableArray *messages = [NSMutableArray array];
    id<IMessageIterator> iterator =  [[CustomerMessageDB instance] newMessageIterator:self.storeID last:messageID];
    int count = 0;
    ICustomerMessage *msg = (ICustomerMessage*)[iterator next];
    while (msg) {
        if (msg.type == MESSAGE_ATTACHMENT) {
            MessageAttachmentContent *att = msg.attachmentContent;
            [self.attachments setObject:att
                                 forKey:[NSNumber numberWithInt:att.msgLocalID]];
            
        } else {
            msg.isOutgoing = !msg.isSupport;
            [messages insertObject:msg atIndex:0];
            if (++count >= PAGE_COUNT) {
                break;
            }
        }
        msg = (ICustomerMessage*)[iterator next];
    }
    return messages;
}


- (NSArray*)loadLateData:(int)messageID {
    return nil;
}


-(void)saveMessageAttachment:(IMessage*)msg address:(NSString*)address {
    //以附件的形式存储，以免第二次查询
    MessageAttachmentContent *att = [[MessageAttachmentContent alloc] initWithAttachment:msg.msgLocalID address:address];
    ICustomerMessage *attachment = [[ICustomerMessage alloc] init];
    attachment.rawContent = att.raw;
    [self saveMessage:attachment];
}


-(BOOL)saveMessage:(IMessage*)msg {
    return [[CustomerMessageDB instance] insertMessage:msg];
}

-(BOOL)removeMessage:(IMessage*)msg {
    return [[CustomerMessageDB instance] removeMessage:msg.msgLocalID];
    
}
-(BOOL)markMessageFailure:(IMessage*)msg {
    return [[CustomerMessageDB instance] markMessageFailure:msg.msgLocalID];
}

-(BOOL)markMesageListened:(IMessage*)msg {
    return [[CustomerMessageDB instance] markMesageListened:msg.msgLocalID];
}

-(BOOL)eraseMessageFailure:(IMessage*)msg {
    return [[CustomerMessageDB instance] eraseMessageFailure:msg.msgLocalID];
}

-(IMessage*)newMessage {
    ICustomerMessage *msg = [[ICustomerMessage alloc] init];
    return msg;
}
-(IMessage*)newOutMessage {
    ICustomerMessage *msg = [[ICustomerMessage alloc] init];
    msg.customerID = self.customerID;
    msg.customerAppID = self.customerAppID;
    msg.storeID = self.storeID;
    msg.sellerID = self.sellerID;
    return msg;
}
@end
