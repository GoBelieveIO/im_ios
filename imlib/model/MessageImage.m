//
//  MessageImage.m
//  gobelieve
//
//  Created by houxh on 2018/1/25.
//

#import "MessageImage.h"


@implementation MessageImage
- (id)initWithImageURL:(NSString *)imageURL width:(int)width height:(int)height {
    NSString *uuid = [[NSUUID UUID] UUIDString];
    NSDictionary *image = @{@"url":imageURL,
                            @"width":[NSNumber numberWithInt:width],
                            @"height":[NSNumber numberWithInt:height]};

    NSDictionary *dic = @{@"image2":image,
                          @"uuid":uuid};
    self = [super initWithDictionary:dic];
    if (self) {

    
    }
    return self;
}
-(NSString*)imageURL {
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
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:self.dict];
    NSDictionary *image = @{@"url":url,
                            @"width":@(self.width),
                            @"height":@(self.height)};
    [dict setObject:image forKey:@"image2"];
    MessageImageContent *newContent = [[MessageImageContent alloc] initWithDictionary:dict];
    return newContent;
}

-(int)type {
    return MESSAGE_IMAGE;
}
@end

