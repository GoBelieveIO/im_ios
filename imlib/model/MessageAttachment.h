//
//  MessageAttachment.h
//  gobelieve
//
//  Created by houxh on 2018/1/25.
//

#import <Foundation/Foundation.h>
#import "MessageContent.h"

@interface MessageAttachment : MessageContent

@property(nonatomic) int msgLocalID;

@property(nonatomic) NSString *address;
@property(nonatomic) NSString *url;

//location
- (id)initWithAttachment:(int64_t)msgLocalID address:(NSString*)address;

//image/audio
- (id)initWithAttachment:(int64_t)msgLocalID url:(NSString*)url;

@end
typedef MessageAttachment MessageAttachmentContent;
