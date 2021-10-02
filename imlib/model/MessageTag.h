//
//  MessageTag.h
//  gobelieve
//
//  Created by houxh on 2020/5/13.
//

#import <Foundation/Foundation.h>
#import "MessageContent.h"

NS_ASSUME_NONNULL_BEGIN

@interface MessageTag : MessageContent
- (id)initWithMsgId:(NSString*)msgid addTag:(NSString*)tag;
- (id)initWithMsgId:(NSString*)msgid deleteTag:(NSString*)tag;

@property(nonatomic, readonly) NSString *msgid;//被打标签消息的uuid
@property(nonatomic, readonly) NSString *addTag;
@property(nonatomic, readonly) NSString *deleteTag;
@end

NS_ASSUME_NONNULL_END
