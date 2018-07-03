//
//  MessageVideo.h
//  gobelieve
//
//  Created by houxh on 2018/5/26.
//

#import <Foundation/Foundation.h>
#import "MessageContent.h"

@interface MessageVideo : MessageContent
- (id)initWithVideoURL:(NSString *)imageURL
             thumbnail:(NSString*)thumbnail
                 width:(int)width
                height:(int)height
              duration:(int)duration
                  size:(int)size;

@property(nonatomic, readonly) NSString *videoURL;
@property(nonatomic, readonly) NSString *thumbnailURL;

@property(nonatomic, readonly) int width;
@property(nonatomic, readonly) int height;
@property(nonatomic, readonly) int duration;
@property(nonatomic, readonly) int size;//文件大小

-(MessageVideo*)cloneWithURL:(NSString*)url thumbnail:(NSString*)thumbnail;
@end

typedef MessageVideo MessageVideoContent;
