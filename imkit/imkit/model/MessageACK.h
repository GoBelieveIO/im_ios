//
//  MessageACK.h
//  gobelieve
//
//  Created by houxh on 2019/7/25.
//

#import <Foundation/Foundation.h>
#import "MessageNotification.h"


@interface MessageACK : MessageNotificationContent
-(id)initWithError:(int)err;

@property(nonatomic, readonly) int error;
@end

typedef MessageACK MessageACKContent;

