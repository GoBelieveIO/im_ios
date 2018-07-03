//
//  Outbox.h
//  imkit
//
//  Created by houxh on 16/1/18.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "IMessage.h"

@protocol OutboxObserver <NSObject>

-(void)onAudioUploadSuccess:(IMessage*)msg URL:(NSString*)url;
-(void)onAudioUploadFail:(IMessage*)msg;
-(void)onImageUploadSuccess:(IMessage*)msg URL:(NSString*)url;
-(void)onImageUploadFail:(IMessage*)msg;

-(void)onVideoUploadSuccess:(IMessage*)msg URL:(NSString*)url thumbnailURL:(NSString*)thumbURL;
-(void)onVideoUploadFail:(IMessage*)msg;
@end
@interface Outbox : NSObject

-(BOOL)isUploading:(IMessage*)msg;

-(BOOL)uploadVideo:(IMessage*)msg;
-(BOOL)uploadImage:(IMessage*)msg;
-(BOOL)uploadImage:(IMessage*)msg withImage:(UIImage*)image;
-(BOOL)uploadAudio:(IMessage*)msg;

-(BOOL)uploadSecretVideo:(IMessage*)msg;
-(BOOL)uploadSecretImage:(IMessage*)msg;
-(BOOL)uploadSecretImage:(IMessage*)msg withImage:(UIImage*)image;
-(BOOL)uploadSecretAudio:(IMessage*)msg;


-(void)addBoxObserver:(id<OutboxObserver>)ob;
-(void)removeBoxObserver:(id<OutboxObserver>)ob;


//override
-(void)sendMessage:(IMessage*)msg;
//override
-(void)markMessageFailure:(IMessage*)msg;
    
-(void)saveMessageAttachment:(IMessage*)msg url:(NSString*)url;
-(void)saveMessageAttachment:(IMessage*)msg url:(NSString*)url thumbnail:(NSString*)thumbnail;
@end
