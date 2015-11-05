//
//  EaseEmotionEscape.m
//  EaseUI
//
//  Created by EaseMob on 15/9/29.
//  Copyright (c) 2015年 easemob. All rights reserved.
//

#import "EaseEmotionEscape.h"

#define RGBCOLOR(r,g,b) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:1]
#define kEmotionTopMargin -3.0f

@implementation EMTextAttachment
//I want my emoticon has the same size with line's height
- (CGRect)attachmentBoundsForTextContainer:(NSTextContainer *)textContainer proposedLineFragment:(CGRect)lineFrag glyphPosition:(CGPoint)position characterIndex:(NSUInteger)charIndex NS_AVAILABLE_IOS(7_0)
{
    return CGRectMake( 0, kEmotionTopMargin, lineFrag.size.height, lineFrag.size.height);
}

@end

@implementation EaseEmotionEscape

+(NSMutableAttributedString *) attributtedStringFromText:(NSString *) aInputText
{
    NSString *urlPattern = @"\\\\::([a-z]+)([0-9]+)]";
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:urlPattern options:NSRegularExpressionCaseInsensitive error:&error ];
    
    NSArray* matches = [regex matchesInString:aInputText options:NSMatchingReportCompletion range:NSMakeRange(0, [aInputText length])];
    NSMutableAttributedString * string = [[ NSMutableAttributedString alloc ] initWithString:aInputText attributes:nil ];
    
    for (NSTextCheckingResult *match in [matches reverseObjectEnumerator]) {
        NSRange matchRange = [match range];
        //            if(NSTextCheckingTypeRegularExpression == [match resultType])
        //                NSLog(@"%@",[match grammarDetails]);
        NSString *subStr = [aInputText substringWithRange:matchRange];
        
        NSString *typePattern = @"([a-z]+)";
        NSString *namePattern = @"([0-9]+)";
        NSRegularExpression *typeRegex = [NSRegularExpression regularExpressionWithPattern:typePattern options:NSRegularExpressionCaseInsensitive error:&error ];
        NSArray* typeMatches = [typeRegex matchesInString:subStr options:NSMatchingReportCompletion range:NSMakeRange(0, [subStr length])];
        NSString *type;
        for (NSTextCheckingResult *submatch in typeMatches) {
            type = [subStr substringWithRange:[submatch range]];
        }
        
        NSRegularExpression *nameRegex = [NSRegularExpression regularExpressionWithPattern:namePattern options:NSRegularExpressionCaseInsensitive error:&error ];
        NSArray* nameMatches = [nameRegex matchesInString:subStr options:NSMatchingReportCompletion range:NSMakeRange(0, [subStr length])];
        NSString *number;
        for (NSTextCheckingResult *submatch in nameMatches) {
            number = [subStr substringWithRange:[submatch range]];
        }

        EMTextAttachment * textAttachment = [[EMTextAttachment alloc ] initWithData:nil ofType:nil];
        textAttachment.imageName = number;
        UIImage * emojiImage;
        
        if ([type isEqualToString:@"a"]) {
            NSString *emojiName = [NSString stringWithFormat:@"a%@",number];
            emojiImage = [UIImage imageNamed:emojiName];
        }
        
        NSAttributedString * textAttachmentString;
        if (emojiImage) {
            textAttachment.image = emojiImage ;
            textAttachmentString = [NSAttributedString attributedStringWithAttachment:textAttachment];
        }else{
            NSString *str = [EaseEmotionEscape getEmojiTextByKey:subStr];
            if (str != nil) {
                str = [NSString stringWithFormat:@"[%@]", str];
                textAttachmentString = [[NSAttributedString alloc] initWithString:str];
            }else {
                textAttachmentString = [[NSAttributedString alloc] initWithString:@"[表情]"];
            }
        }
        
        if (textAttachment != nil) {
            [string deleteCharactersInRange:matchRange];
            [string insertAttributedString:textAttachmentString atIndex:matchRange.location];
        }
    }
    
    //    [regex replaceMatchesInString:string.mutableString options:NSMatchingReportCompletion range:NSMakeRange(0, [string.mutableString length]) withTemplate:@""];
    return string;
}

+(NSAttributedString *) attStringFromTextForChatting:(NSString *) aInputText
{
    NSMutableAttributedString * string = [EaseEmotionEscape attributtedStringFromText:aInputText];
    NSMutableParagraphStyle * paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:0];
    [string addAttribute:NSParagraphStyleAttributeName
                   value:paragraphStyle
                   range:NSMakeRange(0, [string length])];
    return string;
}

+(NSAttributedString *) attStringFromTextForInputView:(NSString *) aInputText
{
    NSMutableAttributedString * string = [EaseEmotionEscape attributtedStringFromText:aInputText];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 1.0;
    [string addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, string.length)];
    [string addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:16.0f] range:NSMakeRange(0, string.length)];
    return string;
}

+(NSString*) getEmojiTextByKey:(NSString*) aKey
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *plistPaht = [paths objectAtIndex:0];
    NSString *fileName = [plistPaht stringByAppendingPathComponent:@"EmotionTextMapList.plist"];
    NSMutableDictionary *emojiKeyValue = [[NSMutableDictionary alloc] initWithContentsOfFile: fileName];
    return [emojiKeyValue objectForKey:aKey];
    //    NSLog(@"write data is :%@",writeData);
}

@end