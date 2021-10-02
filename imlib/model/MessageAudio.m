//
//  MessageAudio.m
//  gobelieve
//
//  Created by houxh on 2018/1/25.
//

#import "MessageAudio.h"

@implementation MessageAudio
- (id)initWithAudio:(NSString*)url duration:(int)duration {
    NSString *uuid = [[NSUUID UUID] UUIDString];
    NSNumber *d = [NSNumber numberWithInteger:duration];
    NSDictionary *dic = @{@"audio":@{@"url":url, @"duration":d}, @"uuid":uuid};
    self = [super initWithDictionary:dic];
    if (self) {

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
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:self.dict];
    NSMutableDictionary *audio = [NSMutableDictionary dictionaryWithDictionary:[dict objectForKey:@"audio"]];
    [audio setObject:url forKey:@"url"];
    [dict setObject:audio forKey:@"audio"];
    MessageAudioContent *newContent = [[MessageAudioContent alloc] initWithDictionary:dict];
    return newContent;
}

-(int)type {
    return MESSAGE_AUDIO;
}
@end
