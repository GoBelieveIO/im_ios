//
//  MessageLink.m
//  gobelieve
//
//  Created by houxh on 2018/1/25.
//

#import "MessageLink.h"

@implementation MessageLink
- (NSString*)imageURL {
    return [[self.dict objectForKey:@"link"] objectForKey:@"image"];
}

- (NSString*)url {
    return [[self.dict objectForKey:@"link"] objectForKey:@"url"];
}

- (NSString*)title {
    return [[self.dict objectForKey:@"link"] objectForKey:@"title"];
}

- (NSString*)content {
    return [[self.dict objectForKey:@"link"] objectForKey:@"content"];
}

-(int)type {
    return MESSAGE_LINK;
}
@end
