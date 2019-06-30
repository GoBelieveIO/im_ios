//
//  HCDChatFace.h
//  WeChatInputBar
//
//  Created by hcd on 2018/11/5.
//  Copyright © 2018 hcd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HCDFaceType) {
    HCDFaceTypeEmoji,
    HCDFaceTypeGIF,
};


@interface HCDChatFace : NSObject
//@property (nonatomic, strong) NSString *faceID;
@property (nonatomic, strong) NSString *faceName;

@property(nonatomic, copy) NSString *emoji;

+ (HCDChatFace *)emojiWithCode:(int)code;
@end


@interface HCDChatFaceGroup : NSObject
@property (nonatomic, assign) HCDFaceType faceType;
@property (nonatomic, strong) NSString *groupID;
@property (nonatomic, strong) NSString *groupImageName;
@property (nonatomic, strong, nullable) NSArray<HCDChatFace *> *facesArray;
@end

NS_ASSUME_NONNULL_END
