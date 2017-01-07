/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "PeerOutbox.h"
#import "IMHttpAPI.h"
#import "../model/FileCache.h"
#import "IMService.h"
#import "PeerMessageDB.h"
#import "GroupMessageDB.h"
#import "wav_amr.h"
#import "UIImageView+WebCache.h"

@implementation PeerOutbox
+(PeerOutbox*)instance {
    static PeerOutbox *box;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!box) {
            box = [[PeerOutbox alloc] init];
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


- (void)sendMessage:(IMessage*)msg{
 
    IMMessage *im = [[IMMessage alloc] init];
    im.sender = msg.sender;
    im.receiver = msg.receiver;
    im.msgLocalID = msg.msgLocalID;
    
    im.content = msg.rawContent;
    
    [[IMService instance] sendPeerMessage:im];
}

-(void)markMessageFailure:(IMessage*)msg {
    [[PeerMessageDB instance] markMessageFailure:msg.msgLocalID uid:msg.receiver];
}

-(void)saveMessageAttachment:(IMessage*)msg url:(NSString*)url {
    MessageAttachmentContent *att = [[MessageAttachmentContent alloc] initWithAttachment:msg.msgLocalID url:url];
    IMessage *attachment = [[IMessage alloc] init];
    attachment.sender = msg.sender;
    attachment.receiver = msg.receiver;
    attachment.rawContent = att.raw;
    
    [[PeerMessageDB instance] insertMessage:attachment uid:msg.receiver];
}
@end
