/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "GroupOutbox.h"
#import "IMHttpAPI.h"
#import "../model/FileCache.h"
#import "IMService.h"
#import "PeerMessageDB.h"
#import "GroupMessageDB.h"
#import "wav_amr.h"
#import "UIImageView+WebCache.h"



@implementation GroupOutbox
+(GroupOutbox*)instance {
    static GroupOutbox *box;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!box) {
            box = [[GroupOutbox alloc] init];
        }
    });
    return box;
}


-(id)init {
    self = [super init];
    if (self) {

    }
    return self;
}


//override
- (void)sendMessage:(IMessage*)msg {
 
    IMMessage *im = [[IMMessage alloc] init];
    im.sender = msg.sender;
    im.receiver = msg.receiver;
    im.msgLocalID = msg.msgLocalID;
    
    im.content = msg.rawContent;

    [[IMService instance] sendGroupMessage:im];
}


//override
-(void)markMessageFailure:(IMessage*)msg {
    [[GroupMessageDB instance] markMessageFailure:msg.msgLocalID gid:msg.receiver];
}

@end
