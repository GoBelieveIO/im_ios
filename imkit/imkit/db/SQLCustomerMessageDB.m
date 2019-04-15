#import "SQLCustomerMessageDB.h"

@interface SQLCustomerMessageIterator : NSObject<IMessageIterator>

-(SQLCustomerMessageIterator*)initWithDB:(FMDatabase*)db store:(int64_t)store;

-(SQLCustomerMessageIterator*)initWithDB:(FMDatabase*)db store:(int64_t)store position:(int)msgID;

-(SQLCustomerMessageIterator*)initWithDB:(FMDatabase*)db uid:(int64_t)uid appID:(int64_t)appID;

-(SQLCustomerMessageIterator*)initWithDB:(FMDatabase*)db uid:(int64_t)uid appID:(int64_t)appID position:(int)msgID;

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
        NSString *sql = @"SELECT  id, customer_id, customer_appid, store_id, seller_id, timestamp, flags, is_support, content FROM customer_message WHERE store_id = ? ORDER BY id DESC";
        self.rs = [db executeQuery:sql, @(store)];
    }
    return self;
}

-(SQLCustomerMessageIterator*)initWithDB:(FMDatabase*)db store:(int64_t)store position:(int)msgID {
    self = [super init];
    if (self) {
        NSString *sql = @"SELECT  id, customer_id, customer_appid, store_id, seller_id, timestamp, flags, is_support, content FROM customer_message WHERE store_id = ? AND id < ? ORDER BY id DESC";
        self.rs = [db executeQuery:sql, @(store), @(msgID)];
    }
    return self;
}

-(SQLCustomerMessageIterator*)initWithDB:(FMDatabase*)db uid:(int64_t)uid appID:(int64_t)appID {
    self = [super init];
    if (self) {
        NSString *sql = @"SELECT  id, customer_id, customer_appid, store_id, seller_id, timestamp, flags, is_support, content FROM customer_message WHERE customer_id = ? AND customer_appid=? ORDER BY id DESC";
        self.rs = [db executeQuery:sql, @(uid), @(appID)];
    }
    return self;
}

-(SQLCustomerMessageIterator*)initWithDB:(FMDatabase*)db uid:(int64_t)uid appID:(int64_t)appID position:(int)msgID {
    self = [super init];
    if (self) {
        NSString *sql = @"SELECT  id, customer_id, customer_appid, store_id, seller_id, timestamp, flags, is_support, content FROM customer_message WHERE customer_id = ? AND customer_appid=? AND id < ? ORDER BY id DESC";
        self.rs = [db executeQuery:sql, @(uid), @(appID), @(msgID)];
    }
    return self;
}


-(IMessage*)next {
    BOOL r = [self.rs next];
    if (!r) {
        return nil;
    }
    
    ICustomerMessage *msg = [[ICustomerMessage alloc] init];
    msg.customerAppID = [self.rs longLongIntForColumn:@"customer_appid"];
    msg.customerID = [self.rs longLongIntForColumn:@"customer_id"];
    msg.storeID = [self.rs longLongIntForColumn:@"store_id"];
    msg.sellerID = [self.rs longLongIntForColumn:@"seller_id"];
    msg.timestamp = [self.rs intForColumn:@"timestamp"];
    msg.flags = [self.rs intForColumn:@"flags"];
    msg.isSupport = [self.rs intForColumn:@"is_support"];
    msg.rawContent = [self.rs stringForColumn:@"content"];
    msg.msgLocalID = [self.rs intForColumn:@"id"];
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

-(IMessage*)getLastMessage:(int64_t)uid appID:(int64_t)appID {
    FMResultSet *rs = [self.db executeQuery:@"SELECT id, customer_id, customer_appid, store_id, seller_id, timestamp, flags, is_support, content FROM customer_message WHERE customer_id= ? AND customer_appid=? ORDER BY id DESC", @(uid), @(appID)];
    if ([rs next]) {
        ICustomerMessage *msg = [[ICustomerMessage alloc] init];
        msg.customerAppID = [rs longLongIntForColumn:@"customer_appid"];
        msg.customerID = [rs longLongIntForColumn:@"customer_id"];
        msg.storeID = [rs longLongIntForColumn:@"store_id"];
        msg.sellerID = [rs longLongIntForColumn:@"seller_id"];
        msg.timestamp = [rs intForColumn:@"timestamp"];
        msg.flags = [rs intForColumn:@"flags"];
        msg.isSupport = [rs intForColumn:@"is_support"];
        msg.rawContent = [rs stringForColumn:@"content"];
        msg.msgLocalID = [rs intForColumn:@"id"];
        return msg;
    }
    return nil;
}

-(IMessage*)getLastMessage:(int64_t)storeID {
    FMResultSet *rs = [self.db executeQuery:@"SELECT id, customer_id, customer_appid, store_id, seller_id, timestamp, flags, is_support, content FROM customer_message WHERE store_id= ? ORDER BY id DESC", @(storeID)];
    if ([rs next]) {
        ICustomerMessage *msg = [[ICustomerMessage alloc] init];
        msg.customerAppID = [rs longLongIntForColumn:@"customer_appid"];
        msg.customerID = [rs longLongIntForColumn:@"customer_id"];
        msg.storeID = [rs longLongIntForColumn:@"store_id"];
        msg.sellerID = [rs longLongIntForColumn:@"seller_id"];
        msg.timestamp = [rs intForColumn:@"timestamp"];
        msg.flags = [rs intForColumn:@"flags"];
        msg.isSupport = [rs intForColumn:@"is_support"];
        msg.rawContent = [rs stringForColumn:@"content"];
        msg.msgLocalID = [rs intForColumn:@"id"];
        return msg;
    }
    return nil;
}

-(IMessage*)getMessage:(int)msgID {
    FMResultSet *rs = [self.db executeQuery:@"SELECT id, customer_id, customer_appid, store_id, seller_id, timestamp, flags, is_support, content FROM customer_message WHERE id= ?", @(msgID)];
    if ([rs next]) {
        ICustomerMessage *msg = [[ICustomerMessage alloc] init];
        msg.customerAppID = [rs longLongIntForColumn:@"customer_appid"];
        msg.customerID = [rs longLongIntForColumn:@"customer_id"];
        msg.storeID = [rs longLongIntForColumn:@"store_id"];
        msg.sellerID = [rs longLongIntForColumn:@"seller_id"];
        msg.timestamp = [rs intForColumn:@"timestamp"];
        msg.flags = [rs intForColumn:@"flags"];
        msg.isSupport = [rs intForColumn:@"is_support"];
        msg.rawContent = [rs stringForColumn:@"content"];
        msg.msgLocalID = [rs intForColumn:@"id"];
        return msg;
    }
    return nil;
}

-(int)getMessageId:(NSString*)uuid {
    FMResultSet *rs = [self.db executeQuery:@"SELECT id FROM customer_message WHERE uuid= ?", uuid];
    if ([rs next]) {
        int msgId = (int)[rs longLongIntForColumn:@"id"];
        [rs close];
        return msgId;
    }
    return 0;
}

-(BOOL)insertMessage:(IMessage*)msg {
    ICustomerMessage *cm = (ICustomerMessage*)msg;
    FMDatabase *db = self.db;
    int is_support = cm.isSupport ? 1 : 0;
    NSString *uuid = cm.uuid ? cm.uuid : @"";
    NSString *sql = @"INSERT INTO customer_message (customer_id, customer_appid, store_id, seller_id,\
        timestamp, flags, is_support, uuid, content) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
    BOOL r = [db executeUpdate:sql, @(cm.customerID), @(cm.customerAppID), @(cm.storeID),
              @(cm.sellerID),@(cm.timestamp), @(cm.flags), @(is_support), uuid, cm.rawContent];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }
    msg.msgId = [self.db lastInsertRowId];
    return YES;
}

-(BOOL)removeMessage:(int)msgLocalID {
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

-(BOOL)removeMessageIndex:(int)msgLocalID {
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

-(BOOL)updateMessageContent:(int)msgLocalID content:(NSString*)content {
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

-(BOOL)acknowledgeMessage:(int)msgLocalID {
    return [self addFlag:msgLocalID flag:MESSAGE_FLAG_ACK];
}

-(BOOL)markMessageFailure:(int)msgLocalID {
    return [self addFlag:msgLocalID flag:MESSAGE_FLAG_FAILURE];
}

-(BOOL)markMesageListened:(int)msgLocalID {
    return [self addFlag:msgLocalID  flag:MESSAGE_FLAG_LISTENED];
}

-(BOOL)addFlag:(int)msgLocalID flag:(int)f {
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


-(BOOL)eraseMessageFailure:(int)msgLocalID {
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


-(BOOL)updateFlags:(int)msgLocalID flags:(int)flags {
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

-(id<IMessageIterator>)newForwardMessageIterator:(int64_t)store last:(int)lastMsgID {
    return [[SQLCustomerMessageIterator alloc] initWithDB:self.db store:store position:lastMsgID];
}

-(id<IMessageIterator>)newMessageIterator:(int64_t)uid appID:(int64_t)appID {
    return [[SQLCustomerMessageIterator alloc] initWithDB:self.db uid:uid appID:appID];
}

-(id<IMessageIterator>)newMessageIterator:(int64_t)uid appID:(int64_t)appID last:(int)lastMsgID {
    return [[SQLCustomerMessageIterator alloc] initWithDB:self.db uid:uid appID:appID position:lastMsgID];
}

-(void)saveMessageAttachment:(IMessage*)msg address:(NSString*)address {
    //以附件的形式存储，以免第二次查询
    MessageAttachmentContent *att = [[MessageAttachmentContent alloc] initWithAttachment:msg.msgLocalID address:address];
    ICustomerMessage *attachment = [[ICustomerMessage alloc] init];
    attachment.rawContent = att.raw;
    [self saveMessage:attachment];
}


-(BOOL)saveMessage:(IMessage*)msg {
    return [self insertMessage:msg];
}

- (id<IMessageIterator>)newBackwardMessageIterator:(int64_t)conversationID messageID:(int)messageID {
    return nil;
}


- (id<IMessageIterator>)newMiddleMessageIterator:(int64_t)conversationID messageID:(int)messageID {
    return nil;
}



@end


