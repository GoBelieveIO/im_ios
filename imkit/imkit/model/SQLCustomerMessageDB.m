#import "SQLCustomerMessageDB.h"

@interface SQLCustomerMessageIterator : NSObject<IMessageIterator>

-(SQLCustomerMessageIterator*)initWithDB:(FMDatabase*)db store:(int64_t)store;

-(SQLCustomerMessageIterator*)initWithDB:(FMDatabase*)db store:(int64_t)store position:(int)msgID;

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


@interface SQLCustomerConversationIterator : NSObject<ConversationIterator>
@property(nonatomic) FMResultSet *rs;
@property(nonatomic) FMDatabase *db;
@end

@implementation SQLCustomerConversationIterator

//thread safe problem
-(void)dealloc {
    [self.rs close];
}

-(IMessage*)getMessage:(int)msgID {
    FMDatabase *rs = [self.db executeQuery:@"SELECT id, customer_id, customer_appid, store_id, seller_id, timestamp, flags, is_support, content FROM customer_message WHERE id= ?", @(msgID)];
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

-(SQLCustomerConversationIterator*)initWithDB:(FMDatabase*)db {
    self = [super init];
    if (self) {
        self.db = db;
        self.rs = [db executeQuery:@"SELECT MAX(id) as id, store_id FROM customer_message GROUP BY store_id"];
    }
    return self;
}

-(IMessage*)next {
    BOOL r = [self.rs next];
    if (!r) {
        return nil;
    }
    
    int msgID = [self.rs intForColumn:@"id"];
    
    return [self getMessage:msgID];
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


-(BOOL)insertMessage:(IMessage*)msg uid:(int64_t)uid{
    ICustomerMessage *cm = (ICustomerMessage*)msg;
    FMDatabase *db = self.db;
    int is_support = cm.isSupport ? 1 : 0;
    NSString *sql = @"INSERT INTO customer_message (customer_id, customer_appid, store_id, seller_id,\
        timestamp, flags, is_support, content) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
    BOOL r = [db executeUpdate:sql, @(cm.customerID), @(cm.customerAppID), @(cm.storeID),
              @(cm.sellerID),@(cm.timestamp), @(cm.flags), @(is_support), cm.rawContent];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }
    msg.msgLocalID = [self.db lastInsertRowId];
    return YES;
}

-(BOOL)removeMessage:(int)msgLocalID uid:(int64_t)uid{
    FMDatabase *db = self.db;
    BOOL r = [db executeUpdate:@"DELETE FROM customer_message WHERE id=?", @(msgLocalID)];
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

-(BOOL)clear {
    FMDatabase *db = self.db;
    BOOL r = [db executeUpdate:@"DELETE FROM customer_message"];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }
    return YES;
}

-(BOOL)acknowledgeMessage:(int)msgLocalID uid:(int64_t)uid {
    return [self addFlag:msgLocalID flag:MESSAGE_FLAG_ACK];
}

-(BOOL)markMessageFailure:(int)msgLocalID uid:(int64_t)uid {
    [self addFlag:msgLocalID flag:MESSAGE_FLAG_FAILURE];
}

-(BOOL)markMesageListened:(int)msgLocalID uid:(int64_t)uid {
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


-(BOOL)eraseMessageFailure:(int)msgLocalID uid:(int64_t)uid {
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

-(id<IMessageIterator>)newMessageIterator:(int64_t)store {
    return [[SQLCustomerMessageIterator alloc] initWithDB:self.db store:store];
}

-(id<IMessageIterator>)newMessageIterator:(int64_t)store last:(int)lastMsgID {
    return [[SQLCustomerMessageIterator alloc] initWithDB:self.db store:store position:lastMsgID];
}

-(id<ConversationIterator>)newConversationIterator {
    return [[SQLCustomerConversationIterator alloc] initWithDB:self.db];
}

@end


