/************************************************************
  *  * EaseMob CONFIDENTIAL 
  * __________________ 
  * Copyright (C) 2013-2014 EaseMob Technologies. All rights reserved. 
  *  
  * NOTICE: All information contained herein is, and remains 
  * the property of EaseMob Technologies.
  * Dissemination of this information or reproduction of this material 
  * is strictly forbidden unless prior written permission is obtained
  * from EaseMob Technologies.
  */

#import "EaseChatBarMoreView.h"

#define CHAT_BUTTON_SIZE 50
#define INSETS 10
#define MOREVIEW_COL 4
#define MOREVIEW_ROW 2



@implementation UIView (MoreView)

- (void)removeAllSubview
{
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
}

@end

@interface EaseChatBarMoreView ()<UIScrollViewDelegate>
{
    NSInteger _maxIndex;
}

@property (nonatomic, strong) UIScrollView *scrollview;
@property (nonatomic, strong) UIPageControl *pageControl;

@end

@implementation EaseChatBarMoreView

+ (void)initialize
{
    // UIAppearance Proxy Defaults
    EaseChatBarMoreView *moreView = [self appearance];
    moreView.moreViewBackgroundColor = [UIColor whiteColor];
}

- (instancetype)initWithFrame:(CGRect)frame config:(NSDictionary*)config {
    self = [super initWithFrame:frame];
    if (self) {
        _maxIndex = -1;
        [self setupSubviewsForType:config];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _maxIndex = -1;
        [self setupSubviewsForType:nil];
    }
    return self;
}

- (void)setupSubviewsForType:(NSDictionary*)config {
    _scrollview = [[UIScrollView alloc] init];
    _scrollview.pagingEnabled = YES;
    _scrollview.showsHorizontalScrollIndicator = NO;
    _scrollview.showsVerticalScrollIndicator = NO;
    _scrollview.delegate = self;
    [self addSubview:_scrollview];
    
    _pageControl = [[UIPageControl alloc] init];
    _pageControl.currentPage = 0;
    _pageControl.numberOfPages = 1;
    [self addSubview:_pageControl];
    
    CGRect frame = self.frame;
    _scrollview.frame = CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame));
    _pageControl.frame = CGRectMake(0, CGRectGetHeight(frame) - 20, CGRectGetWidth(frame), 20);
    _pageControl.hidden = _pageControl.numberOfPages<=1;
    
    BOOL photoDisabled = [[config objectForKey:@(BUTTON_PHOTO_TAG)] boolValue];
    if (!photoDisabled) {
        [self insertItemWithImage:[UIImage imageNamed:@"chatBar_colorMore_photo"]
                 highlightedImage:[UIImage imageNamed:@"chatBar_colorMore_photoSelected"]
                            title:NSLocalizedString(@"message.photo", @"photo")
                              tag:BUTTON_PHOTO_TAG];
    }
    BOOL locationDisabled = [[config objectForKey:@(BUTTON_LOCATION_TAG)] boolValue];
    if (!locationDisabled) {
        [self insertItemWithImage:[UIImage imageNamed:@"chatBar_colorMore_location"]
                 highlightedImage:[UIImage imageNamed:@"chatBar_colorMore_locationSelected"]
                            title:NSLocalizedString(@"message.location", @"location")
                              tag:BUTTON_LOCATION_TAG];
    }
    
    BOOL cameraDisabled = [[config objectForKey:@(BUTTON_CAMERA_TAG)] boolValue];
    if (!cameraDisabled) {
        [self insertItemWithImage:[UIImage imageNamed:@"chatBar_colorMore_camera"]
                 highlightedImage:[UIImage imageNamed:@"chatBar_colorMore_cameraSelected"]
                            title:NSLocalizedString(@"message.camera", @"camera")
                              tag:BUTTON_CAMERA_TAG];
    }
    
    BOOL callDisabled = [[config objectForKey:@(BUTTON_CALL_TAG)] boolValue];
    if (!callDisabled) {
        [self insertItemWithImage:[UIImage imageNamed:@"chatBar_colorMore_videoCall"]
                 highlightedImage:[UIImage imageNamed:@"chatBar_colorMore_videoCallSelected"]
                            title:NSLocalizedString(@"message.call", @"call")
                              tag:BUTTON_CALL_TAG];
    }
}

- (void)insertItemWithImage:(UIImage *)image highlightedImage:(UIImage *)highLightedImage title:(NSString *)title tag:(NSInteger)tag {
    CGFloat insets = (self.frame.size.width - MOREVIEW_COL * CHAT_BUTTON_SIZE) / 5;
    CGRect frame = self.frame;
    _maxIndex++;
    NSInteger pageSize = MOREVIEW_COL*MOREVIEW_ROW;
    NSInteger page = _maxIndex/pageSize;
    NSInteger row = (_maxIndex%pageSize)/MOREVIEW_COL;
    NSInteger col = _maxIndex%MOREVIEW_COL;
    
    UIButton *moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    CGRect buttonFrame = CGRectMake(page * CGRectGetWidth(self.frame) + insets * (col + 1) + CHAT_BUTTON_SIZE * col, INSETS + INSETS * 2 * row + CHAT_BUTTON_SIZE * row, CHAT_BUTTON_SIZE , CHAT_BUTTON_SIZE);
    [moreButton setFrame:buttonFrame];
    [moreButton setImage:image forState:UIControlStateNormal];
    [moreButton setImage:highLightedImage forState:UIControlStateHighlighted];
    [moreButton addTarget:self action:@selector(moreAction:) forControlEvents:UIControlEventTouchUpInside];
    moreButton.tag = tag;
    [_scrollview addSubview:moreButton];
    
    CGRect f = CGRectMake(buttonFrame.origin.x - 10, buttonFrame.origin.y + CHAT_BUTTON_SIZE + 4, CHAT_BUTTON_SIZE + 20, 24);
    UILabel *label = [[UILabel alloc] initWithFrame:f];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = title;
    label.font = [UIFont systemFontOfSize:12];
    label.tag = 1000 + tag;
    [_scrollview addSubview:label];
    
    [_scrollview setContentSize:CGSizeMake(CGRectGetWidth(self.frame) * (page + 1), CGRectGetHeight(self.frame))];
    [_pageControl setNumberOfPages:page + 1];
    if (_maxIndex > MOREVIEW_COL) {
        frame.size.height = 150;
        _scrollview.frame = CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame));
        _pageControl.frame = CGRectMake(0, CGRectGetHeight(frame) - 20, CGRectGetWidth(frame), 20);
        self.frame = frame;
    }
    _pageControl.hidden = _pageControl.numberOfPages<=1;
}

- (void)updateItemWithImage:(UIImage *)image highlightedImage:(UIImage *)highLightedImage title:(NSString *)title tag:(NSInteger)tag {
    UIView *moreButton = [_scrollview viewWithTag:tag];
    if (moreButton && [moreButton isKindOfClass:[UIButton class]]) {
        [(UIButton*)moreButton setImage:image forState:UIControlStateNormal];
        [(UIButton*)moreButton setImage:highLightedImage forState:UIControlStateHighlighted];
    }
}


#pragma setter
- (void)setMoreViewBackgroundColor:(UIColor *)moreViewBackgroundColor {
    _moreViewBackgroundColor = moreViewBackgroundColor;
    if (_moreViewBackgroundColor) {
        [self setBackgroundColor:_moreViewBackgroundColor];
    }
}



#pragma mark - UIScrollViewDelegate

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGPoint offset =  scrollView.contentOffset;
    if (offset.x == 0) {
        _pageControl.currentPage = 0;
    } else {
        int page = offset.x / CGRectGetWidth(scrollView.frame);
        _pageControl.currentPage = page;
    }
}

#pragma mark - action
- (void)callAction {
    if(_delegate && [_delegate respondsToSelector:@selector(moreViewVideoCallAction:)]){
        [_delegate moreViewVideoCallAction:self];
    }
}

- (void)takePicAction {
    if(_delegate && [_delegate respondsToSelector:@selector(moreViewTakePicAction:)]){
        [_delegate moreViewTakePicAction:self];
    }
}

- (void)photoAction {
    if (_delegate && [_delegate respondsToSelector:@selector(moreViewPhotoAction:)]) {
        [_delegate moreViewPhotoAction:self];
    }
}

- (void)locationAction {
    if (_delegate && [_delegate respondsToSelector:@selector(moreViewLocationAction:)]) {
        [_delegate moreViewLocationAction:self];
    }
}

- (void)moreAction:(UIButton*)sender {
    UIButton *button = (UIButton*)sender;
    if (sender.tag == BUTTON_PHOTO_TAG) {
        [self photoAction];
    } else if (sender.tag == BUTTON_CAMERA_TAG) {
        [self takePicAction];
    } else if (sender.tag == BUTTON_LOCATION_TAG) {
        [self locationAction];
    } else if (sender.tag == BUTTON_CALL_TAG) {
        [self callAction];
    } else if ([_delegate respondsToSelector:@selector(moreView:didItemInMoreViewAtIndex:)]) {
        [_delegate moreView:self didItemInMoreViewAtIndex:button.tag];
    }
}

@end
