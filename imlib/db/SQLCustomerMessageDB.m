#import "SQLCustomerMessageDB.h"

@interface SQLCustomerMessageIterator : NSObject<IMessageIterator>

-(SQLCustomerMessageIterator*)initWithDB:(FMDatabase*)db store:(int64_t)store;

-(SQLCustomerMessageIterator*)initWithDB:(FMDatabase*)db store:(int64_t)store position:(int64_t)msgID;

-(SQLCustomerMessageIterator*)initWithDB:(FMDatabase*)db uid:(int64_t)uid appID:(int64_t)appID;

-(SQLCustomerMessageIterator*)initWithDB:(FMDatabase*)db uid:(int64_t)uid appID:(int64_t)appID position:(int64_t)msgID;

@property(nonatomic) FMResultSet *rs;
@end

@implementation SQLCustomerMessageIterator

//thread safe problem
-(void)dealloc {
    [self.rs close];
}

-(SQLCustomerMessageIterator*)initWithDB:(FMDatabase*)db store:(int64_t)store {
    self = [super init];
    if (self) {
        NSString *sql = @"SELECT id, sender_appid, sender, receiver_appid, receiver, timestamp, flags, content FROM customer_message WHERE store_id = ? ORDER BY id DESC";
        self.rs = [db executeQuery:sql, @(store)];
    }
    return self;
}

-(SQLCustomerMessageIterator*)initWithDB:(FMDatabase*)db store:(int64_t)store position:(int64_t)msgID {
    self = [super init];
    if (self) {
        NSString *sql = @"SELECT id, sender_appid, sender, receiver_appid, receiver, timestamp, flags, content FROM customer_message WHERE store_id = ? AND id < ? ORDER BY id DESC";
        self.rs = [db executeQuery:sql, @(store), @(msgID)];
    }
    return self;
}

-(SQLCustomerMessageIterator*)initWithDB:(FMDatabase*)db uid:(int64_t)uid appID:(int64_t)appID {
    self = [super init];
    if (self) {
        NSString *sql = @"SELECT id, sender_appid, sender, receiver_appid, receiver, timestamp, flags, content FROM customer_message WHERE peer_appid = ? AND peer = ? ORDER BY id DESC";
        self.rs = [db executeQuery:sql, @(appID), @(uid)];
    }
    return self;
}

-(SQLCustomerMessageIterator*)initWithDB:(FMDatabase*)db uid:(int64_t)uid appID:(int64_t)appID position:(int64_t)msgID {
    self = [super init];
    if (self) {
        NSString *sql = @"SELECT id, sender_appid, sender, receiver_appid, receiver, timestamp, flags, content FROM customer_message WHERE peer_appid = ? AND peer = ? AND id < ? ORDER BY id DESC";
        self.rs = [db executeQuery:sql, @(appID), @(uid),  @(msgID)];
    }
    return self;
}


-(IMessage*)next {
    BOOL r = [self.rs next];
    if (r) {
        return [self readMessage:self.rs];
    }
    return nil;
}

-(ICustomerMessage*)readMessage:(FMResultSet*)rs {
    ICustomerMessage *msg = [[ICustomerMessage alloc] init];
    msg.senderAppID = [rs longLongIntForColumn:@"sender_appid"];
    msg.sender = [rs longLongIntForColumn:@"sender"];
    msg.receiverAppID = [rs longLongIntForColumn:@"receiver_appid"];
    msg.receiver = [rs longLongIntForColumn:@"receiver"];
    msg.timestamp = [rs intForColumn:@"timestamp"];
    msg.flags = [rs intForColumn:@"flags"];
    msg.rawContent = [rs stringForColumn:@"content"];
    msg.msgId = [rs longLongIntForColumn:@"id"];
    return msg;
}

@end


@implementation SQLCustomerMessageDB
+(SQLCustomerMessageDB*)instance {
    static SQLCustomerMessageDB *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!m) {
            m = [[SQLCustomerMessageDB alloc] init];
        }
    });
    return m;
}

-(ICustomerMessage*)readMessage:(FMResultSet*)rs {
    ICustomerMessage *msg = [[ICustomerMessage alloc] init];
    msg.senderAppID = [rs longLongIntForColumn:@"sender_appid"];
    msg.sender = [rs longLongIntForColumn:@"sender"];
    msg.receiverAppID = [rs longLongIntForColumn:@"receiver_appid"];
    msg.receiver = [rs longLongIntForColumn:@"receiver"];
    msg.timestamp = [rs intForColumn:@"timestamp"];
    msg.flags = [rs intForColumn:@"flags"];
    msg.rawContent = [rs stringForColumn:@"content"];
    msg.msgId = [rs longLongIntForColumn:@"id"];
    return msg;
}

-(IMessage*)getLastMessage:(int64_t)uid appID:(int64_t)appID {
    FMResultSet *rs = [self.db executeQuery:@"SELECT id, sender_appid, sender, receiver_appid, receiver, timestamp, flags, content FROM customer_message WHERE customer_id= ? AND customer_appid=? ORDER BY id DESC", @(uid), @(appID)];
    if ([rs next]) {
        return [self readMessage:rs];
    }
    return nil;
}

-(IMessage*)getLastMessage:(int64_t)storeID {
    FMResultSet *rs = [self.db executeQuery:@"SELECT id, sender_appid, sender, receiver_appid, receiver, timestamp, flags, content FROM customer_message WHERE store_id= ? ORDER BY id DESC", @(storeID)];
    if ([rs next]) {
        return [self readMessage:rs];
    }
    return nil;
}

-(IMessage*)getMessage:(int64_t)msgID {
    FMResultSet *rs = [self.db executeQuery:@"SELECT id, sender_appid, sender, receiver_appid, receiver, timestamp, flags, content FROM customer_message WHERE id= ?", @(msgID)];
    if ([rs next]) {
        return [self readMessage:rs];
    }
    return nil;
}

-(int64_t)getMessageId:(NSString*)uuid {
    FMResultSet *rs = [self.db executeQuery:@"SELECT id FROM customer_message WHERE uuid= ?", uuid];
    if ([rs next]) {
        int64_t msgId = (int)[rs longLongIntForColumn:@"id"];
        [rs close];
        return msgId;
    }
    return 0;
}

-(BOOL)insertMessage:(IMessage*)msg uid:(int64_t)peer appid:(int64_t)peerAppId {
    ICustomerMessage *cm = (ICustomerMessage*)msg;
    FMDatabase *db = self.db;
    NSString *uuid = cm.uuid ? cm.uuid : nil;
    NSString *sql = @"INSERT INTO customer_message (peer_appid, peer, store_id, sender_appid, sender, receiver_appid, receiver,\
        timestamp, flags, uuid, content) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    BOOL r = [db executeUpdate:sql, @(peerAppId), @(peer), @(cm.content.storeId),
              @(cm.senderAppID), @(cm.sender), @(cm.receiverAppID),
              @(cm.receiver), @(cm.timestamp), @(cm.flags), uuid, cm.rawContent];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }
    msg.msgId = [self.db lastInsertRowId];
    return YES;
}

-(BOOL)removeMessage:(int64_t)msgLocalID {
    FMDatabase *db = self.db;
    BOOL r = [db executeUpdate:@"DELETE FROM customer_message WHERE id=?", @(msgLocalID)];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }
    
    r = [db executeUpdate:@"DELETE FROM customer_message_fts WHERE rowid=?", @(msgLocalID)];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }
    return YES;
    return YES;
}

-(BOOL)removeMessageIndex:(int64_t)msgLocalID {
    FMDatabase *db = self.db;
    BOOL r = [db executeUpdate:@"DELETE FROM customer_message_fts WHERE rowid=?", @(msgLocalID)];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }
    return YES;
}

-(BOOL)clearConversation:(int64_t)uid appID:(int64_t)appID {
    FMDatabase *db = self.db;
    BOOL r = [db executeUpdate:@"DELETE FROM customer_message WHERE customer_id=? AND customer_appid=?", @(uid), @(appID)];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }
    return YES;
}

-(BOOL)clearConversation:(int64_t)store {
    FMDatabase *db = self.db;
    BOOL r = [db executeUpdate:@"DELETE FROM customer_message WHERE store=?", @(store)];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }
    return YES;
}

-(BOOL)updateMessageContent:(int64_t)msgLocalID content:(NSString*)content {
    FMDatabase *db = self.db;
    
    BOOL r = [db executeUpdate:@"UPDATE group_message SET content=? WHERE id=?", content, @(msgLocalID)];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }
    
    return [db changes] == 1;
}

-(BOOL)clear {
    FMDatabase *db = self.db;
    BOOL r = [db executeUpdate:@"DELETE FROM customer_message"];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }
    return YES;
}

-(BOOL)acknowledgeMessage:(int64_t)msgLocalID {
    return [self addFlag:msgLocalID flag:MESSAGE_FLAG_ACK];
}

-(BOOL)markMessageFailure:(int64_t)msgLocalID {
    return [self addFlag:msgLocalID flag:MESSAGE_FLAG_FAILURE];
}

-(BOOL)markMesageListened:(int64_t)msgLocalID {
    return [self addFlag:msgLocalID  flag:MESSAGE_FLAG_LISTENED];
}

-(BOOL)markMessageReaded:(int64_t)msgLocalID {
    return [self addFlag:msgLocalID  flag:MESSAGE_FLAG_READED];
}

-(BOOL)addFlag:(int64_t)msgLocalID flag:(int)f {
    FMDatabase *db = self.db;
    FMResultSet *rs = [db executeQuery:@"SELECT flags FROM customer_message WHERE id=?", @(msgLocalID)];
    if (!rs) {
        return NO;
    }
    if ([rs next]) {
        int flags = [rs intForColumn:@"flags"];
        flags |= f;
        
        
        BOOL r = [db executeUpdate:@"UPDATE customer_message SET flags= ? WHERE id= ?", @(flags), @(msgLocalID)];
        if (!r) {
            NSLog(@"error = %@", [db lastErrorMessage]);
            return NO;
        }
    }
    
    [rs close];
    return YES;
}


-(BOOL)eraseMessageFailure:(int64_t)msgLocalID {
    FMDatabase *db = self.db;
    FMResultSet *rs = [db executeQuery:@"SELECT flags FROM customer_message WHERE id=?", @(msgLocalID)];
    if (!rs) {
        return NO;
    }
    if ([rs next]) {
        int flags = [rs intForColumn:@"flags"];
        
        int f = MESSAGE_FLAG_FAILURE;
        flags &= ~f;
        
        BOOL r = [db executeUpdate:@"UPDATE customer_message SET flags= ? WHERE id= ?", @(flags), @(msgLocalID)];
        if (!r) {
            NSLog(@"error = %@", [db lastErrorMessage]);
            return NO;
        }
    }
    
    [rs close];
    return YES;
    
}


-(BOOL)updateFlags:(int64_t)msgLocalID flags:(int)flags {
    FMDatabase *db = self.db;
    
    BOOL r = [db executeUpdate:@"UPDATE customer_message SET flags= ? WHERE id= ?", @(flags), @(msgLocalID)];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }
    return YES;
}


-(id<IMessageIterator>)newMessageIterator:(int64_t)store {
    return [[SQLCustomerMessageIterator alloc] initWithDB:self.db store:store];
}

-(id<IMessageIterator>)newForwardMessageIterator:(int64_t)store last:(int64_t)lastMsgID {
    return [[SQLCustomerMessageIterator alloc] initWithDB:self.db store:store position:lastMsgID];
}

-(id<IMessageIterator>)newMessageIterator:(int64_t)uid appID:(int64_t)appID {
    return [[SQLCustomerMessageIterator alloc] initWithDB:self.db uid:uid appID:appID];
}

-(id<IMessageIterator>)newForwardMessageIterator:(int64_t)uid appID:(int64_t)appID last:(int64_t)lastMsgID {
    return [[SQLCustomerMessageIterator alloc] initWithDB:self.db uid:uid appID:appID position:lastMsgID];
}



-(BOOL)saveMessage:(IMessage*)msg {
    ICustomerMessage *cm = (ICustomerMessage*)msg;
    return [self insertMessage:msg uid:cm.receiver appid:cm.receiverAppID];
}

- (id<IMessageIterator>)newBackwardMessageIterator:(int64_t)conversationID messageID:(int64_t)messageID {
    return nil;
}


- (id<IMessageIterator>)newMiddleMessageIterator:(int64_t)conversationID messageID:(int64_t)messageID {
    return nil;
}

- (id<IMessageIterator>)newForwardMessageIterator:(int64_t)conversationID messageID:(int64_t)messageID {
    return nil;
}




@end


