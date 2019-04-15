#import <Foundation/Foundation.h>

@interface HCDChatHelper : NSObject
@property (nonatomic, strong) NSMutableArray *faceGroupArray;
+ (NSAttributedString *)formatMessageString:(NSString *)text withFont:(UIFont*)font;
@end
