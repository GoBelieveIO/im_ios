/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import <Foundation/Foundation.h>

@class AsyncTCP;
typedef void(^ConnectCB)(AsyncTCP *tcp, int err);
typedef void(^ReadCB)(AsyncTCP *tcp, NSData *data, int err);
typedef void(^CloseCB)(AsyncTCP *tcp, int err);

@interface AsyncTCP : NSObject
-(id)init;
-(id)initWithQueue:(dispatch_queue_t)queue;
-(BOOL)connect:(NSString*)host port:(int)port cb:(ConnectCB)cb;
-(BOOL)connect:(struct sockaddr*)addr cb:(ConnectCB)cb;
-(void)close;
-(void)write:(NSData*)data;
-(void)flush;
-(void)startRead:(ReadCB)cb;

//protected
- (BOOL)synthesizeIPv6:(NSString*)host port:(int)port addr:(struct sockaddr*)addr addrinfo:(struct addrinfo*)info;
@end


