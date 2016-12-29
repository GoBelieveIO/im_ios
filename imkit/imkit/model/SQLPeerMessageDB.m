#import "SQLPeerMessageDB.h"

@interface SQLPeerMessageIterator : NSObject<IMessageIterator>

-(SQLPeerMessageIterator*)initWithDB:(FMDatabase*)db peer:(int64_t)peer;

-(SQLPeerMessageIterator*)initWithDB:(FMDatabase*)db peer:(int64_t)peer position:(int)msgID;

@property(nonatomic, strong) FMResultSet *rs;
@end

@implementation SQLPeerMessageIterator

//thread safe problem
-(void)dealloc {
    [self.rs close];
}

-(SQLPeerMessageIterator*)initWithDB:(FMDatabase*)db peer:(int64_t)peer {
    self = [super init];
    if (self) {
        NSString *sql = @"SELECT id, sender, receiver, timestamp, flags, content FROM peer_message WHERE peer = ? ORDER BY id DESC";
        self.rs = [db executeQuery:sql, @(peer)];
    }
    return self;
}

-(SQLPeerMessageIterator*)initWithDB:(FMDatabase*)db peer:(int64_t)peer position:(int)msgID {
    self = [super init];
    if (self) {
        NSString *sql = @"SELECT id, sender, receiver, timestamp, flags, content FROM peer_message WHERE peer = ? AND id < ? ORDER BY id DESC";
        self.rs = [db executeQuery:sql, @(peer), @(msgID)];
    }
    return self;
}

-(IMessage*)next {
    BOOL r = [self.rs next];
    if (!r) {
        return nil;
    }
 
    IMessage *msg = [[IMessage alloc] init];
    msg.sender = [self.rs longLongIntForColumn:@"sender"];
    msg.receiver = [self.rs longLongIntForColumn:@"receiver"];
    msg.timestamp = [self.rs intForColumn:@"timestamp"];
    msg.flags = [self.rs intForColumn:@"flags"];
    msg.rawContent = [self.rs stringForColumn:@"content"];
    msg.msgLocalID = [self.rs intForColumn:@"id"];
    return msg;
}

@end


@interface SQLPeerConversationIterator : NSObject<ConversationIterator>
@property(nonatomic, strong) FMResultSet *rs;
@property(nonatomic, strong) FMDatabase *db;
@end

@implementation SQLPeerConversationIterator

//thread safe problem
-(void)dealloc {
    [self.rs close];
}

-(IMessage*)getMessage:(int)msgID {
    FMDatabase *rs = [self.db executeQuery:@"SELECT id, sender, receiver, timestamp, flags, content FROM peer_message WHERE id= ?", @(msgID)];
    IMessage *msg = [[IMessage alloc] init];
    msg.sender = [self.rs longLongIntForColumn:@"sender"];
    msg.receiver = [self.rs longLongIntForColumn:@"receiver"];
    msg.timestamp = [self.rs intForColumn:@"timestamp"];
    msg.flags = [self.rs intForColumn:@"flags"];
    msg.rawContent = [self.rs stringForColumn:@"content"];
    msg.msgLocalID = [self.rs intForColumn:@"id"];
    return msg;
}

-(SQLPeerConversationIterator*)initWithDB:(FMDatabase*)db {
    self = [super init];
    if (self) {
        self.db = db;
        self.rs = [db executeQuery:@"SELECT MAX(id) as id, peer FROM peer_message GROUP BY peer"];
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


@implementation SQLPeerMessageDB
+(SQLPeerMessageDB*)instance {
    static SQLPeerMessageDB *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!m) {
            m = [[SQLPeerMessageDB alloc] init];
        }
    });
    return m;
}


-(BOOL)insertMessage:(IMessage*)msg uid:(int64_t)uid{
    FMDatabase *db = self.db;
    BOOL r = [db executeUpdate:@"INSERT INTO peer_message (peer, sender, receiver, timestamp, flags, content) VALUES (?, ?, ?, ?, ?, ?)",
              @(uid), @(msg.sender), @(msg.receiver), @(msg.timestamp),@(msg.flags), msg.rawContent];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }
    msg.msgLocalID = [self.db lastInsertRowId];
    return YES;
}

-(BOOL)removeMessage:(int)msgLocalID uid:(int64_t)uid{
    FMDatabase *db = self.db;
    BOOL r = [db executeUpdate:@"DELETE FROM peer_message WHERE id=?", @(msgLocalID)];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }
    return YES;
}

-(BOOL)clearConversation:(int64_t)uid {
    FMDatabase *db = self.db;
    BOOL r = [db executeUpdate:@"DELETE FROM peer_message WHERE peer=?", @(uid)];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }
    return YES;
}

-(BOOL)clear {
    FMDatabase *db = self.db;
    BOOL r = [db executeUpdate:@"DELETE FROM peer_message"];
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
    FMResultSet *rs = [db executeQuery:@"SELECT flags FROM peer_message WHERE id=?", @(msgLocalID)];
    if (!rs) {
        return NO;
    }
    if ([rs next]) {
        int flags = [rs intForColumn:@"flags"];
        flags |= f;
        
        
        BOOL r = [db executeUpdate:@"UPDATE peer_message SET flags= ? WHERE id= ?", @(flags), @(msgLocalID)];
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
    FMResultSet *rs = [db executeQuery:@"SELECT flags FROM peer_message WHERE id=?", @(msgLocalID)];
    if (!rs) {
        return NO;
    }
    if ([rs next]) {
        int flags = [rs intForColumn:@"flags"];
        
        int f = MESSAGE_FLAG_FAILURE;
        flags &= ~f;
        
        BOOL r = [db executeUpdate:@"UPDATE peer_message SET flags= ? WHERE id= ?", @(flags), @(msgLocalID)];
        if (!r) {
            NSLog(@"error = %@", [db lastErrorMessage]);
            return NO;
        }
    }
    
    [rs close];
    return YES;
    
}

-(id<IMessageIterator>)newMessageIterator:(int64_t)uid {
    return [[SQLPeerMessageIterator alloc] initWithDB:self.db peer:uid];
}

-(id<IMessageIterator>)newMessageIterator:(int64_t)uid last:(int)lastMsgID {
    return [[SQLPeerMessageIterator alloc] initWithDB:self.db peer:uid position:lastMsgID];
}

-(id<ConversationIterator>)newConversationIterator {
    return [[SQLPeerConversationIterator alloc] initWithDB:self.db];
}

@end


