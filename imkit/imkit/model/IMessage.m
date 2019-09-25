/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "IMessage.h"




/*
 raw format
 {
    "text":"文本",
    "image":"image url",
    "image2": {
        "url":"image url",
        "width":"宽度(整数)",
        "height":"高度(整数)"
    }
    "audio": {
        "url":"audio url",
        "duration":"时长(整数)"
    }
    "location":{
        "latitude":"纬度(浮点数)",
        "longitude":"经度(浮点数)"
    }
    "notification":"群组通知内容"
    "link":{
        "image":"图片url",
        "url":"跳转url",
        "title":"标题"
    }
    "video":{
         "url":"视频url",
         "thumbnail":"视频缩略图url",
         "width":"宽度(整数)",
         "height":"高度(整数)",
         "duration":"时长(整数)"
     }
     "file":{
         "url":"文件url",
         "filename":"文件名称",
         "size":"文件大小"
     }
     "revoke": {
        "msgid": "被撤回消息的uuid"
     }
}*/


@implementation IMessage
+(MessageContent*)fromRaw:(NSString *)rawContent {
    const char *utf8 = [rawContent UTF8String];
    if (utf8 == nil) return nil;
    NSData *data = [NSData dataWithBytes:utf8 length:strlen(utf8)];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
    
    MessageContent *content = nil;
    if ([dict objectForKey:@"text"] != nil) {
        content = [[MessageTextContent alloc] initWithRaw:rawContent];
    } else if ([dict objectForKey:@"image"] != nil ||
               [dict objectForKey:@"image2"] != nil) {
        content = [[MessageImageContent alloc] initWithRaw:rawContent];
    } else if ([dict objectForKey:@"audio"] != nil) {
        content = [[MessageAudioContent alloc] initWithRaw:rawContent];
    } else if ([dict objectForKey:@"location"] != nil) {
        content = [[MessageLocationContent alloc] initWithRaw:rawContent];
    } else if ([dict objectForKey:@"notification"] != nil) {
        content = [[MessageGroupNotificationContent alloc] initWithRaw:rawContent];
    } else if ([dict objectForKey:@"link"]) {
        content = [[MessageLinkContent alloc] initWithRaw:rawContent];
    } else if ([dict objectForKey:@"attachment"] != nil) {
        content = [[MessageAttachmentContent alloc] initWithRaw:rawContent];
    } else if ([dict objectForKey:@"timestamp"] != nil) {
        content = [[MessageTimeBaseContent alloc] initWithRaw:rawContent];
    } else if ([dict objectForKey:@"headline"] != nil) {
        content = [[MessageHeadlineContent alloc] initWithRaw:rawContent];
    } else if ([dict objectForKey:@"voip"] != nil) {
        content = [[MessageVOIPContent alloc] initWithRaw:rawContent];
    } else if ([dict objectForKey:@"group_voip"] != nil) {
        content = [[MessageGroupVOIPContent alloc] initWithRaw:rawContent];
    } else if ([dict objectForKey:@"p2p_session"] != nil) {
        content = [[MessageP2PSession alloc] initWithRaw:rawContent];
    } else if ([dict objectForKey:@"secret"] != nil) {
        content = [[MessageSecret alloc] initWithRaw:rawContent];
    } else if ([dict objectForKey:@"voip"]) {
        content = [[MessageVideo alloc] initWithRaw:rawContent];
    } else if ([dict objectForKey:@"file"]) {
        content = [[MessageFile alloc] initWithRaw:rawContent];
    } else if ([dict objectForKey:@"video"]) {
        content = [[MessageVideo alloc] initWithRaw:rawContent];
    } else if ([dict objectForKey:@"revoke"]) {
        content = [[MessageRevoke alloc] initWithRaw:rawContent];
    } else if ([dict objectForKey:@"ack"]) {
        content = [[MessageACK alloc] initWithRaw:rawContent];
    }
    
    return content;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    IMessage *m = [[[self class] allocWithZone:zone] init];
    m.msgLocalID = self.msgLocalID;
    m.secret = self.secret;
    m.flags = self.flags;
    m.sender = self.sender;
    m.receiver = self.receiver;
    m.timestamp = self.timestamp;
    m.content = self.content;
    m.isOutgoing = self.isOutgoing;
    m.senderInfo = self.senderInfo;
    return m;
}

-(int)msgLocalID {
    return (int)self.msgId;
}

-(void)setMsgLocalID:(int)msgLocalID {
    self.msgId = msgLocalID;
}

-(BOOL)isACK {
    return self.flags&MESSAGE_FLAG_ACK;
}

-(BOOL)isFailure {
    return self.flags&MESSAGE_FLAG_FAILURE;
}

-(BOOL)isListened{
    return self.flags&MESSAGE_FLAG_LISTENED;
}

-(BOOL)isIncomming {
    return !self.isOutgoing;
}

-(void)setContent:(MessageContent *)content {
    _content = content;
    _rawContent = content.raw;
}

-(void)setRawContent:(NSString *)rawContent {
    _rawContent = [rawContent copy];
    _content = [[self class] fromRaw:rawContent];
}

-(int)type {
    return self.content.type;
}
-(NSString*)uuid {
    return [self.content uuid];
}
-(MessageTextContent*)textContent {
    if (self.type == MESSAGE_TEXT) {
        return (MessageTextContent*)self.content;
    }
    return nil;
}

-(MessageImageContent*)imageContent {
    if (self.type == MESSAGE_IMAGE) {
        return (MessageImageContent*)self.content;
    }
    return nil;
}

-(MessageAudioContent*)audioContent {
    if (self.type == MESSAGE_AUDIO) {
        return (MessageAudioContent*)self.content;
    }
    return nil;
}

-(MessageLocationContent*)locationContent {
    if (self.type == MESSAGE_LOCATION) {
        return (MessageLocationContent*)self.content;
    }
    return nil;
}

-(MessageNotificationContent*)notificationContent {
    if (self.type == MESSAGE_GROUP_NOTIFICATION ||
        self.type == MESSAGE_TIME_BASE ||
        self.type == MESSAGE_HEADLINE ||
        self.type == MESSAGE_GROUP_VOIP ||
        self.type == MESSAGE_REVOKE ||
        self.type == MESSAGE_ACK) {
        return (MessageNotificationContent*)self.content;
    }
    return nil;
}

-(MessageLinkContent*)linkContent {
    if (self.type == MESSAGE_LINK) {
        return (MessageLinkContent*)self.content;
    }
    return nil;
}

-(MessageAttachmentContent*)attachmentContent {
    if (self.type == MESSAGE_ATTACHMENT) {
        return (MessageAttachmentContent*)self.content;
    }
    return nil;
}

-(MessageTimeBaseContent*)timeBaseContent {
    if (self.type == MESSAGE_TIME_BASE) {
        return (MessageTimeBaseContent*)self.content;
    }
    return nil;
}

-(MessageVOIPContent*)voipContent {
    if (self.type == MESSAGE_VOIP) {
        return (MessageVOIPContent*)self.content;
    }
    return nil;
}

-(MessageGroupVOIPContent*)groupVOIPContent {
    if (self.type == MESSAGE_GROUP_VOIP) {
        return (MessageGroupVOIPContent*)self.content;
    }
    return nil;
}

-(MessageGroupNotificationContent*)groupNotificationContent {
    if (self.type == MESSAGE_GROUP_NOTIFICATION) {
        return (MessageGroupNotificationContent*)self.content;
    }
    return nil;
}

-(MessageP2PSession*)p2pSessionContent {
    if (self.type == MESSAGE_P2P_SESSION) {
        return (MessageP2PSession*)self.content;
    }
    return nil;
}

-(MessageSecret*)secretContent {
    if (self.type == MESSAGE_SECRET) {
        return (MessageSecret*)self.content;
    }
    return nil;
}

-(MessageVideo*)videoContent {
    if (self.type == MESSAGE_VIDEO) {
        return (MessageVideo*)self.content;
    }
    return nil;
}

-(MessageFile*)fileContent {
    if (self.type == MESSAGE_FILE) {
        return (MessageFile*)self.content;
    }
    return nil;
}

-(MessageRevoke*)revokeContent {
    if (self.type == MESSAGE_REVOKE) {
        return (MessageRevoke*)self.content;
    }
    return nil;
}

-(MessageACK*)ackContent {
    if (self.type == MESSAGE_ACK) {
        return (MessageACK*)self.content;
    }
    return nil;
}
@end






