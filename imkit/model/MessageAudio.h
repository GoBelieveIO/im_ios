//
//  MessageAudio.h
//  gobelieve
//
//  Created by houxh on 2018/1/25.
//

#import <Foundation/Foundation.h>
#import "MessageContent.h"

@interface MessageAudio : MessageContent
- (id)initWithAudio:(NSString*)url duration:(int)duration;

@property(nonatomic, copy) NSString *url;
@property(nonatomic) int duration;

-(MessageAudio*)cloneWithURL:(NSString*)url;

@end
typedef  MessageAudio MessageAudioContent;


