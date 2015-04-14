/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/


#import <UIKit/UIKit.h>

@interface UIImage (JSMessagesView)

#pragma mark - Avatar styles
- (UIImage *)circleImageWithSize:(CGFloat)size;
- (UIImage *)squareImageWithSize:(CGFloat)size;

- (UIImage *)imageAsCircle:(BOOL)clipToCircle
               withDiamter:(CGFloat)diameter
               borderColor:(UIColor *)borderColor
               borderWidth:(CGFloat)borderWidth
              shadowOffSet:(CGSize)shadowOffset;

#pragma mark - Input bar
+ (UIImage *)inputBar;
+ (UIImage *)inputField;

#pragma mark - Bubble cap insets
- (UIImage *)makeStretchableDefaultIncoming;
- (UIImage *)makeStretchableDefaultOutgoing;


#pragma mark - Incoming message bubbles
+ (UIImage *)bubbleDefaultIncoming;
+ (UIImage *)bubbleDefaultIncomingSelected;

#pragma mark - Outgoing message bubbles
+ (UIImage *)bubbleDefaultOutgoing;
+ (UIImage *)bubbleDefaultOutgoingSelected;

@end
