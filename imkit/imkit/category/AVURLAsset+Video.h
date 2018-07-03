//
//  AVURLAsset+Video.h
//  gobelieve
//
//  Created by houxh on 2018/5/27.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@interface AVURLAsset(Video)
-(UIImage*)thumbnail;
-(NSDictionary*)metadata;
@end
