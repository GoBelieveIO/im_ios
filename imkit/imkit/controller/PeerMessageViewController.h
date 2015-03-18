//
//  PeerMessageViewController.h
//  imkit
//
//  Created by houxh on 15/3/18.
//  Copyright (c) 2015年 beetle. All rights reserved.
//

#import "MessageViewController.h"
#import "TextMessageViewController.h"
#define TEXT_MODE1
#ifdef TEXT_MODE
@interface PeerMessageViewController : TextMessageViewController
#else
@interface PeerMessageViewController : MessageViewController
#endif

@property(nonatomic, assign) int64_t currentUID;
@property(nonatomic, assign) int64_t peerUID;
@property(nonatomic, copy) NSString *peerName;

@end
