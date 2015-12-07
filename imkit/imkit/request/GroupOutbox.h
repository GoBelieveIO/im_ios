/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "IMessage.h"

@protocol GroupOutboxObserver <NSObject>

-(void)onAudioUploadSuccess:(IMessage*)msg URL:(NSString*)url;
-(void)onAudioUploadFail:(IMessage*)msg;
-(void)onImageUploadSuccess:(IMessage*)msg URL:(NSString*)url;
-(void)onImageUploadFail:(IMessage*)msg;

@end

@interface GroupOutbox : NSObject

+(GroupOutbox*)instance;

-(BOOL)isUploading:(IMessage*)msg;



-(BOOL)uploadGroupImage:(IMessage*)msg;
-(BOOL)uploadGroupImage:(IMessage*)msg withImage:(UIImage*)image;
-(BOOL)uploadGroupAudio:(IMessage*)msg;

-(void)addBoxObserver:(id<GroupOutboxObserver>)ob;
-(void)removeBoxObserver:(id<GroupOutboxObserver>)ob;
@end
