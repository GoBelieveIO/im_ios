/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "AudioDownloader.h"
#import "TAHttpOperation.h"
#import "FileCache.h"
#import "wav_amr.h"
#import <SDWebImage/SDWebImage.h>
#import "UIImage+Resize.h"

@interface AudioDownloader()
@property(nonatomic)NSMutableArray *observers;
@property(nonatomic)NSMutableArray *messages;
@end

@implementation AudioDownloader
+(AudioDownloader*)instance {
    static AudioDownloader *box;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!box) {
            box = [[AudioDownloader alloc] init];
        }
    });
    return box;
}

-(id)init {
    self = [super init];
    if (self) {
        self.observers = [NSMutableArray array];
        self.messages = [NSMutableArray array];
    }
    return self;
}

-(void)addDownloaderObserver:(id<AudioDownloaderObserver>)ob {
    [self.observers addObject:ob];
}

-(void)removeDownloaderObserver:(id<AudioDownloaderObserver>)ob {
    [self.observers removeObject:ob];
}

-(BOOL)isDownloading:(IMessage*)msg {
    for (IMessage *message in self.messages) {
        if (message.receiver == msg.receiver &&
            message.sender == msg.sender &&
            message.msgLocalID == msg.msgLocalID) {
            return YES;
        }
    }
    return NO;
}

-(void)onDownloadSuccess:(IMessage*)msg {
    for (id<AudioDownloaderObserver> ob in self.observers) {
        [ob onAudioDownloadSuccess:msg];
    }
}

-(void)onDownloadFail:(IMessage*)msg {
    for (id<AudioDownloaderObserver> ob in self.observers) {
        [ob onAudioDownloadFail:msg];
    }
}

-(IMHttpOperation*)downloadURL:(NSString*)url success:(void (^)(NSData *data))success fail:(void (^)(void))fail {
    IMHttpOperation *request = [IMHttpOperation httpOperationWithTimeoutInterval:60];
    request.targetURL = url;
    request.method = @"GET";
    
    request.successCB = ^(IMHttpOperation*commObj, NSURLResponse *response, NSData *data) {
        success(data);
    };
    request.failCB = ^(IMHttpOperation*commObj, IMHttpOperationError error) {
        fail();
    };
    [[NSOperationQueue mainQueue] addOperation:request];
    return request;
    
}

-(void)downloadImage:(IMessage*)msg {
    if ([self isDownloading:msg]) {
        return;
    }
    NSString *msgURL = msg.imageContent.imageURL;
    
    [self.messages addObject:msg];
    [self downloadURL: msgURL
                success:^(NSData *data) {
                    [self.messages removeObject:msg];
                    NSAssert(msg.secret, @"");
                    
                    //todo save secret data into noncache directory
                    [[SDImageCache sharedImageCache] storeImageDataToDisk:data forKey:msgURL];
                    UIImage *image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:msgURL];
                    if (!image) {
                        //图片解码失败
                        [self onDownloadSuccess:msg];
                        return;
                    }
                    
                    UIImage *sizeImage = [image resize:CGSizeMake(256, 256)];
                    [[SDImageCache sharedImageCache] storeImage:sizeImage  forKey:msg.imageContent.littleImageURL completion:nil];
                    [self onDownloadSuccess:msg];
                }
                   fail:^{
                       [self.messages removeObject:msg];
                       [self onDownloadFail:msg];
                   }];
    
    
}

-(void)downloadAudio:(IMessage*)msg {
    if ([self isDownloading:msg]) {
        return;
    }
    NSString *msgURL = msg.audioContent.url;
    [self.messages addObject:msg];
    [self downloadURL: msgURL
                success:^(NSData *data) {
                    [self.messages removeObject:msg];
                    
                    FileCache *cache = [FileCache instance];
                    [cache storeFile:data forKey:msgURL];
       
                    NSString *amr_path = [cache queryCacheForKey:msgURL];
                    NSString *wav_path = [NSString stringWithFormat:@"%@.wav", amr_path];
                    int r = decode_amr([amr_path UTF8String], [wav_path UTF8String]);
                    if (r != 0) {
                        [self onDownloadFail:msg];
                    } else {
                        [cache.fileManager removeItemAtPath:amr_path error:nil];
                        [cache.fileManager moveItemAtPath:wav_path toPath:amr_path error:nil];
                        [self onDownloadSuccess:msg];
                    }
                }
                   fail:^{
                       [self.messages removeObject:msg];
                       [self onDownloadFail:msg];
                   }];
}

-(void)downloadVideoThumbnail:(IMessage*)msg {
    if ([self isDownloading:msg]) {
        return;
    }
    NSString *msgURL = msg.videoContent.thumbnailURL;
    
    [self.messages addObject:msg];
    [self downloadURL: msgURL
              success:^(NSData *data) {
                  [self.messages removeObject:msg];
                  NSAssert(msg.secret, @"");
                  //todo save secret data into noncache directory
                  [[SDImageCache sharedImageCache] storeImageDataToDisk:data forKey:msgURL];
                  UIImage *image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:msgURL];
                  if (!image) {
                      //图片解码失败
                      [self onDownloadSuccess:msg];
                      return;
                  }
                  [self onDownloadSuccess:msg];
              }
                 fail:^{
                     [self.messages removeObject:msg];
                     [self onDownloadFail:msg];
                 }];
}
@end
