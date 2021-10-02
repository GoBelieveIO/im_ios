//
//  MessageVideo.m
//  gobelieve
//
//  Created by houxh on 2018/5/26.
//

#import "MessageVideo.h"


@implementation MessageVideo
- (id)initWithVideoURL:(NSString *)videoURL thumbnail:(NSString*)thumbnail width:(int)width height:(int)height duration:(int)duration size:(int)size {
    NSString *uuid = [[NSUUID UUID] UUIDString];
    NSDictionary *video = @{@"url":videoURL,
                            @"thumbnail":thumbnail,
                            @"duration":@(duration),
                            @"width":[NSNumber numberWithInt:width],
                            @"height":[NSNumber numberWithInt:height],
                            @"size":[NSNumber numberWithInt:size]};

    NSDictionary *dic = @{@"video":video,
                          @"uuid":uuid};
    
    self = [super initWithDictionary:dic];
    if (self) {

    }
    return self;
}

-(NSString*)videoURL {
    NSDictionary *video = [self.dict objectForKey:@"video"];
    return [video objectForKey:@"url"];
}

-(NSString*)thumbnailURL {
    NSDictionary *video = [self.dict objectForKey:@"video"];
    return [video objectForKey:@"thumbnail"];
}

-(int)width {
    NSDictionary *video = [self.dict objectForKey:@"video"];
    return [[video objectForKey:@"width"] intValue];
}

-(int)height {
    NSDictionary *video = [self.dict objectForKey:@"video"];
    return [[video objectForKey:@"height"] intValue];
}

-(int)duration {
    NSDictionary *video = [self.dict objectForKey:@"video"];
    return [[video objectForKey:@"duration"] intValue];
}

-(int)size {
    NSDictionary *video = [self.dict objectForKey:@"video"];
    return [[video objectForKey:@"size"] intValue];
}

-(int)type {
    return MESSAGE_VIDEO;
}


-(MessageVideo*)cloneWithURL:(NSString*)url thumbnail:(NSString *)thumbnail {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:self.dict];
    NSMutableDictionary *video = [NSMutableDictionary dictionaryWithDictionary:[dict objectForKey:@"video"]];
    [video setObject:url forKey:@"url"];
    [video setObject:thumbnail forKey:@"thumbnail"];
    [dict setObject:video forKey:@"video"];
    MessageVideo *newContent = [[MessageVideo alloc] initWithDictionary:dict];
    return newContent;
}

@end


