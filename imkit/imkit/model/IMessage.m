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
    "audio": {
        "url":"audio url",
        "duration":"时长(整形)"
    }
    "location":{
        "latitude":"纬度(浮点数)",
        "latitude":"经度(浮点数)"
    }
    "notification":"通知内容"
 
}*/


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
    
    if ([self.dict objectForKey:@"text"] != nil) {
        self.type = MESSAGE_TEXT;
    } else if ([self.dict objectForKey:@"image"] != nil) {
        self.type = MESSAGE_IMAGE;
    } else if ([self.dict objectForKey:@"audio"] != nil) {
        self.type = MESSAGE_AUDIO;
    } else if ([self.dict objectForKey:@"location"] != nil) {
        self.type = MESSAGE_LOCATION;
    } else if ([self.dict objectForKey:@"notification"] != nil) {
        self.type = MESSAGE_GROUP_NOTIFICATION;
    } else if ([self.dict objectForKey:@"attachment"] != nil) {
        self.type = MESSAGE_ATTACHMENT;
    } else {
        self.type = MESSAGE_UNKNOWN;
    }
}

-(NSString*)raw {
    return self._raw;
}

@end


@implementation MessageTextContent

-(id)initWithText:(NSString*)text {
    self = [super init];
    if (self) {
        NSDictionary *dic = @{@"text":text};
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:0 error:nil];
        NSString* newStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        self.raw =  newStr;
    }
    return self;
}

-(NSString*)text {
    return [self.dict objectForKey:@"text"];
}

@end


@implementation MessageAudioContent

- (id)initWithAudio:(NSString*)url duration:(int)duration {
    self = [super init];
    if (self) {
        NSNumber *d = [NSNumber numberWithInteger:duration];
        NSDictionary *dic = @{@"audio":@{@"url":url, @"duration":d}};
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

@end


@implementation MessageImageContent
- (id)initWithImageURL:(NSString*)imageURL {
    self = [super init];
    if (self) {
        NSDictionary *dic = @{@"image":imageURL};
        NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic options:0 error:nil] encoding:NSUTF8StringEncoding];
        self.raw = newStr;
    }
    return self;
}

-(NSString*)imageURL {
    return[self.dict objectForKey:@"image"];
}

-(NSString*) littleImageURL{
    NSAssert(self.type==MESSAGE_IMAGE, @"littleImageURL:类型错误");
    NSString *littleUrl = [NSString stringWithFormat:@"%@@128w_128h_0c", [self imageURL]];
    return littleUrl;
}

@end


@implementation MessageLocationContent

- (id)initWithLocation:(CLLocationCoordinate2D)location {
    self = [super init];
    if (self) {
        NSDictionary *loc = @{@"latitude":[NSNumber numberWithDouble:location.latitude],
                              @"longitude":[NSNumber numberWithDouble:location.longitude]};
        NSDictionary *dic = @{@"location":loc};
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


@end

@implementation MessageNotificationContent

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
    }
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

- (int)msgLocalID {
    return [[[self.dict objectForKey:@"attachment"] objectForKey:@"msg_id"] intValue];
}

- (NSString*)address {
    return [[self.dict objectForKey:@"attachment"] objectForKey:@"address"];
}

@end

@implementation IUser

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

-(void)setRawContent:(NSString *)rawContent {
    _rawContent = [rawContent copy];
    
    const char *utf8 = [rawContent UTF8String];
    if (utf8 == nil) return;
    NSData *data = [NSData dataWithBytes:utf8 length:strlen(utf8)];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
    
    MessageContent *content = nil;
    if ([dict objectForKey:@"text"] != nil) {
        _type = MESSAGE_TEXT;
        content = [[MessageTextContent alloc] initWithRaw:rawContent];
    } else if ([dict objectForKey:@"image"] != nil) {
        _type = MESSAGE_IMAGE;
        content = [[MessageImageContent alloc] initWithRaw:rawContent];
    } else if ([dict objectForKey:@"audio"] != nil) {
        _type = MESSAGE_AUDIO;
        content = [[MessageAudioContent alloc] initWithRaw:rawContent];
    } else if ([dict objectForKey:@"location"] != nil) {
        _type = MESSAGE_LOCATION;
        content = [[MessageLocationContent alloc] initWithRaw:rawContent];
    } else if ([dict objectForKey:@"notification"] != nil) {
        _type = MESSAGE_GROUP_NOTIFICATION;
        content = [[MessageNotificationContent alloc] initWithRaw:rawContent];
    } else if ([dict objectForKey:@"attachment"] != nil) {
        _type = MESSAGE_ATTACHMENT;
        content = [[MessageAttachmentContent alloc] initWithRaw:rawContent];
    } else {
        _type = MESSAGE_UNKNOWN;
    }
    
    _content = content;
}
@end

@implementation IGroup

@end

@implementation Conversation


@end
