/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */
#import "MessageDB.h"

#if 0
#import "FileGroupMessageDB.h"
typedef FileGroupMessageDB GroupMessageDB;
#define PEER_FILE_ENGINE_DB
#else
#import "SQLGroupMessageDB.h"
typedef SQLGroupMessageDB GroupMessageDB;
#define PEER_SQL_ENGINE_DB
#endif

