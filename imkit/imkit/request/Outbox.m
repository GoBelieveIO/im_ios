//
//  Outbox.m
//  imkit
//
//  Created by houxh on 16/1/18.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "Outbox.h"
#import "IMHttpAPI.h"
#import "FileCache.h"
#import "wav_amr.h"
#import "UIImageView+WebCache.h"

@interface Outbox()
@property(nonatomic) NSMutableArray *observers;
@property(nonatomic) NSMutableArray *messages;
@end

@implementation Outbox


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

-(void)sendAudioMessage:(IMessage*)msg URL:url {
    MessageAudioContent *old = msg.audioContent;
    MessageAudioContent *audio = [old cloneWithURL:url];
    msg.rawContent = audio.raw;
    [self sendMessage:msg];
    msg.rawContent = old.raw;
}

-(void)sendImageMessage:(IMessage*)msg URL:url {
    MessageImageContent *old = msg.imageContent;
    MessageImageContent *content = [old cloneWithURL:url];
    msg.rawContent = content.raw;
    [self sendMessage:msg];
    msg.rawContent = old.raw;
}

-(void)sendMessage:(IMessage*)msg {
    

}

-(void)markMessageFailure:(IMessage*)msg {
    
}

-(void)saveMessageAttachment:(IMessage*)msg url:(NSString*)url {
    NSAssert(NO, @"not implement");
}

-(void)onUploadImageSuccess:(IMessage*)msg URL:url {
    for (id<OutboxObserver> observer in self.observers) {
        [observer onImageUploadSuccess:msg URL:url];
    }
    
    
}

-(void)onUploadImageFail:(IMessage*)msg {
    for (id<OutboxObserver> observer in self.observers) {
        [observer onImageUploadFail:msg];
    }
}

-(void)onUploadAudioSuccess:(IMessage*)msg URL:url {
    for (id<OutboxObserver> observer in self.observers) {
        [observer onAudioUploadSuccess:msg URL:url];
    }
    
}


-(void)onUploadAudioFail:(IMessage*)msg {
    for (id<OutboxObserver> observer in self.observers) {
        [observer onAudioUploadFail:msg];
    }
}

//用服务器的url做为key对应本地的缓存
-(void)saveAudio:(IMessage*)msg url:(NSString*)url {
    MessageAudioContent *content = msg.audioContent;
    NSString *c = [[FileCache instance] queryCacheForKey:content.url];
    if (c.length > 0) {
        NSData *data = [NSData dataWithContentsOfFile:c];
        if (data.length > 0) {
            [[FileCache instance] storeFile:data forKey:url];
        }
    }
}

//用服务器的url做为key对应本地的缓存
-(void)saveImage:(IMessage*)msg url:(NSString*)url {
    MessageImageContent *content = msg.imageContent;
    UIImage *image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:content.imageURL];
    UIImage *littleImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:content.littleImageURL];
    
    if (image && littleImage) {
        MessageImageContent *newContent = [content cloneWithURL:url];
        [[SDImageCache sharedImageCache] storeImage:image forKey:newContent.imageURL];
        [[SDImageCache sharedImageCache] storeImage:littleImage forKey:newContent.littleImageURL];
    }
}

-(BOOL)uploadImage:(IMessage*)msg withImage:(UIImage*)image {
    [self.messages addObject:msg];
    [IMHttpAPI uploadImage:image
                   success:^(NSString *url) {
                       [self.messages removeObject:msg];
                       
                       NSLog(@"upload image success url:%@", url);
                       [self saveImage:msg url:url];
                       [self saveMessageAttachment:msg url:url];
                       [self sendImageMessage:msg URL:url];
                       [self onUploadImageSuccess:msg URL:url];
                       
                   }
                      fail:^() {
                          NSLog(@"upload image fail");
                          [self.messages removeObject:msg];
                          [self markMessageFailure:msg];
                          [self onUploadImageFail:msg];
                      }];
    return YES;
    
}
-(BOOL)uploadImage:(IMessage*)msg {
    MessageImageContent *content = msg.imageContent;
    UIImage *image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:content.imageURL];
    if (!image) {
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
                       NSLog(@"upload audio success url:%@", url);

                       [self.messages removeObject:msg];
                       [self saveAudio:msg url:url];
                       [self saveMessageAttachment:msg url:url];
                       [self sendAudioMessage:msg URL:url];
                       [self onUploadAudioSuccess:msg URL:url];
                   }fail:^{
                       NSLog(@"upload audio fail");
                       
                       [self.messages removeObject:msg];
                       [self markMessageFailure:msg];

                       [self onUploadAudioFail:msg];
                   }];
    
    return YES;
}

-(void)addBoxObserver:(id<OutboxObserver>)ob {
    [self.observers addObject:ob];
}

-(void)removeBoxObserver:(id<OutboxObserver>)ob {
    [self.observers removeObject:ob];
}

@end


