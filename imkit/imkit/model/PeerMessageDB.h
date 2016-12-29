/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */
#import "MessageDB.h"

#ifdef FILE_ENGINE_DB
#import "FilePeerMessageDB.h"
typedef FilePeerMessageDB PeerMessageDB;
#elif defined SQL_ENGINE_DB
#import "SQLPeerMessageDB.h"
typedef SQLPeerMessageDB PeerMessageDB;
#else
#error "no engine"
#endif

