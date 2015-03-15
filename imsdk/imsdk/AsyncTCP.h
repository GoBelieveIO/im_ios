//
//  AsyncTCP.h
//  im
//
//  Created by houxh on 14-6-26.
//  Copyright (c) 2014年 potato. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AsyncTCP;
typedef void(^ConnectCB)(AsyncTCP *tcp, int err);
typedef void(^ReadCB)(AsyncTCP *tcp, NSData *data, int err);
typedef void(^CloseCB)(AsyncTCP *tcp, int err);

@interface AsyncTCP : NSObject
-(BOOL)connect:(NSString*)host port:(int)port cb:(ConnectCB)cb;
-(void)close;
-(void)write:(NSData*)data;
-(void)startRead:(ReadCB)cb;
@end


