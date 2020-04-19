//
//  MessageClassroom.h
//  gobelieve
//
//  Created by houxh on 2020/3/3.
//

#import <Foundation/Foundation.h>
#import "MessageContent.h"

NS_ASSUME_NONNULL_BEGIN

@interface MessageClassroom : MessageContent
@property(nonatomic, assign) int64_t masterID;
@property(nonatomic, assign) int64_t serverID;
@property(nonatomic, copy) NSString *channelID;
@property(nonatomic, copy) NSString *micMode;
@end

NS_ASSUME_NONNULL_END
