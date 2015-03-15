//
//  ReverseFile.h
//  Message
//
//  Created by houxh on 14-7-22.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ReverseFile : NSObject
@property(nonatomic)int fd;
@property(nonatomic)int pos;
-(id)initWithFD:(int)fd;
-(int)read:(char*)p length:(int)len;
@end
