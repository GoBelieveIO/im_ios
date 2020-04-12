//
//  MessageVideo.m
//  gobelieve
//
//  Created by houxh on 2018/5/26.
//

#import "MessageVideo.h"


@implementation MessageVideo
- (id)initWithVideoURL:(NSString *)videoURL
             thumbnail:(NSString*)thumbnail
                 width:(int)width
                height:(int)height
              duration:(int)duration
                  size:(int)size
                  uuid:(NSString*)uuid {
    self = [super init];
    if (self) {
        NSDictionary *video = @{@"url":videoURL,
                                @"thumbnail":thumbnail,
                                @"duration":@(duration),
                                @"width":[NSNumber numberWithInt:width],
                                @"height":[NSNumber numberWithInt:height]};

        NSDictionary *dic = @{@"video":video,
                              @"uuid":uuid};
        NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic options:0 error:nil] encoding:NSUTF8StringEncoding];
        self.raw = newStr;
    }
    return self;
}
- (id)initWithVideoURL:(NSString *)videoURL thumbnail:(NSString*)thumbnail width:(int)width height:(int)height duration:(int)duration size:(int)size {
    self = [super init];
    if (self) {
        NSString *uuid = [[NSUUID UUID] UUIDString];
        NSDictionary *video = @{@"url":videoURL,
                                @"thumbnail":thumbnail,
                                @"duration":@(duration),
                                @"width":[NSNumber numberWithInt:width],
                                @"height":[NSNumber numberWithInt:height],
                                @"size":[NSNumber numberWithInt:size]};

        NSDictionary *dic = @{@"video":video,
                              @"uuid":uuid};
        NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic options:0 error:nil] encoding:NSUTF8StringEncoding];
        self.raw = newStr;
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

-(MessageVideo*)cloneWithURL:(NSString*)url thumbnail:(NSString *)thumbnail {
    MessageVideo *newContent = [[MessageVideo alloc] initWithVideoURL:url
                                                            thumbnail:thumbnail
                                                                width:self.width
                                                               height:self.height
                                                             duration:self.duration
                                                                 size:self.size
                                                                 uuid:self.uuid];
    return newContent;
}

-(int)type {
    return MESSAGE_VIDEO;
}
@end


