/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "IMessage.h"


@interface MessageContent()
@property(nonatomic)NSDictionary *dict;
@property(nonatomic, copy)NSString *_raw;
@end

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
 
}*/

@interface MessageContent()

@end

@implementation MessageContent

- (id)initWithRaw:(NSString*)raw {
    self = [super init];
    if (self) {
        self.raw = raw;
    }
    return self;
}

-(void)setRaw:(NSString *)raw {
    self._raw = raw;
    const char *utf8 = [raw UTF8String];
    if (utf8 == nil) return;
    NSData *data = [NSData dataWithBytes:utf8 length:strlen(utf8)];
    self.dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
}

-(NSString*)raw {
    return self._raw;
}

-(NSString*)uuid {
    return [self.dict objectForKey:@"uuid"];
}

-(int)type {
    return MESSAGE_UNKNOWN;
}

@end


@implementation MessageTextContent

-(id)initWithText:(NSString*)text {
    self = [super init];
    if (self) {
        NSString *uuid = [[NSUUID UUID] UUIDString];
        NSDictionary *dic = @{@"text":text, @"uuid":uuid};
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:0 error:nil];
        NSString* newStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        self.raw =  newStr;
    }
    return self;
}

-(NSString*)text {
    return [self.dict objectForKey:@"text"];
}

-(int)type {
    return MESSAGE_TEXT;
}
@end


@implementation MessageAudioContent
- (id)initWithAudio:(NSString*)url duration:(int)duration uuid:(NSString*)uuid {
    self = [super init];
    if (self) {
        NSNumber *d = [NSNumber numberWithInteger:duration];
        NSDictionary *dic = @{@"audio":@{@"url":url, @"duration":d}, @"uuid":uuid};
        NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic options:0 error:nil] encoding:NSUTF8StringEncoding];
        self.raw =  newStr;
    }
    return self;
}

- (id)initWithAudio:(NSString*)url duration:(int)duration {
    self = [super init];
    if (self) {
        NSString *uuid = [[NSUUID UUID] UUIDString];
        NSNumber *d = [NSNumber numberWithInteger:duration];
        NSDictionary *dic = @{@"audio":@{@"url":url, @"duration":d}, @"uuid":uuid};
        NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic options:0 error:nil] encoding:NSUTF8StringEncoding];
        self.raw =  newStr;
    }
    return self;
}

- (NSString*)url {
    return [[self.dict objectForKey:@"audio"] objectForKey:@"url"];
}

- (int)duration {
    return [[[self.dict objectForKey:@"audio"] objectForKey:@"duration"] intValue];
}

-(MessageAudioContent*)cloneWithURL:(NSString*)url {
    MessageAudioContent *newContent = [[MessageAudioContent alloc] initWithAudio:url duration:self.duration uuid:self.uuid];
    return newContent;
}

-(int)type {
    return MESSAGE_AUDIO;
}
@end


@implementation MessageImageContent
- (id)initWithImageURL:(NSString *)imageURL width:(int)width height:(int)height uuid:(NSString*)uuid {
    self = [super init];
    if (self) {
        NSDictionary *image = @{@"url":imageURL,
                                @"width":[NSNumber numberWithInt:width],
                                @"height":[NSNumber numberWithInt:height]};
        
        //保留key:image是为了兼容性
        NSDictionary *dic = @{@"image2":image,
                              @"image":imageURL,
                              @"uuid":uuid};
        NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic options:0 error:nil] encoding:NSUTF8StringEncoding];
        self.raw = newStr;
    }
    return self;
}
- (id)initWithImageURL:(NSString *)imageURL width:(int)width height:(int)height {
    self = [super init];
    if (self) {
        NSString *uuid = [[NSUUID UUID] UUIDString];
        NSDictionary *image = @{@"url":imageURL,
                                @"width":[NSNumber numberWithInt:width],
                                @"height":[NSNumber numberWithInt:height]};
        
        //保留key:image是为了兼容性
        NSDictionary *dic = @{@"image2":image,
                              @"image":imageURL,
                              @"uuid":uuid};
        NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic options:0 error:nil] encoding:NSUTF8StringEncoding];
        self.raw = newStr;
    }
    return self;
}
-(NSString*)imageURL {
    NSString *url = [self.dict objectForKey:@"image"];
    if (url != nil) {
        return url;
    }
    
    NSDictionary *image = [self.dict objectForKey:@"image2"];
    return [image objectForKey:@"url"];
}

//在原图URL后面添加"@{width}w_{heigth}h_{1|0}c", 支持128x128, 256x256
-(NSString*) littleImageURL{
    NSString *littleUrl = [NSString stringWithFormat:@"%@@256w_256h_0c", [self imageURL]];
    return littleUrl;
}

-(int)width {
    NSDictionary *image = [self.dict objectForKey:@"image2"];
    return [[image objectForKey:@"width"] intValue];
}

-(int)height {
    NSDictionary *image = [self.dict objectForKey:@"image2"];
    return [[image objectForKey:@"height"] intValue];
}

-(MessageImageContent*)cloneWithURL:(NSString*)url {
    MessageImageContent *newContent = [[MessageImageContent alloc] initWithImageURL:url width:self.width height:self.height uuid:self.uuid];
    return newContent;
}

-(int)type {
    return MESSAGE_IMAGE;
}
@end


@implementation MessageLocationContent

- (id)initWithLocation:(CLLocationCoordinate2D)location {
    self = [super init];
    if (self) {
        NSString *uuid = [[NSUUID UUID] UUIDString];
        NSDictionary *loc = @{@"latitude":[NSNumber numberWithDouble:location.latitude],
                              @"longitude":[NSNumber numberWithDouble:location.longitude]};
        NSDictionary *dic = @{@"location":loc, @"uuid":uuid};
        NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic options:0 error:nil] encoding:NSUTF8StringEncoding];
        self.raw =  newStr;
    }
    return self;
}


-(CLLocationCoordinate2D)location {
    CLLocationCoordinate2D lc;
    NSDictionary *location = [self.dict objectForKey:@"location"];
    lc.latitude = [[location objectForKey:@"latitude"] doubleValue];
    lc.longitude = [[location objectForKey:@"longitude"] doubleValue];
    return lc;
}

-(NSString*)snapshotURL {
    CLLocationCoordinate2D location = self.location;
    NSString *s = [NSString stringWithFormat:@"%f-%f", location.latitude, location.longitude];
    NSString *t = [NSString stringWithFormat:@"http://localhost/snapshot/%@.png", s];
    return t;
}

-(void)setAddress:(NSString *)address {
    _address = [address copy];

    CLLocationCoordinate2D location = self.location;
    NSDictionary *loc = @{@"latitude":[NSNumber numberWithDouble:location.latitude],
                          @"longitude":[NSNumber numberWithDouble:location.longitude],
                          @"address":address};
    NSDictionary *dic = @{@"location":loc, @"uuid":self.uuid};
    NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic options:0 error:nil] encoding:NSUTF8StringEncoding];
    self.raw = newStr;
}

-(int)type {
    return MESSAGE_LOCATION;
}
@end

@implementation MessageLinkContent
- (NSString*)imageURL {
    return [[self.dict objectForKey:@"link"] objectForKey:@"image"];
}

- (NSString*)url {
    return [[self.dict objectForKey:@"link"] objectForKey:@"url"];
}

- (NSString*)title {
    return [[self.dict objectForKey:@"link"] objectForKey:@"title"];
}

- (NSString*)content {
    return [[self.dict objectForKey:@"link"] objectForKey:@"content"];
}

-(int)type {
    return MESSAGE_LINK;
}
@end

@implementation MessageNotificationContent

@end

@implementation MessageGroupNotificationContent

- (id)initWithRaw:(NSString *)raw {
    self = [super initWithRaw:raw];
    if (self) {
        NSString *notification = [self.dict objectForKey:@"notification"];
        self.rawNotification = notification;
    }
    return self;
}

- (id)initWithNotification:(NSString*)notification {
    self = [super init];
    if (self) {
        NSDictionary *dic = @{@"notification":notification};
        NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic options:0 error:nil] encoding:NSUTF8StringEncoding];
        self.raw =  newStr;
        
        self.rawNotification = notification;
        

    }
    return self;
}

- (void)setRawNotification:(NSString *)rawNotification {
    _rawNotification = [rawNotification copy];
    const char *utf8 = [rawNotification UTF8String];
    if (utf8 == nil) {
        utf8 = "";
    }
    
    NSData *data = [NSData dataWithBytes:utf8 length:strlen(utf8)];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
    
    if ([dict objectForKey:@"create"]) {
        self.notificationType = NOTIFICATION_GROUP_CREATED;
        NSDictionary *d = [dict objectForKey:@"create"];
        self.master = [[d objectForKey:@"master"] longLongValue];
        self.groupName = [d objectForKey:@"name"];
        self.groupID = [[d objectForKey:@"group_id"] longLongValue];
        self.members = [d objectForKey:@"members"];
        self.timestamp = [[d objectForKey:@"timestamp"] intValue];
    } else if ([dict objectForKey:@"disband"]) {
        self.notificationType = NOTIFICATION_GROUP_DISBANDED;
        NSDictionary *obj = [dict objectForKey:@"disband"];
        self.groupID = [[obj objectForKey:@"group_id"] longLongValue];
        self.timestamp = [[obj objectForKey:@"timestamp"] intValue];
    } else if ([dict objectForKey:@"quit_group"]) {
        self.notificationType = NOTIFICATION_GROUP_MEMBER_LEAVED;
        NSDictionary *obj = [dict objectForKey:@"quit_group"];
        self.groupID = [[obj objectForKey:@"group_id"] longLongValue];
        self.member =[[obj objectForKey:@"member_id"] longLongValue];
        self.timestamp = [[obj objectForKey:@"timestamp"] intValue];
    } else if ([dict objectForKey:@"add_member"]) {
        self.notificationType = NOTIFICATION_GROUP_MEMBER_ADDED;
        NSDictionary *obj = [dict objectForKey:@"add_member"];
        self.groupID = [[obj objectForKey:@"group_id"] longLongValue];
        self.member =[[obj objectForKey:@"member_id"] longLongValue];
        self.timestamp = [[obj objectForKey:@"timestamp"] intValue];
    } else if ([dict objectForKey:@"update_name"]) {
        self.notificationType = NOTIFICATION_GROUP_NAME_UPDATED;
        NSDictionary *obj = [dict objectForKey:@"update_name"];
        self.groupID = [[obj objectForKey:@"group_id"] longLongValue];
        self.timestamp = [[obj objectForKey:@"timestamp"] intValue];
        self.groupName = [obj objectForKey:@"name"];
    } else if ([dict objectForKey:@"update_notice"]) {
        self.notificationType = NOTIFICATION_GROUP_NOTICE_UPDATED;
        NSDictionary *obj = [dict objectForKey:@"update_notice"];
        self.groupID = [[obj objectForKey:@"group_id"] longLongValue];
        self.timestamp = [[obj objectForKey:@"timestamp"] intValue];
        self.notice = [obj objectForKey:@"notice"];
    }
}

-(int)type {
    return MESSAGE_GROUP_NOTIFICATION;
}
@end

@implementation MessageAttachmentContent

- (id)initWithAttachment:(int)msgLocalID address:(NSString*)address {
    self = [super init];
    if (self) {
        NSDictionary *attachment = @{@"address":address,
                                     @"msg_id":[NSNumber numberWithInt:msgLocalID]};
        NSDictionary *dic = @{@"attachment":attachment};
        NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic options:0 error:nil] encoding:NSUTF8StringEncoding];
        self.raw =  newStr;
    }
    return self;
    
}

- (id)initWithAttachment:(int)msgLocalID url:(NSString*)url {
    self = [super init];
    if (self) {
        NSDictionary *attachment = @{@"url":url,
                                     @"msg_id":[NSNumber numberWithInt:msgLocalID]};
        NSDictionary *dic = @{@"attachment":attachment};
        NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic options:0 error:nil] encoding:NSUTF8StringEncoding];
        self.raw =  newStr;
    }
    return self;
}

- (int)msgLocalID {
    return [[[self.dict objectForKey:@"attachment"] objectForKey:@"msg_id"] intValue];
}

- (NSString*)address {
    return [[self.dict objectForKey:@"attachment"] objectForKey:@"address"];
}

- (NSString*)url {
    return [[self.dict objectForKey:@"attachment"] objectForKey:@"url"];
}

-(int)type {
    return MESSAGE_ATTACHMENT;
}
@end

@implementation MessageTimeBaseContent

-(id)initWithTimestamp:(int)ts {
    self = [super init];
    if (self) {
        NSDictionary *dic = @{@"timestamp":[NSNumber numberWithInt:ts]};
        NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic options:0 error:nil] encoding:NSUTF8StringEncoding];
        self.raw =  newStr;
    }
    return self;
}

-(int)timestamp {
    return [[self.dict objectForKey:@"timestamp"] intValue];
}

-(int)type {
    return MESSAGE_TIME_BASE;
}
@end

@implementation MessageVOIPContent
-(id)initWithFlag:(int)flag duration:(int)duration videoEnabled:(BOOL)videoEnabled {
    self = [super init];
    if (self) {
        NSDictionary *dic = @{@"voip":@{@"flag":@(flag), @"duration":@(duration), @"video_enabled":@(videoEnabled)}};
        NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic options:0 error:nil] encoding:NSUTF8StringEncoding];
        self.raw =  newStr;
    }
    return self;
}

-(int)type {
    return MESSAGE_VOIP;
}

-(int)flag {
     return [[[self.dict objectForKey:@"voip"] objectForKey:@"flag"] intValue];
}

-(int)duration {
    return [[[self.dict objectForKey:@"voip"] objectForKey:@"duration"] intValue];
}

-(BOOL)videoEnabled {
    return [[[self.dict objectForKey:@"voip"] objectForKey:@"video_enabled"] boolValue];
}

@end

@implementation MessageGroupVOIPContent
-(id)initWithInitiator:(int64_t)initiator finished:(BOOL)finished {
    self = [super init];
    if (self) {
        NSDictionary *dic = @{@"group_voip":@{@"initiator":@(initiator), @"finished":@(finished)}};
        NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic options:0 error:nil] encoding:NSUTF8StringEncoding];
        self.raw =  newStr;
    }
    return self;
}

-(int)type {
    return MESSAGE_GROUP_VOIP;
}

-(int64_t)initiator {
    return [[[self.dict objectForKey:@"group_voip"] objectForKey:@"initiator"] longLongValue];
}

-(BOOL)finished {
    return [[[self.dict objectForKey:@"group_voip"] objectForKey:@"finished"] boolValue];
}

@end

@implementation MessageHeadlineContent
-(id)initWithHeadline:(NSString*)headline {
    self = [super init];
    if (self) {
        NSDictionary *dic = @{@"headline":headline};
        NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic options:0 error:nil] encoding:NSUTF8StringEncoding];
        self.raw =  newStr;
    }
    return self;
}

-(NSString*)notificationDesc {
    return [self headline];
}

-(NSString*)headline {
    return [self.dict objectForKey:@"headline"];
}

-(int)type {
    return MESSAGE_HEADLINE;
}
@end


@interface IMessage()

@end

@implementation IMessage

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
    
    const char *utf8 = [rawContent UTF8String];
    if (utf8 == nil) return;
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
    }
    
    _content = content;
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
        self.type == MESSAGE_GROUP_VOIP) {
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

@end


@implementation ICustomerMessage
-(int64_t)sender {
    if (self.isSupport) {
        return self.storeID;
    } else {
        return self.customerID;
    }
}

-(int64_t)receiver {
    if (self.isSupport) {
        return self.customerID;
    } else {
        return self.storeID;
    }
}
@end


@implementation IUser

@end


