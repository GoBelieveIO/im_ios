/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "GroupOutbox.h"
#import "IMService.h"
#import "GroupMessageDB.h"

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
    im.msgLocalID = msg.msgId;
    
    im.content = msg.rawContent;

    [[IMService instance] sendGroupMessageAsync:im];
}


//override
-(void)markMessageFailure:(IMessage*)msg {
    [[GroupMessageDB instance] markMessageFailure:msg.msgId];
}

-(void)saveMessageAttachment:(IMessage*)msg url:(NSString*)url {
    if (msg.audioContent) {
        MessageAudioContent *audioContent = [msg.audioContent cloneWithURL:url];
        [[GroupMessageDB instance] updateMessageContent:msg.msgId content:audioContent.raw];
    } else if (msg.imageContent) {
        MessageImageContent *imageContent = [msg.imageContent cloneWithURL:url];
        [[GroupMessageDB instance] updateMessageContent:msg.msgId content:imageContent.raw];
    } else if (msg.fileContent) {
        MessageFileContent *fileContent = [msg.fileContent cloneWithURL:url];
        [[GroupMessageDB instance] updateMessageContent:msg.msgId content:fileContent.raw];
    }
}

-(void)saveMessageAttachment:(IMessage*)msg url:(NSString*)url thumbnail:(NSString*)thumbnail {
    MessageVideoContent *videoContent = [msg.videoContent cloneWithURL:url thumbnail:thumbnail];
    [[GroupMessageDB instance] updateMessageContent:msg.msgId content:videoContent.raw];
}

@end
