//
//  AudioDownloader.h
//  Message
//
//  Created by houxh on 14-9-14.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMessage.h"

@protocol AudioDownloaderObserver <NSObject>

-(void)onAudioDownloadSuccess:(IMessage*)msg;
-(void)onAudioDownloadFail:(IMessage*)msg;

@end

@interface AudioDownloader : NSObject

+(AudioDownloader*)instance;

-(void)addDownloaderObserver:(id<AudioDownloaderObserver>)ob;
-(void)removeDownloaderObserver:(id<AudioDownloaderObserver>)ob;

-(BOOL)isDownloading:(IMessage*)msg;
-(void)downloadAudio:(IMessage*)msg;

@end
