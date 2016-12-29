/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "SQLGroupMessageDB.h"
#import "MessageDB.h"
#include <sys/stat.h>
#include <dirent.h>
#import "util.h"
#import "ReverseFile.h"


@interface SQLGroupMessageIterator : NSObject<IMessageIterator>

-(SQLGroupMessageIterator*)initWithDB:(FMDatabase*)db gid:(int64_t)gid;

-(SQLGroupMessageIterator*)initWithDB:(FMDatabase*)db gid:(int64_t)gid position:(int)msgID;

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


@interface SQLGroupConversationIterator : NSObject<ConversationIterator>
@property(nonatomic) FMResultSet *rs;
@property(nonatomic) FMDatabase *db;
@end

@implementation SQLGroupConversationIterator

//thread safe problem
-(void)dealloc {
    [self.rs close];
}

-(IMessage*)getMessage:(int)msgID {
    FMDatabase *rs = [self.db executeQuery:@"SELECT id, sender, group_id, timestamp, flags, content FROM group_message WHERE id= ?", @(msgID)];
    IMessage *msg = [[IMessage alloc] init];
    msg.sender = [self.rs longLongIntForColumn:@"sender"];
    msg.receiver = [self.rs longLongIntForColumn:@"group_id"];
    msg.timestamp = [self.rs intForColumn:@"timestamp"];
    msg.flags = [self.rs intForColumn:@"flags"];
    msg.rawContent = [self.rs stringForColumn:@"content"];
    msg.msgLocalID = [self.rs intForColumn:@"id"];
    return msg;
}

-(SQLGroupConversationIterator*)initWithDB:(FMDatabase*)db {
    self = [super init];
    if (self) {
        self.db = db;
        self.rs = [db executeQuery:@"SELECT MAX(id) as id, group_id FROM group_message GROUP BY group_id"];
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

-(id<IMessageIterator>)newMessageIterator:(int64_t)gid last:(int)lastMsgID {
    return [[SQLGroupMessageIterator alloc] initWithDB:self.db gid:gid position:lastMsgID];
}

-(id<ConversationIterator>)newConversationIterator {
    return [[SQLGroupConversationIterator alloc] initWithDB:self.db];
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

-(BOOL)insertMessage:(IMessage*)msg {
    FMDatabase *db = self.db;
    BOOL r = [db executeUpdate:@"INSERT INTO group_message (sender, group_id, timestamp, flags, content) VALUES (?, ?, ?, ?, ?)",
              @(msg.sender), @(msg.receiver), @(msg.timestamp),@(msg.flags), msg.rawContent];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }
    
    msg.msgLocalID = [db lastInsertRowId];
    return YES;

}

-(BOOL)removeMessage:(int)msgLocalID gid:(int64_t)gid{
    FMDatabase *db = self.db;
    BOOL r = [db executeUpdate:@"DELETE FROM group_message WHERE id=?", @(msgLocalID)];
    if (!r) {
        NSLog(@"error = %@", [db lastErrorMessage]);
        return NO;
    }
    return YES;
}

-(BOOL)acknowledgeMessage:(int)msgLocalID gid:(int64_t)gid {
    return [self addFlag:msgLocalID flag:MESSAGE_FLAG_ACK];
}

-(BOOL)markMessageFailure:(int)msgLocalID gid:(int64_t)gid {
    return [self addFlag:msgLocalID flag:MESSAGE_FLAG_FAILURE];
}

-(BOOL)markMesageListened:(int)msgLocalID gid:(int64_t)gid{
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


-(BOOL)eraseMessageFailure:(int)msgLocalID gid:(int64_t)gid {
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


@end

