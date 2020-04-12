/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>
#import "MessageContent.h"

#define  TSPreKeyWhisperMessageType 1
#define  TSEncryptedWhisperMessageType 2

@interface MessageSecret : MessageContent
@property(nonatomic, copy) NSString *ciphertext;
@property(nonatomic, assign) int cipherType;

-(id)initWithCiphertext:(NSString*)ciphertext cipherType:(int)type uuid:(NSString*)uuid;
@end
