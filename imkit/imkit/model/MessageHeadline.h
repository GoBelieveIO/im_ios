//
//  MessageHeadline.h
//  gobelieve
//
//  Created by houxh on 2018/1/25.
//

#import <Foundation/Foundation.h>
#import "MessageNotification.h"

@interface MessageHeadline : MessageNotificationContent
@property(nonatomic, readonly) NSString *headline;

-(id)initWithHeadline:(NSString*)headline;

@end

typedef MessageHeadline MessageHeadlineContent;
