//
//  Outbox.h
//  Message
//
//  Created by houxh on 14-9-13.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "IMessage.h"

@protocol OutboxObserver <NSObject>

-(void)onAudioUploadSuccess:(IMessage*)msg URL:(NSString*)url;
-(void)onAudioUploadFail:(IMessage*)msg;
-(void)onImageUploadSuccess:(IMessage*)msg URL:(NSString*)url;
-(void)onImageUploadFail:(IMessage*)msg;

@end

@interface Outbox : NSObject

+(Outbox*)instance;

-(BOOL)isUploading:(IMessage*)msg;

-(BOOL)uploadImage:(IMessage*)msg image:(UIImage*)image;
-(BOOL)uploadAudio:(IMessage*)msg;

-(void)addBoxObserver:(id<OutboxObserver>)ob;
-(void)removeBoxObserver:(id<OutboxObserver>)ob;
@end
