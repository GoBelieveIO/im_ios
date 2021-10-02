/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "SQLGroupMessageDB.h"
#import "NSString+JSMessagesView.h"

@interface SQLGroupMessageIterator : NSObject<IMessageIterator>
-(SQLGroupMessageIterator*)initWithDB:(FMDatabase*)db gid:(int64_t)gid;
-(SQLGroupMessageIterator*)initWithDB:(FMDatabase*)db gid:(int64_t)gid position:(int64_t)msgID;
-(SQLGroupMessageIterator*)initWithDB:(FMDatabase*)db gid:(int64_t)gid middle:(int64_t)msgID;
-(SQLGroupMessageIterator*)initWithDB:(FMDatabase*)db gid:(int64_t)gid last:(int64_t)msgID;

@property(nonatomic) FMResultSet *rs;
@end

@implementation SQLGroupMessageIterator

//thread safe problem
-(void)dealloc {
    [self.rs close];
}

-(SQLGroupMessageIterator*)initWithDB:(FMDatabase*)db gid:(int64_t)gid {
    self = [super init];
    if (self) {
        NSString *sql = @"SELECT id, sender, group_id, timestamp, flags, reader_count, reference_count, reference, content, tags FROM group_message WHERE group_id=? ORDER BY id DESC";
        self.rs = [db executeQuery:sql, @(gid)];
    }
    return self;
}

-(SQLGroupMessageIterator*)initWithDB:(FMDatabase*)db gid:(int64_t)gid position:(int64_t)msgID {
    self = [super init];
    if (self) {
        NSString *sql = @"SELECT id, sender, group_id, timestamp, flags, reader_count, reference_count, reference, content, tags FROM group_message WHERE group_id=? AND id < ? ORDER BY id DESC";
        self.rs = [db executeQuery:sql, @(gid), @(msgID)];
    }
    return self;
}

-(SQLGroupMessageIterator*)initWithDB:(FMDatabase*)db gid:(int64_t)gid middle:(int64_t)msgID {
    self = [super init];
    if (self) {
        NSString *sql = @"SELECT id, sender, group_id, timestamp, flags, reader_count, reference_count, reference, content, tags FROM group_message WHERE group_id=? AND id > ? AND id < ? ORDER BY id DESC";
        self.rs = [db executeQuery:sql, @(gid), @(msgID-10), @(msgID+10)];
    }
    return self;
}

//上拉刷新
-(SQLGroupMessageIterator*)initWithDB:(FMDatabase*)db gid:(int64_t)gid last:(int64_t)msgID {
    self = [super init];
    if (self) {
        NSString *sql = @"SELECT id, sender, group_id, timestamp, flags, reader_count, reference_count, reference, content, tags FROM group_message WHERE group_id=? AND id>? ORDER BY id";
        self.rs = [db executeQuery:sql, @(gid), @(msgID)];
    }
    return self;
}


-(SQLGroupMessageIterator*)initWithDB:(FMDatabase*)db gid:(int64_t)gid topic:(NSString*)uuid {
    self = [super init];
    if (self) {
        NSString *sql = @"SELECT id, sender, group_id, timestamp, flags, reader_count, reference_count, reference, content, tags FROM group_message WHERE group_id=? AND reference = ? ORDER BY id DESC";
        self.rs = [db executeQuery:sql, @(gid), uuid];
    }
    return self;
}

-(IMessage*)next {
    BOOL r = [self.rs next];
    if (!r) {
        return nil;
    }
    
    IMessage *msg = [[IMessage alloc] init];
    msg.msgId = [self.rs longLongIntForColumn:@"id"];
    msg.sender = [self.rs longLongIntForColumn:@"sender"];
    msg.receiver = [self.rs longLongIntForColumn:@"group_id"];
    msg.timestamp = [self.rs intForColumn:@"timestamp"];
    msg.flags = [self.rs intForColumn:@"flags"];
    msg.readerCount = [self.rs intForColumn:@"reader_count"];
    msg.referenceCount = [self.rs intForColumn:@"reference_count"];
    msg.reference = [self.rs stringForColumn:@"reference"];
    msg.rawContent = [self.rs stringForColumn:@"content"];
    NSString *tags = [self.rs stringForColumn:@"tags"];
    if (tags.length > 0) {
        msg.tags = [tags componentsSeparatedByString:@","];
    }
    return msg;
}

@end



@implementation SQLGroupMessageDB

+(SQLGroupMessageDB*)instance {
    static SQLGroupMessageDB *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!m) {
            m = [[SQLGroupMessageDB alloc] init];
        }
    });
    return m;
}

-(id)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}


-(id<IMessageIterator>)newMessageIterator:(int64_t)gid {
    return [[SQLGroupMessageIterator alloc] initWithDB:self.db gid:gid];
}

-(id<IMessageIterator>)newForwardMessageIterator:(int64_t)gid messageID:(int64_t)lastMsgID {
    return [[SQLGroupMessageIterator alloc] initWithDB:self.db gid:gid position:lastMsgID];
}

-(id<IMessageIterator>)newMiddleMessageIterator:(int64_t)gid messageID:(int64_t)messageID {
    return [[SQLGroupMessageIterator alloc] initWithDB:self.db gid:gid middle:messageID];
}

-(id<IMessageIterator>)newBackwardMessageIterator:(int64_t)gid messageID:(int64_t)messageID {
    return [[SQLGroupMessageIterator alloc] initWithDB:self.db gid:gid last:messageID];
}

-(id<IMessageIterator>)newTopicMessageIterator:(int64_t)gid topic:(NSString*)uuid {
    return [[SQLGroupMessageIterator alloc] initWithDB:self.db gid:gid topic:uuid];
}


-(BOOL)clearConversation:(int64_t)gid {
    FMDatabase *db = self.db;
    BOOL r = [db executeUpdate:@"DELETE FROM group_message WHERE group_id=?", @(gid)];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }
    return YES;
}


-(BOOL)clear {
    FMDatabase *db = self.db;
    BOOL r = [db executeUpdate:@"DELETE FROM group_message"];
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

-(BOOL)insertMessages:(NSArray*)msgs {
    FMDatabase *db = self.db;
    [db beginTransaction];
    
    for (IMessage *msg in msgs) {
        NSString *uuid = msg.uuid ? msg.uuid : nil;
        NSString *ref = msg.reference.length > 0 ? msg.reference : nil;
        BOOL r = [db executeUpdate:@"INSERT INTO group_message (sender, group_id, timestamp, flags, uuid, reference, content) VALUES (?, ?, ?, ?, ?, ?, ?)",
                  @(msg.sender), @(msg.receiver), @(msg.timestamp),@(msg.flags), uuid, ref, msg.rawContent];
        if (!r) {
            NSLog(@"error = %@", [db lastErrorMessage]);
            [db rollback];
            return NO;
        }
        
        int64_t rowID = [db lastInsertRowId];
        msg.msgId = rowID;
        
        if (msg.textContent) {
            NSString *text = [msg.textContent.text tokenizer];
            [db executeUpdate:@"INSERT INTO group_message_fts (docid, content) VALUES (?, ?)", @(rowID), text];
        }
        
        if (msg.reference.length > 0) {
            r = [db executeUpdate:@"UPDATE group_message SET reference_count=reference_count+1 WHERE uuid=?", msg.reference];
            if (!r) {
                //ignore the error
                NSLog(@"error = %@", [db lastErrorMessage]);
            }
        }
    }
    
    [db commit];
    return YES;
}

-(BOOL)insertMessage:(IMessage*)msg {
    FMDatabase *db = self.db;
    [db beginTransaction];
    NSString *uuid = msg.uuid.length > 0 ? msg.uuid : nil;
    NSString *ref = msg.reference.length > 0 ? msg.reference : nil;
    BOOL r = [db executeUpdate:@"INSERT INTO group_message (sender, group_id, timestamp, flags, uuid, reference, content) VALUES (?, ?, ?, ?, ?, ?, ?)",
              @(msg.sender), @(msg.receiver), @(msg.timestamp),@(msg.flags), uuid, ref, msg.rawContent];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        [db rollback];
        return NO;
    }
    
    int64_t rowID = [db lastInsertRowId];
    msg.msgId = rowID;
    
    if (msg.textContent) {
        NSString *text = [msg.textContent.text tokenizer];
        [db executeUpdate:@"INSERT INTO group_message_fts (docid, content) VALUES (?, ?)", @(rowID), text];
    }
    
    if (msg.reference.length > 0) {
        r = [db executeUpdate:@"UPDATE group_message SET reference_count=reference_count+1 WHERE uuid=?", msg.reference];
        if (!r) {
            NSLog(@"error = %@", [db lastErrorMessage]);
            [db rollback];
            return NO;
        }
    }

    [db commit];
    return YES;

}

-(BOOL)removeMessage:(int64_t)msgLocalID {
    FMDatabase *db = self.db;
    BOOL r = [db executeUpdate:@"DELETE FROM group_message WHERE id=?", @(msgLocalID)];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }
    
    r = [db executeUpdate:@"DELETE FROM group_message_fts WHERE rowid=?", @(msgLocalID)];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }
    
    return YES;
}

-(BOOL)removeMessageIndex:(int64_t)msgLocalID {
    FMDatabase *db = self.db;
    BOOL r = [db executeUpdate:@"DELETE FROM group_message_fts WHERE rowid=?", @(msgLocalID)];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }
    return YES;
}

-(NSArray*)search:(NSString*)key {
    FMDatabase *db = self.db;
    
    key = [key stringByReplacingOccurrencesOfString:@"'" withString:@"\'"];
    key = [key tokenizer];
    NSString *sql = [NSString stringWithFormat:@"SELECT rowid FROM group_message_fts WHERE group_message_fts MATCH '%@'", key];
    
    FMResultSet *rs = [db executeQuery:sql];
    NSMutableArray *array = [NSMutableArray array];
    while ([rs next]) {
        int64_t msgID = [rs longLongIntForColumn:@"rowid"];
        IMessage *msg = [self getMessage:msgID];
        if (msg) {
            [array addObject:msg];
        }
    }
    
    [rs close];
    return array;
}

-(IMessage*)getLastMessage:(int64_t)gid {
    FMResultSet *rs = [self.db executeQuery:@"SELECT id, sender, group_id, timestamp, flags, reader_count, reference_count, reference, content, tags FROM group_message WHERE group_id= ? ORDER BY id DESC", @(gid)];
    if ([rs next]) {
        IMessage *msg = [[IMessage alloc] init];
        msg.msgId = [rs longLongIntForColumn:@"id"];
        msg.sender = [rs longLongIntForColumn:@"sender"];
        msg.receiver = [rs longLongIntForColumn:@"group_id"];
        msg.timestamp = [rs intForColumn:@"timestamp"];
        msg.flags = [rs intForColumn:@"flags"];
        msg.readerCount = [rs intForColumn:@"reader_count"];
        msg.referenceCount = [rs intForColumn:@"reference_count"];
        msg.reference = [rs stringForColumn:@"reference"];
        msg.rawContent = [rs stringForColumn:@"content"];
        NSString *tags = [rs stringForColumn:@"tags"];
        if (tags.length > 0) {
            msg.tags = [tags componentsSeparatedByString:@","];
        }
        [rs close];
        return msg;
    }
    [rs close];
    return nil;
}

-(int64_t)getMessageId:(NSString*)uuid {
    FMResultSet *rs = [self.db executeQuery:@"SELECT id FROM group_message WHERE uuid=?", uuid];
    if ([rs next]) {
        int64_t msgId = [rs longLongIntForColumn:@"id"];
        [rs close];
        return msgId;
    }
    return 0;
}

-(IMessage*)getMessage:(int64_t)msgID {
    FMResultSet *rs = [self.db executeQuery:@"SELECT id, sender, group_id, timestamp, flags, reader_count, reference_count, reference, content, tags FROM group_message WHERE id= ?", @(msgID)];
    if ([rs next]) {
        IMessage *msg = [[IMessage alloc] init];
        msg.sender = [rs longLongIntForColumn:@"sender"];
        msg.receiver = [rs longLongIntForColumn:@"group_id"];
        msg.timestamp = [rs intForColumn:@"timestamp"];
        msg.flags = [rs intForColumn:@"flags"];
        msg.readerCount = [rs intForColumn:@"reader_count"];
        msg.referenceCount = [rs intForColumn:@"reference_count"];
        msg.reference = [rs stringForColumn:@"reference"];
        msg.rawContent = [rs stringForColumn:@"content"];
        msg.msgId = [rs longLongIntForColumn:@"id"];
        NSString *tags = [rs stringForColumn:@"tags"];
        if (tags.length > 0) {
            msg.tags = [tags componentsSeparatedByString:@","];
        }
        return msg;
    }
    return nil;
}

-(int)getMessageReferenceCount:(NSString*)uuid {
    FMResultSet *rs = [self.db executeQuery:@"SELECT reference_count FROM group_message WHERE uuid=?", uuid];
    if ([rs next]) {
        int count = [rs intForColumn:@"reference_count"];
        [rs close];
        return count;
    }
    return 0;
}

-(int)getMessageReaderCount:(int64_t)msgID {
    FMResultSet *rs = [self.db executeQuery:@"SELECT reader_count FROM group_message WHERE id=?", @(msgID)];
    if ([rs next]) {
        int count = [rs intForColumn:@"reader_count"];
        [rs close];
        return count;
    }
    return 0;
}

-(int)acknowledgeMessage:(int64_t)msgLocalID {
    return [self addFlag:msgLocalID flag:MESSAGE_FLAG_ACK];
}

-(int)markMessageFailure:(int64_t)msgLocalID {
    return [self addFlag:msgLocalID flag:MESSAGE_FLAG_FAILURE];
}

-(int)markMesageListened:(int64_t)msgLocalID {
    return [self addFlag:msgLocalID flag:MESSAGE_FLAG_LISTENED];
}

-(int)markMessageReaded:(int64_t)msgLocalID {
    return [self addFlag:msgLocalID  flag:MESSAGE_FLAG_READED];
}

-(int)addFlag:(int64_t)msgLocalID flag:(int)f {
    FMDatabase *db = self.db;
    FMResultSet *rs = [db executeQuery:@"SELECT flags FROM group_message WHERE id=?", @(msgLocalID)];
    if (!rs) {
        return 0;
    }
    
    int changes = 0;
    if ([rs next]) {
        int flags = [rs intForColumn:@"flags"];
        if ((flags & f) == 0) {
            flags |= f;
            
            
            BOOL r = [db executeUpdate:@"UPDATE group_message SET flags= ? WHERE id= ?", @(flags), @(msgLocalID)];
            if (!r) {
                NSLog(@"error = %@", [db lastErrorMessage]);
                return 0;
            }
            changes = [db changes];
        }
    }
    
    [rs close];
    return changes;
}


-(BOOL)eraseMessageFailure:(int64_t)msgLocalID {
    FMDatabase *db = self.db;
    FMResultSet *rs = [db executeQuery:@"SELECT flags FROM group_message WHERE id=?", @(msgLocalID)];
    if (!rs) {
        return NO;
    }
    if ([rs next]) {
        int flags = [rs intForColumn:@"flags"];
        
        int f = MESSAGE_FLAG_FAILURE;
        if (flags & f) {
            flags &= ~f;
            
            BOOL r = [db executeUpdate:@"UPDATE group_message SET flags= ? WHERE id= ?", @(flags), @(msgLocalID)];
            if (!r) {
                NSLog(@"error = %@", [db lastErrorMessage]);
                return NO;
            }
        }
    }
    
    [rs close];
    return YES;
    
}

-(BOOL)updateFlags:(int64_t)msgLocalID flags:(int)flags {
    FMDatabase *db = self.db;
    
    BOOL r = [db executeUpdate:@"UPDATE group_message SET flags= ? WHERE id= ?", @(flags), @(msgLocalID)];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }
    
    return YES;
}


-(BOOL)saveMessage:(IMessage*)msg {
    return [self insertMessage:msg];
}

-(BOOL)addMessage:(int64_t)msgId tag:(NSString*)tag {
    if (tag.length == 0) {
        return NO;
    }
    
    FMDatabase *db = self.db;
    FMResultSet *rs = [db executeQuery:@"SELECT tags FROM group_message WHERE id=?", @(msgId)];
    if (!rs) {
        return NO;
    }
    if ([rs next]) {
        NSString *tags = [rs stringForColumn:@"tags"];
        if (![tags containsString:tag]) {
            if (tags.length == 0) {
                tags = tag;
            } else {
                tags = [NSString stringWithFormat:@"%@,%@", tags, tag];
            }
            BOOL r = [db executeUpdate:@"UPDATE group_message SET tags= ? WHERE id= ?", tags, @(msgId)];
            if (!r) {
                NSLog(@"error = %@", [db lastErrorMessage]);
                return NO;
            }
        }
    }
    
    [rs close];
    return YES;
}

-(BOOL)removeMessage:(int64_t)msgId tag:(NSString*)tag {
    if (tag.length == 0) {
        return NO;
    }
    
    FMDatabase *db = self.db;
    FMResultSet *rs = [db executeQuery:@"SELECT tags FROM group_message WHERE id=?", @(msgId)];
    if (!rs) {
        return NO;
    }
    if ([rs next]) {
        NSString *tags = [rs stringForColumn:@"tags"];
        if ([tags containsString:tag]) {
            NSString *t = [NSString stringWithFormat:@"%@,", tag];
            tags = [tags stringByReplacingOccurrencesOfString:t withString:@""];
            tags = [tags stringByReplacingOccurrencesOfString:tag withString:@""];
            BOOL r = [db executeUpdate:@"UPDATE group_message SET tags = ? WHERE id= ?", tags, @(msgId)];
            if (!r) {
                NSLog(@"error = %@", [db lastErrorMessage]);
                return NO;
            }
        }
    }
    
    [rs close];
    return YES;
}


-(BOOL)addMessage:(int64_t)msgId reader:(int64_t)uid {
    FMDatabase *db = self.db;
    [db beginTransaction];
    BOOL r = [db executeUpdate:@"INSERT INTO group_message_readed (msg_id, uid) VALUES (?, ?)", @(msgId), @(uid)];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        [db rollback];
        return NO;
    }
    
    FMResultSet *rs = [db executeQuery:@"SELECT COUNT(*) as count FROM group_message_readed WHERE msg_id=?", @(msgId)];
    if (!rs) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        [db rollback];
        return NO;
    }
    
    int count = 0;
    if ([rs next]) {
        count = [rs intForColumn:@"count"];
    }
    [rs close];
    
    r = [db executeUpdate:@"UPDATE group_message SET reader_count = ? WHERE id= ?", @(count), @(msgId)];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        [db rollback];
        return NO;
    }
    [db commit];
    return YES;
}

-(NSArray*)getMessageReaders:(int64_t)msgId {
    FMDatabase *db = self.db;
    FMResultSet *rs = [db executeQuery:@"SELECT uid FROM group_message_readed WHERE msg_id = ?", @(msgId)];
    NSMutableArray *array = [NSMutableArray array];
    while ([rs next]) {
        int64_t uid = [rs longLongIntForColumn:@"uid"];
        [array addObject:@(uid)];
    }
    [rs close];
    return array;
}

@end

