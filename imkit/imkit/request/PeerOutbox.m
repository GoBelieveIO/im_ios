/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "PeerOutbox.h"
#import "IMHttpAPI.h"
#import "../model/FileCache.h"
#import <imsdk/IMService.h>
#import "PeerMessageDB.h"
#import "GroupMessageDB.h"
#import "wav_amr.h"
#import "UIImageView+WebCache.h"

@interface PeerOutbox()
@property(nonatomic) NSMutableArray *observers;
@property(nonatomic) NSMutableArray *messages;
@end

@implementation PeerOutbox
+(PeerOutbox*)instance {
    static PeerOutbox *box;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!box) {
            box = [[PeerOutbox alloc] init];
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

-(BOOL)isUploading:(IMessage *)msg {
    for (IMessage *message in self.messages) {
        if (message.receiver == msg.receiver &&
            message.sender == msg.sender &&
            message.msgLocalID == msg.msgLocalID) {
            return YES;
        }
    }
    return NO;
}

-(void)sendAudioMessage:(IMessage*)msg URL:url{
    MessageAudioContent *old = msg.audioContent;
    MessageAudioContent *audio = [[MessageAudioContent alloc] initWithAudio:url duration:old.duration];
    msg.rawContent = audio.raw;
    [self sendMessage:msg];
    msg.rawContent = old.raw;
}

-(void)sendImageMessage:(IMessage*)msg URL:url {
    MessageImageContent *old = msg.imageContent;
    MessageImageContent *content = [[MessageImageContent alloc] initWithImageURL:url];
    msg.rawContent = content.raw;
    [self sendMessage:msg];
    msg.rawContent = old.raw;
}

- (void)sendMessage:(IMessage*)msg{
 
    IMMessage *im = [[IMMessage alloc] init];
    im.sender = msg.sender;
    im.receiver = msg.receiver;
    im.msgLocalID = msg.msgLocalID;
    
    im.content = msg.rawContent;
    
    [[IMService instance] sendPeerMessage:im];
}

-(void)onUploadImageSuccess:(IMessage*)msg URL:url {
    for (id<PeerOutboxObserver> observer in self.observers) {
        [observer onImageUploadSuccess:msg URL:url];
    }

  
}

-(void)onUploadImageFail:(IMessage*)msg {
    for (id<PeerOutboxObserver> observer in self.observers) {
        [observer onImageUploadFail:msg];
    }
}

-(void)onUploadAudioSuccess:(IMessage*)msg URL:url {
    for (id<PeerOutboxObserver> observer in self.observers) {
        [observer onAudioUploadSuccess:msg URL:url];
    }
}

-(void)onUploadAudioFail:(IMessage*)msg {
    for (id<PeerOutboxObserver> observer in self.observers) {
        [observer onAudioUploadFail:msg];
    }
}

-(BOOL)uploadImage:(IMessage*)msg withImage:(UIImage*)image {
    [self.messages addObject:msg];
    [IMHttpAPI uploadImage:image
                   success:^(NSString *url) {
                       [self.messages removeObject:msg];
                       NSLog(@"upload image success url:%@", url);
                       [self sendImageMessage:msg URL:url];
                       [self onUploadImageSuccess:msg URL:url];
                       
                   }
                      fail:^() {
                          NSLog(@"upload image fail");
                          [self.messages removeObject:msg];
                          [[PeerMessageDB instance] markMessageFailure:msg.msgLocalID uid:msg.receiver];
                          [self onUploadImageFail:msg];
                      }];
    return YES;

}

-(BOOL)uploadImage:(IMessage*)msg {
    MessageImageContent *content = msg.imageContent;
    UIImage *image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:content.imageURL];
    if (!image) {
        NSLog(@"can't load image from image cache");
        return NO;
    }
    return [self uploadImage:msg withImage:image];
}

-(BOOL)uploadAudio:(IMessage*)msg {
    FileCache *cache = [FileCache instance];
    MessageAudioContent *content = msg.audioContent;
    NSString *path = [cache queryCacheForKey:content.url];

    NSString *tmp = [NSString stringWithFormat:@"%@.amr", path];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:tmp]) {
        const char *amr = [tmp UTF8String];
        const char *wav = [path UTF8String];
    
        int r = encode_amr(wav, amr);
        if (r != 0) {
            return NO;
        }

    }

    NSData *data = [NSData dataWithContentsOfFile:tmp];
    if (data == nil) {
        return NO;
    }
    
    [self.messages addObject:msg];
    [IMHttpAPI uploadAudio:data
                    success:^(NSString *url) {
                        [self.messages removeObject:msg];
                        NSLog(@"upload audio success url:%@", url);
                        [self sendAudioMessage:msg URL:url];
                        [self onUploadAudioSuccess:msg URL:url];
                    }fail:^{
                        NSLog(@"upload audio fail");
                        [self.messages removeObject:msg];
                        [[PeerMessageDB instance] markMessageFailure:msg.msgLocalID uid:msg.receiver];
                        [self onUploadAudioFail:msg];
                    }];
    
    return YES;
}

-(void)addBoxObserver:(id<PeerOutboxObserver>)ob {
    [self.observers addObject:ob];
}

-(void)removeBoxObserver:(id<PeerOutboxObserver>)ob {
    [self.observers removeObject:ob];
}

@end
