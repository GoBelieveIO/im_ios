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

@implementation Audio

@end

@implementation GroupNotification

-(id)initWithRaw:(NSString*)raw {
    self = [super init];
    if (self) {
        self.raw = raw;
        
        const char *utf8 = [raw UTF8String];
        if (utf8 == nil) {
            utf8 = "";
        }
        
        NSData *data = [NSData dataWithBytes:utf8 length:strlen(utf8)];
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        
        if ([dict objectForKey:@"create"]) {
            self.type = NOTIFICATION_GROUP_CREATED;
            NSDictionary *d = [dict objectForKey:@"create"];
            self.master = [[d objectForKey:@"master"] longLongValue];
            self.groupName = [d objectForKey:@"name"];
            self.groupID = [[d objectForKey:@"group_id"] longLongValue];
            self.members = [d objectForKey:@"members"];
        } else if ([dict objectForKey:@"disband"]) {
            self.type = NOTIFICATION_GROUP_DISBANDED;
            NSDictionary *obj = [dict objectForKey:@"disband"];
            self.groupID = [[obj objectForKey:@"group_id"] longLongValue];
        } else if ([dict objectForKey:@"quit_group"]) {
            self.type = NOTIFICATION_GROUP_MEMBER_LEAVED;
            NSDictionary *obj = [dict objectForKey:@"quit_group"];
            self.groupID = [[obj objectForKey:@"group_id"] longLongValue];
            self.member =[[obj objectForKey:@"member_id"] longLongValue];
        } else if ([dict objectForKey:@"add_member"]) {
            self.type = NOTIFICATION_GROUP_MEMBER_ADDED;
            NSDictionary *obj = [dict objectForKey:@"add_member"];
            self.groupID = [[obj objectForKey:@"group_id"] longLongValue];
            self.member =[[obj objectForKey:@"member_id"] longLongValue];
        }
    }
    return self;
}

@end
@implementation MessageContent
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

- (id)initWithImageURL:(NSString*)imageURL {
    self = [super init];
    if (self) {
        NSDictionary *dic = @{@"image":imageURL};
        NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic options:0 error:nil] encoding:NSUTF8StringEncoding];
        self.raw = newStr;
    }
    return self;
}

- (id)initWithAudio:(Audio*)audio {
    self = [super init];
    if (self) {
        NSNumber *d = [NSNumber numberWithInteger:audio.duration];
        NSDictionary *dic = @{@"audio":@{@"url":audio.url, @"duration":d}};
        NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic options:0 error:nil] encoding:NSUTF8StringEncoding];
        self.raw =  newStr;
    }
    return self;
}

- (id)initWithNotification:(GroupNotification*)notification {
    self = [super init];
    if (self) {
        NSDictionary *dic = @{@"notification":notification.raw};
        NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic options:0 error:nil] encoding:NSUTF8StringEncoding];
        self.raw =  newStr;
    }
    return self;
}

- (id)initWithRaw:(NSString*)raw {
    self = [super init];
    if (self) {
        self.raw = raw;
    }
    return self;
}

-(NSString*)text {
    return [self.dict objectForKey:@"text"];
}

-(NSString*)imageURL {
    return[self.dict objectForKey:@"image"];
}

-(NSString*) littleImageURL{
    NSAssert(self.type==MESSAGE_IMAGE, @"littleImageURL:类型错误");
    NSString *littleUrl = [NSString stringWithFormat:@"%@@128w_128h_0c", [self imageURL]];
    return littleUrl;
}

-(Audio*)audio {
    NSDictionary *obj = [self.dict objectForKey:@"audio"];
    Audio *audio = [[Audio alloc] init];
    audio.url = [obj objectForKey:@"url"];
    audio.duration = [[obj objectForKey:@"duration"] intValue];
    return audio;
}

-(CLLocationCoordinate2D)location {
    CLLocationCoordinate2D lc;
    NSDictionary *location = [self.dict objectForKey:@"location"];
    lc.latitude = [[location objectForKey:@"latitude"] doubleValue];
    lc.longitude = [[location objectForKey:@"longitude"] doubleValue];
    return lc;
}

-(GroupNotification*)notification {
    return [[GroupNotification alloc] initWithRaw:[self.dict objectForKey:@"notification"]];
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
    } else {
        self.type = MESSAGE_UNKNOWN;
    }
}

-(NSString*)raw {
    return self._raw;
}

@end

@implementation IMessage

-(BOOL)isACK {
    return self.flags&MESSAGE_FLAG_ACK;
}

-(BOOL)isPeerACK {
    return self.flags&MESSAGE_FLAG_PEER_ACK;
}

-(BOOL)isFailure {
    return self.flags&MESSAGE_FLAG_FAILURE;
}

-(BOOL)isListened{
    return self.flags&MESSAGE_FLAG_LISTENED;
}

@end

@implementation Conversation


@end
