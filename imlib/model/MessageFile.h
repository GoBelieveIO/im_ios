//
//  MessageFile.h
//  gobelieve
//
//  Created by houxh on 2018/5/26.
//

#import <Foundation/Foundation.h>
#import "MessageContent.h"
@interface MessageFile : MessageContent
- (id)initWithFileURL:(NSString *)fileURL name:(NSString*)name size:(int)size;

@property(nonatomic, readonly) NSString *fileURL;
@property(nonatomic, readonly) NSString *fileName;
@property(nonatomic, readonly) int fileSize;

-(MessageFile*)cloneWithURL:(NSString*)url;
@end

typedef MessageFile MessageFileContent;
