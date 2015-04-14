/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

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
