/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

//
//  Model.h
//  im
//
//  Created by houxh on 14-6-28.
//  Copyright (c) 2014年 potato. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMessage.h"


#define HEADER_SIZE 32
#define IMMAGIC 0x494d494d
#define IMVERSION (1<<16) //1.0


@class ReverseFile;

@interface FileMessageDB : NSObject

+(BOOL)writeHeader:(int)fd;
+(BOOL)checkHeader:(int)fd;
+(BOOL)writeMessage:(IMessage*)msg fd:(int)fd;
+(BOOL)insertIMessage:(IMessage*)msg path:(NSString*)path;
+(BOOL)addFlag:(int)msgLocalID path:(NSString*)path flag:(int)flag;
+(BOOL)eraseFlag:(int)msgLocalID path:(NSString*)path flag:(int)flag;
+(BOOL)clearMessages:(NSString*)path;
+(IMessage*)readMessage:(ReverseFile*)file;
@end
