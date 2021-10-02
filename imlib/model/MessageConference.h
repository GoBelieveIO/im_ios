//
//  MessageConference.h
//  gobelieve
//
//  Created by houxh on 2020/8/2.
//

#import <Foundation/Foundation.h>
#import "MessageContent.h"

NS_ASSUME_NONNULL_BEGIN

@interface MessageConference : MessageContent;
@property(nonatomic, assign) int64_t masterID;
@property(nonatomic, assign) int64_t serverID;
@property(nonatomic, copy) NSString *channelID;
@property(nonatomic, copy) NSString *micMode;
@end

NS_ASSUME_NONNULL_END
