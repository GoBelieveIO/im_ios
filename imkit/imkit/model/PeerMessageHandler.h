//
//  PeerMessageHandler.h
//  Message
//
//  Created by houxh on 14-7-22.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <imsdk/IMService.h>

@interface PeerMessageHandler : NSObject<IMPeerMessageHandler>
+(PeerMessageHandler*)instance;
@end
