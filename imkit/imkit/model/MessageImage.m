//
//  MessageImage.m
//  gobelieve
//
//  Created by houxh on 2018/1/25.
//

#import "MessageImage.h"


@implementation MessageImage
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

