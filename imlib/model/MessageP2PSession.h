//
//  MessageP2PSession.h
//  gobelieve
//
//  Created by houxh on 2018/1/25.
//

#import <Foundation/Foundation.h>
#import "MessageContent.h"

@interface MessageP2PSession : MessageContent
@property(nonatomic, copy) NSString *channelID;
@property(nonatomic, copy) NSString *deviceID;

-(id)initWithDeviceID:(NSString*)deviceID channelID:(NSString*)channelID;

@end
