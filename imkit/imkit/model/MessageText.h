//
//  MessageText.h
//  gobelieve
//
//  Created by houxh on 2018/1/25.
//

#import <Foundation/Foundation.h>
#import "MessageContent.h"

@interface MessageText : MessageContent
- (id)initWithText:(NSString*)text;
- (id)initWithText:(NSString*)text at:(NSArray*)at atNames:(NSArray*)atNames;

@property(nonatomic, readonly) NSString *text;
@property(nonatomic, readonly) NSArray *at;
@property(nonatomic, readonly) NSArray *atNames;

@end


typedef MessageText MessageTextContent;
