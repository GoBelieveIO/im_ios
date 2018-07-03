//
//  AVURLAsset+Video.m
//  gobelieve
//
//  Created by houxh on 2018/5/27.
//

#import "AVURLAsset+Video.h"
#
@implementation AVURLAsset(Video)

-(UIImage*)thumbnail {

    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:self];
    // 设定缩略图的方向
    // 如果不设定，可能会在视频旋转90/180/270°时，获取到的缩略图是被旋转过的，而不是正向的
    gen.appliesPreferredTrackTransform = YES;
    // 设置图片的最大size(分辨率)
    gen.maximumSize = CGSizeMake(300, 169);
    CMTime time = CMTimeMakeWithSeconds(0.0, 30);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *thumb = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    return thumb;

}
-(NSDictionary*)metadata {
    CMTime   time = [self duration];
    int seconds = floor(time.value/time.timescale);
    CGSize size = [[[self tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] naturalSize];
    return @{@"width": @((int)size.width),
             @"height": @((int)size.height),
             @"duration" : @(seconds)};
}
@end
