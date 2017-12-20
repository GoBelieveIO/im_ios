//
//  OverlayLabel.h
//  gobelieve
//
//  Created by houxh on 2017/12/4.
//

#import <Foundation/Foundation.h>

@interface OverlayLabel : UILabel
- (NSArray *)getRangesForURLs:(NSAttributedString *)text;
- (NSDictionary *)attributesFromProperties;
- (NSAttributedString *)addLinkAttributesToAttributedString:(NSAttributedString *)string linkRanges:(NSArray *)linkRanges;
@end
