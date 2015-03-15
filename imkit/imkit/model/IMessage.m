//
//  IMessage.m
//  im
//
//  Created by houxh on 14-6-28.
//  Copyright (c) 2014年 potato. All rights reserved.
//

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
}*/

@implementation Audio

@end

@implementation MessageContent

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
    audio.duration = [[obj objectForKey:@"duration"] integerValue];
    return audio;
}

-(CLLocationCoordinate2D)location {
    CLLocationCoordinate2D lc;
    NSDictionary *location = [self.dict objectForKey:@"location"];
    lc.latitude = [[location objectForKey:@"latitude"] doubleValue];
    lc.longitude = [[location objectForKey:@"longitude"] doubleValue];
    return lc;
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