//
//  MessageImage.h
//  gobelieve
//
//  Created by houxh on 2018/1/25.
//

#import <Foundation/Foundation.h>
#import "MessageContent.h"

@interface MessageImage : MessageContent
- (id)initWithImageURL:(NSString *)imageURL width:(int)width height:(int)height;

@property(nonatomic, readonly) NSString *imageURL;
@property(nonatomic, readonly) NSString *littleImageURL;

@property(nonatomic, readonly) int width;
@property(nonatomic, readonly) int height;

-(MessageImage*)cloneWithURL:(NSString*)url;
@end

typedef MessageImage MessageImageContent;
