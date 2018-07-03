//
//  MessageLink.h
//  gobelieve
//
//  Created by houxh on 2018/1/25.
//

#import <Foundation/Foundation.h>
#import "MessageContent.h"

@interface MessageLink : MessageContent
@property(nonatomic, readonly) NSString *imageURL;
@property(nonatomic, readonly) NSString *url;
@property(nonatomic, readonly) NSString *title;
@property(nonatomic, readonly) NSString *content;
@end
typedef MessageLink MessageLinkContent;

