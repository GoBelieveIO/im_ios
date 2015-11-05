//
//  EMEomtionEscape.h
//  EaseUI
//
//  Created by EaseMob on 15/9/29.
//  Copyright (c) 2015年 easemob. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface EaseEmotionEscape : NSObject

+(NSMutableAttributedString *) attributtedStringFromText:(NSString *) aInputText;

+(NSAttributedString *) attStringFromTextForChatting:(NSString *) aInputText;

+(NSAttributedString *) attStringFromTextForInputView:(NSString *) aInputText;

@end

@interface EMTextAttachment : NSTextAttachment

@property(nonatomic, strong) NSString *imageName;

@end
