/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "PeerOutbox.h"
#import "IMService.h"
#import "PeerMessageDB.h"


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
#ifdef SQL_ENGINE_DB
    if (msg.audioContent) {
        MessageAudioContent *audioContent = [msg.audioContent cloneWithURL:url];
        [[PeerMessageDB instance] updateMessageContent:msg.msgLocalID content:audioContent.raw];
    } else if (msg.imageContent) {
        MessageImageContent *imageContent = [msg.imageContent cloneWithURL:url];
        [[PeerMessageDB instance] updateMessageContent:msg.msgLocalID content:imageContent.raw];
    }
#else
    MessageAttachmentContent *att = [[MessageAttachmentContent alloc] initWithAttachment:msg.msgLocalID url:url];
    IMessage *attachment = [[IMessage alloc] init];
    attachment.sender = msg.sender;
    attachment.receiver = msg.receiver;
    attachment.rawContent = att.raw;
    
    [[PeerMessageDB instance] insertMessage:attachment uid:msg.receiver];
#endif
}

-(void)saveMessageAttachment:(IMessage*)msg url:(NSString*)url thumbnail:(NSString*)thumbnail {
    MessageVideoContent *videoContent = [msg.videoContent cloneWithURL:url thumbnail:thumbnail];
    [[PeerMessageDB instance] updateMessageContent:msg.msgLocalID content:videoContent.raw];
}
@end
