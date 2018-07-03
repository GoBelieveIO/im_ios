//
//  MessageVOIP.h
//  gobelieve
//
//  Created by houxh on 2018/1/25.
//

#import <Foundation/Foundation.h>
#import "MessageContent.h"

#define VOIP_FLAG_CANCELED 1   //取消
#define VOIP_FLAG_REFUSED 2
#define VOIP_FLAG_ACCEPTED 3
#define VOIP_FLAG_UNRECEIVED 4  //未接听

@interface MessageVOIP : MessageContent
@property(nonatomic) int flag;
@property(nonatomic) int duration;//通话时长
@property(nonatomic) BOOL videoEnabled;

-(id)initWithFlag:(int)flag duration:(int)duration videoEnabled:(BOOL)videoEnabled;
@end
typedef MessageVOIP MessageVOIPContent;
