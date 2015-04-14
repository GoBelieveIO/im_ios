/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import <Foundation/Foundation.h>

#import "IMessage.h"
#import "MessageDB.h"

@interface GroupConversationIterator : NSObject<ConversationIterator>

@end

@interface GroupMessageIterator : NSObject<IMessageIterator>

@end

@interface GroupMessageDB : NSObject
+(GroupMessageDB*)instance;


-(id<IMessageIterator>)newMessageIterator:(int64_t)uid;
-(id<IMessageIterator>)newMessageIterator:(int64_t)uid last:(int)lastMsgID;
-(id<ConversationIterator>)newConversationIterator;

-(BOOL)insertMessage:(IMessage*)msg;
-(BOOL)removeMessage:(int)msgLocalID gid:(int64_t)gid;
-(BOOL)clearConversation:(int64_t)gid;
-(BOOL)acknowledgeMessage:(int)msgLocalID gid:(int64_t)gid;
-(BOOL)markMessageFailure:(int)msgLocalID gid:(int64_t)gid;
-(BOOL)markMesageListened:(int)msgLocalID gid:(int64_t)gid;
@end
