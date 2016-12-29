/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */
#import "MessageDB.h"

#ifdef FILE_ENGINE_DB
#import "FileGroupMessageDB.h"
typedef FileGroupMessageDB GroupMessageDB;
#elif defined SQL_ENGINE_DB
#import "SQLGroupMessageDB.h"
typedef SQLGroupMessageDB GroupMessageDB;
#else
#error "no engine"
#endif

