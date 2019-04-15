//
//  HCDChatFaceHeleper.h
//  WeChatInputBar
//
//  Created by hcd on 2018/11/5.
//  Copyright © 2018 hcd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HCDChatFace, HCDChatFaceGroup;
@interface HCDChatFaceHeleper : NSObject
@property (nonatomic, strong) NSMutableArray<HCDChatFaceGroup *> *faceGroupArray;
+ (HCDChatFaceHeleper *) sharedFaceHelper;
- (NSArray<HCDChatFace *>*) getFaceArrayByGroupID:(NSString *)groupID;
@end
