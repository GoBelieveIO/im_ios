//
//  Database.m
//  contact
//
//  Created by houxh on 2018/10/8.
//  Copyright © 2018年 momo. All rights reserved.
//

#import "Database.h"
#import <fmdb/FMDB.h>
#import <sqlite3.h>

#define DATABASE_VERSION 6

#define PEER_MESSAGE @"CREATE TABLE \"peer_message\" ( `id` INTEGER PRIMARY KEY AUTOINCREMENT, `peer` INTEGER NOT NULL, `secret` INTEGER DEFAULT 0, `sender` INTEGER NOT NULL, `receiver` INTEGER NOT NULL, `timestamp` INTEGER NOT NULL, `flags` INTEGER NOT NULL, `content` TEXT, `uuid` TEXT );"

#define GROUP_MESSAGE @"CREATE TABLE \"group_message\" ( `id` INTEGER PRIMARY KEY AUTOINCREMENT, `sender` INTEGER NOT NULL, `group_id` INTEGER NOT NULL, `timestamp` INTEGER NOT NULL, `flags` INTEGER NOT NULL, `reader_count` INTEGER DEFAULT 0, `content` TEXT, `uuid` TEXT, `reference_count` INTEGER DEFAULT 0, `reference` TEXT, `tags` TEXT );"

#define CUSTOMER_MESSAGE @"CREATE TABLE `customer_message` ( `id` INTEGER PRIMARY KEY AUTOINCREMENT, `peer_appid` INTEGER NOT NULL, `peer` INTEGER NOT NULL, `store_id` INTEGER NOT NULL, `sender_appid` INTEGER NOT NULL, `sender` INTEGER NOT NULL, `receiver_appid` INTEGER NOT NULL, `receiver` INTEGER NOT NULL, `timestamp` INTEGER NOT NULL, `flags` INTEGER NOT NULL, `content` TEXT, `uuid` TEXT );"

#define PEER_MESSAGE_FTS @"CREATE VIRTUAL TABLE peer_message_fts USING fts4(content TEXT);"

#define GROUP_MESSAGE_FTS @"CREATE VIRTUAL TABLE group_message_fts USING fts4(content TEXT);"

#define CUSTOMER_MESSAGE_FTS @"CREATE VIRTUAL TABLE customer_message_fts USING fts4(content TEXT);"

#define GROUP_MESSAGE_READED @"CREATE TABLE \"group_message_readed\" ( `msg_id` INTEGER NOT NULL, `uid` INTEGER NOT NULL, PRIMARY KEY(`msg_id`,`uid`) )"

#define PEER_MESSAGE_IDX  @"CREATE INDEX `peer_index` ON `peer_message` (`peer`, `secret`, `id`);"
#define GROUP_MESSAGE_IDX @"CREATE INDEX `group_index` ON `group_message` (`group_id` )"
#define CUSTOMER_MESSAGE_IDX @"CREATE INDEX `customer_index` ON `customer_message` (`peer_appid`, `peer`)"
#define CUSTOMER_MESSAGE_STORE_IDX @"CREATE INDEX `customer_store_index` ON `customer_message` (`store_id`)"

#define PEER_MESSAGE_UUID_IDX  @"CREATE UNIQUE INDEX `peer_uuid_index` ON `peer_message` (`uuid`)"
#define GROUP_MESSAGE_UUID_IDX  @"CREATE UNIQUE INDEX `group_uuid_index` ON `group_message` (`uuid`)"
#define CUSTOMER_MESSAGE_UUID_IDX  @"CREATE UNIQUE INDEX `customer_uuid_index` ON `customer_message` (`uuid`)"


//cid:peer_uid|group_id|store_id
#define CONVERSATION  @"CREATE TABLE IF NOT EXISTS `conversation` "\
"(`id` INTEGER PRIMARY KEY NOT NULL , "\
"`appid` INTEGER DEFAULT 0, "\
"`target` INTEGER NOT NULL, "\
"`type` INTEGER NOT NULL, "\
"`name` VARCHAR(255), "\
"`attrs` TEXT, "\
"`flags` INTEGER DEFAULT 0, "\
"`detail` TEXT, "\
"`state` INTEGER DEFAULT 0, "\
"`timestamp` INTEGER DEFAULT 0, "\
"`unread` INTEGER DEFAULT 0) "


#define CONVERSATION_IDX @"CREATE UNIQUE INDEX [conversation_idx] On [conversation] ([appid], [target], [type]);"







@implementation Database

+(void)createDatabaseTable:(FMDatabase*)db2 {
    [db2 beginTransaction];
    [db2 executeUpdate:PEER_MESSAGE];
    [db2 executeUpdate:GROUP_MESSAGE];
    [db2 executeUpdate:CUSTOMER_MESSAGE];
    
    [db2 executeUpdate:PEER_MESSAGE_FTS];
    [db2 executeUpdate:GROUP_MESSAGE_FTS];
    [db2 executeUpdate:CUSTOMER_MESSAGE_FTS];
    
    [db2 executeUpdate:PEER_MESSAGE_IDX];
    [db2 executeUpdate:GROUP_MESSAGE_IDX];
    [db2 executeUpdate:CUSTOMER_MESSAGE_IDX];
    
    [db2 executeUpdate:CUSTOMER_MESSAGE_STORE_IDX];
    
    [db2 executeUpdate:PEER_MESSAGE_UUID_IDX];
    [db2 executeUpdate:GROUP_MESSAGE_UUID_IDX];
    [db2 executeUpdate:CUSTOMER_MESSAGE_UUID_IDX];
    
    [db2 executeUpdate:CONVERSATION];
    [db2 executeUpdate:CONVERSATION_IDX];
    
    [db2 executeUpdate:GROUP_MESSAGE_READED];
    
    [db2 setUserVersion:DATABASE_VERSION];
    [db2 commit];
}

+(FMDatabase*)openMessageDB:(NSString*)dbPath {
    //检查数据库文件是否已经存在
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL dbExists = [fileManager fileExistsAtPath:dbPath];
    FMDatabase *db2 = [[FMDatabase alloc] initWithPath:dbPath];
    BOOL r = [db2 openWithFlags:SQLITE_OPEN_CREATE|SQLITE_OPEN_READWRITE|SQLITE_OPEN_WAL vfs:nil];
    if (!r) {
        NSLog(@"open database error:%@", [db2 lastError]);
        NSAssert(NO, @"");
        return nil;
    }
    
    if (!dbExists) {
        //create db
        [self createDatabaseTable:db2];
    }
    
    uint32_t version = [db2 userVersion];
    
    
    NSAssert(version == DATABASE_VERSION, @"database version");
    return db2;
}

@end
