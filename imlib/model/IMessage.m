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
    "uuid":"消息唯一id"
    "group_id":"点对点消息发到群会话中，用于:已读"
    "reference":"引用的消息id"
    "at":"@的uid数组"
    "at_name":"@的用户名数组，这些用户名包含在text文本字段中"
 
 
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
        "longitude":"经度(浮点数)",
        "address":"地址名称(可选字段)"
    }
    "notification":"群组通知内容"
    "link":{
        "image":"图片url",
        "url":"跳转url",
        "title":"标题"
        "content":"正文"
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
     "classroom": {
         "master_id": "群课堂发起人(整数)",
         "channel_id": "频道id",
         "server_id": "频道对应的服务器id(整数)"
         "mic_mode": "麦克风模式"
     }
     "conference": {
         "master_id": "会议发起人(整数)",
         "channel_id": "频道id",
         "server_id": "频道对应的服务器id(整数)"
     }
     "revoke": {
        "msgid": "被撤回消息的uuid"
     }
     "readed":{
        "msgid": "已读消息的uuid"
     }
     "tag":{
        "msgid": "被打标签消息的uuid",
        "add_tag": "添加的tag",
        "delete_tag": "删除的tag(add_tag和delete_tag只能存在一个)",
     }
}*/


@implementation IMessage
+(MessageContent*)fromRawDict:(NSDictionary *)dict {
    NSDictionary *classes = @{
        @"text":[MessageTextContent class],
        @"image":[MessageImageContent class],
        @"image2":[MessageImageContent class],
        @"location":[MessageLocation class],
        @"audio":[MessageAudioContent class],
        @"video":[MessageVideo class],
        @"file":[MessageFile class],
        @"notification":[MessageGroupNotificationContent class],
        @"link":[MessageLinkContent class],
        @"timestamp":[MessageHeadlineContent class],
        @"headline":[MessageHeadline class],
        @"voip":[MessageVOIPContent class],
        @"group_voip":[MessageGroupVOIPContent class],
        @"secret":[MessageSecret class],
        @"revoke":[MessageRevoke class],
        @"ack":[MessageACK class],
        @"classroom":[MessageClassroom class],
        @"conference":[MessageConference class],
        @"readed":[MessageReaded class],
        @"p2p_session":[MessageP2PSession class],
        @"tag":[MessageTag class],
    };

    Class cls = nil;
    NSArray *keys = [classes allKeys];
    for (NSInteger i = 0; i < keys.count; i++) {
        NSString *key = [keys objectAtIndex:i];
        if ([dict objectForKey:key]) {
            cls = [classes objectForKey:key];
            break;
        }
    }
    if (!cls) {
        cls = [MessageContent class];
    }
    return [[cls alloc] initWithDictionary:dict];

}
+(MessageContent*)fromRaw:(NSString *)rawContent {
    const char *utf8 = [rawContent UTF8String];
    if (utf8 == nil) return nil;
    NSData *data = [NSData dataWithBytes:utf8 length:strlen(utf8)];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
    if (dict) {
        return [self fromRawDict:dict];
    } else {
        return [self fromRawDict:@{}];
    }
}

-(id)init {
    self = [super init];
    if (self) {
        self.tags = [NSArray array];
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    IMessage *m = [[[self class] allocWithZone:zone] init];
    m.msgLocalID = self.msgLocalID;
    m.secret = self.secret;
    m.flags = self.flags;
    m.sender = self.sender;
    m.receiver = self.receiver;
    m.timestamp = self.timestamp;
    
    m.reference = self.reference;
    m.referenceCount = self.referenceCount;
    m.receiverCount = self.receiverCount;
    m.readerCount = self.readerCount;
    m.groupId = self.groupId;
    
    m.content = self.content;
    m.tags = self.tags;
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

-(BOOL)isListened {
    return self.flags&MESSAGE_FLAG_LISTENED;
}

-(BOOL)isReaded {
    return self.flags&MESSAGE_FLAG_READED;
}

-(BOOL)isIncomming {
    return !self.isOutgoing;
}

-(void)setContent:(MessageContent *)content {
    _content = content;
}

-(void)setRawContent:(NSString *)rawContent {
    _content = [[self class] fromRaw:rawContent];
}

-(int)type {
    return self.content.type;
}

-(NSString*)uuid {
    if (_uuid.length > 0) {
        return _uuid;
    } else {
        return self.content.uuid;
    }
}

-(NSString*)reference {
    if (_reference.length > 0) {
        return _reference;
    } else {
        return self.content.reference;
    }
}

-(int64_t)groupId {
    if (_groupId > 0) {
        return _groupId;
    } else {
        return self.content.groupId;
    }
}

-(NSString*)rawContent {
    return self.content.raw;
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

-(MessageClassroom*)classroomContent {
    if (self.type == MESSAGE_CLASSROOM) {
        return (MessageClassroom*)self.content;
    }
    return nil;
}

-(MessageConference*)conferenceContent {
    if (self.type == MESSAGE_CONFERENCE) {
        return (MessageConference*)self.content;
    }
    return nil;
}

-(MessageReaded*)readedContent {
    if (self.type == MESSAGE_READED) {
        return (MessageReaded*)self.content;
    }
    return nil;
}

-(MessageTag*)tagContent {
    if (self.type == MESSAGE_TAG) {
        return (MessageTag*)self.content;
    }
    return nil;
}

-(void)generateRaw {
    if (_uuid.length > 0) {
        self.content.uuid = _uuid;
    }
    if (_reference.length > 0) {
        self.content.reference = _reference;
    }
    if (self.groupId > 0) {
        self.content.groupId = _groupId;
    }
    
    [self.content generateRaw];
}

-(void)addTag:(NSString *)tag {
    if ([self.tags containsObject:tag]) {
        return;
    }
    NSMutableArray *arr = [NSMutableArray arrayWithArray:self.tags];
    [arr addObject:tag];
    self.tags = arr;
}

-(void)removeTag:(NSString *)tag {
    if (![self.tags containsObject:tag]) {
        return;
    }
    NSMutableArray *arr = [NSMutableArray arrayWithArray:self.tags];
    [arr removeObject:tag];
    self.tags = arr;
}
@end






