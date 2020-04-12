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
-(SQLGroupMessageIterator*)initWithDB:(FMDatabase*)db gid:(int64_t)gid position:(int)msgID;
-(SQLGroupMessageIterator*)initWithDB:(FMDatabase*)db gid:(int64_t)gid middle:(int)msgID;
-(SQLGroupMessageIterator*)initWithDB:(FMDatabase*)db gid:(int64_t)gid last:(int)msgID;

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
        NSString *sql = @"SELECT id, sender, group_id, timestamp, flags, content FROM group_message WHERE group_id=? ORDER BY id DESC";
        self.rs = [db executeQuery:sql, @(gid)];
    }
    return self;
}

-(SQLGroupMessageIterator*)initWithDB:(FMDatabase*)db gid:(int64_t)gid position:(int)msgID {
    self = [super init];
    if (self) {
        NSString *sql = @"SELECT id, sender, group_id, timestamp, flags, content FROM group_message WHERE group_id=? AND id < ? ORDER BY id DESC";
        self.rs = [db executeQuery:sql, @(gid), @(msgID)];
    }
    return self;
}

-(SQLGroupMessageIterator*)initWithDB:(FMDatabase*)db gid:(int64_t)gid middle:(int)msgID {
    self = [super init];
    if (self) {
        NSString *sql = @"SELECT id, sender, group_id, timestamp, flags, content FROM group_message WHERE group_id=? AND id > ? AND id < ? ORDER BY id DESC";
        self.rs = [db executeQuery:sql, @(gid), @(msgID-10), @(msgID+10)];
    }
    return self;
}

//上拉刷新
-(SQLGroupMessageIterator*)initWithDB:(FMDatabase*)db gid:(int64_t)gid last:(int)msgID {
    self = [super init];
    if (self) {
        NSString *sql = @"SELECT id, sender, group_id, timestamp, flags, content FROM group_message WHERE group_id=? AND id>? ORDER BY id";
        self.rs = [db executeQuery:sql, @(gid), @(msgID)];
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
    msg.receiver = [self.rs longLongIntForColumn:@"group_id"];
    msg.timestamp = [self.rs intForColumn:@"timestamp"];
    msg.flags = [self.rs intForColumn:@"flags"];
    msg.rawContent = [self.rs stringForColumn:@"content"];
    msg.msgLocalID = [self.rs intForColumn:@"id"];
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

-(id<IMessageIterator>)newForwardMessageIterator:(int64_t)gid last:(int)lastMsgID {
    return [[SQLGroupMessageIterator alloc] initWithDB:self.db gid:gid position:lastMsgID];
}

-(id<IMessageIterator>)newMiddleMessageIterator:(int64_t)gid messageID:(int)messageID {
    return [[SQLGroupMessageIterator alloc] initWithDB:self.db gid:gid middle:messageID];
}

-(id<IMessageIterator>)newBackwardMessageIterator:(int64_t)gid messageID:(int)messageID {
    return [[SQLGroupMessageIterator alloc] initWithDB:self.db gid:gid last:messageID];
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

-(BOOL)updateMessageContent:(int)msgLocalID content:(NSString*)content {
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
        NSString *uuid = msg.uuid ? msg.uuid : @"";
        BOOL r = [db executeUpdate:@"INSERT INTO group_message (sender, group_id, timestamp, flags, uuid, content) VALUES (?, ?, ?, ?, ?, ?)",
                  @(msg.sender), @(msg.receiver), @(msg.timestamp),@(msg.flags), uuid, msg.rawContent];
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
    }
    
    [db commit];
    return YES;
}

-(BOOL)insertMessage:(IMessage*)msg {
    FMDatabase *db = self.db;
    [db beginTransaction];
    NSString *uuid = msg.uuid ? msg.uuid : @"";
    BOOL r = [db executeUpdate:@"INSERT INTO group_message (sender, group_id, timestamp, flags, uuid, content) VALUES (?, ?, ?, ?, ?, ?)",
              @(msg.sender), @(msg.receiver), @(msg.timestamp),@(msg.flags), uuid, msg.rawContent];
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
    
    
    [db commit];
    return YES;

}

-(BOOL)removeMessage:(int)msgLocalID {
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

-(BOOL)removeMessageIndex:(int)msgLocalID {
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
    FMResultSet *rs = [self.db executeQuery:@"SELECT id, sender, group_id, timestamp, flags, content FROM group_message WHERE group_id= ? ORDER BY id DESC", @(gid)];
    if ([rs next]) {
        IMessage *msg = [[IMessage alloc] init];
        msg.sender = [rs longLongIntForColumn:@"sender"];
        msg.receiver = [rs longLongIntForColumn:@"group_id"];
        msg.timestamp = [rs intForColumn:@"timestamp"];
        msg.flags = [rs intForColumn:@"flags"];
        msg.rawContent = [rs stringForColumn:@"content"];
        msg.msgLocalID = [rs intForColumn:@"id"];
        
        [rs close];
        return msg;
    }
    [rs close];
    return nil;
}

-(int)getMessageId:(NSString*)uuid {
    FMResultSet *rs = [self.db executeQuery:@"SELECT id FROM group_message WHERE uuid= ?", uuid];
    if ([rs next]) {
        int msgId = (int)[rs longLongIntForColumn:@"id"];
        [rs close];
        return msgId;
    }
    return 0;
}

-(IMessage*)getMessage:(int64_t)msgID {
    FMResultSet *rs = [self.db executeQuery:@"SELECT id, sender, group_id, timestamp, flags, content FROM group_message WHERE id= ?", @(msgID)];
    if ([rs next]) {
        IMessage *msg = [[IMessage alloc] init];
        msg.sender = [rs longLongIntForColumn:@"sender"];
        msg.receiver = [rs longLongIntForColumn:@"group_id"];
        msg.timestamp = [rs intForColumn:@"timestamp"];
        msg.flags = [rs intForColumn:@"flags"];
        msg.rawContent = [rs stringForColumn:@"content"];
        msg.msgLocalID = [rs intForColumn:@"id"];
        return msg;
    }
    return nil;
}

-(BOOL)acknowledgeMessage:(int)msgLocalID {
    return [self addFlag:msgLocalID flag:MESSAGE_FLAG_ACK];
}

-(BOOL)markMessageFailure:(int)msgLocalID {
    return [self addFlag:msgLocalID flag:MESSAGE_FLAG_FAILURE];
}

-(BOOL)markMesageListened:(int)msgLocalID {
    return [self addFlag:msgLocalID flag:MESSAGE_FLAG_LISTENED];
}


-(BOOL)addFlag:(int)msgLocalID flag:(int)f {
    FMDatabase *db = self.db;
    FMResultSet *rs = [db executeQuery:@"SELECT flags FROM group_message WHERE id=?", @(msgLocalID)];
    if (!rs) {
        return NO;
    }
    if ([rs next]) {
        int flags = [rs intForColumn:@"flags"];
        flags |= f;
        
        
        BOOL r = [db executeUpdate:@"UPDATE group_message SET flags= ? WHERE id= ?", @(flags), @(msgLocalID)];
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
    FMResultSet *rs = [db executeQuery:@"SELECT flags FROM group_message WHERE id=?", @(msgLocalID)];
    if (!rs) {
        return NO;
    }
    if ([rs next]) {
        int flags = [rs intForColumn:@"flags"];
        
        int f = MESSAGE_FLAG_FAILURE;
        flags &= ~f;
        
        BOOL r = [db executeUpdate:@"UPDATE group_message SET flags= ? WHERE id= ?", @(flags), @(msgLocalID)];
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
    
    BOOL r = [db executeUpdate:@"UPDATE group_message SET flags= ? WHERE id= ?", @(flags), @(msgLocalID)];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }
    
    return YES;
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
    return [self insertMessage:msg];
}

@end

