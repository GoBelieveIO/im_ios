//
//  MessageAudio.m
//  gobelieve
//
//  Created by houxh on 2018/1/25.
//

#import "MessageAudio.h"

@implementation MessageAudio
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
