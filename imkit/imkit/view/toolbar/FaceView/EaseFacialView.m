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

#import "EaseFacialView.h"
#import "EaseEmoji.h"
#import "EaseFaceView.h"
#import "EaseEmotionManager.h"

@interface EaseFacialView () <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollview;
@property (nonatomic, strong) UIPageControl *pageControl;

@end

@implementation EaseFacialView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _faces = [NSMutableArray arrayWithArray:[EaseEmoji allEmoji]];
        _scrollview = [[UIScrollView alloc] initWithFrame:frame];
        _scrollview.pagingEnabled = YES;
        _scrollview.showsHorizontalScrollIndicator = NO;
        _scrollview.showsVerticalScrollIndicator = NO;
        _scrollview.alwaysBounceHorizontal = YES;
        _scrollview.delegate = self;
        _pageControl = [[UIPageControl alloc] init];
        [self addSubview:_scrollview];
        [self addSubview:_pageControl];
    }
    return self;
}


//给faces设置位置
-(void)loadFacialView:(EaseEmotionManager*)emotionManager size:(CGSize)size
{
    for (UIView *view in [self.scrollview subviews]) {
        [view removeFromSuperview];
    }
    
    [_scrollview setContentOffset:CGPointZero];
	NSInteger maxRow = emotionManager.emotionRow + 1;
    NSInteger maxCol = emotionManager.emotionCol;
    NSInteger pageSize = emotionManager.emotionRow * emotionManager.emotionCol;
    CGFloat itemWidth = self.frame.size.width / maxCol;
    CGFloat itemHeight = self.frame.size.height / maxRow;
    
    CGRect frame = self.frame;
    frame.size.height -= itemHeight;
    _scrollview.frame = frame;
    
    _faces = [NSMutableArray arrayWithArray:emotionManager.emotions];
    NSInteger totalPage = [_faces count]%pageSize == 0 ? [_faces count]/pageSize : [_faces count]/pageSize + 1;
    [_scrollview setContentSize:CGSizeMake(totalPage * CGRectGetWidth(self.frame), itemHeight * emotionManager.emotionRow)];
    
    _pageControl.currentPage = 0;
    _pageControl.numberOfPages = totalPage;
    _pageControl.frame = CGRectMake(0, (maxRow - 1) * itemHeight + 5, CGRectGetWidth(self.frame), itemHeight - 10);
    
//    UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    [deleteButton setBackgroundColor:[UIColor clearColor]];
//    [deleteButton setFrame:CGRectMake((maxCol - 1) * itemWidth, (maxRow - 1) * itemHeight, itemWidth, itemHeight)];
//    [deleteButton setImage:[UIImage imageNamed:@"faceDelete"] forState:UIControlStateNormal];
//    deleteButton.tag = 10000;
//    [deleteButton addTarget:self action:@selector(selected:) forControlEvents:UIControlEventTouchUpInside];
//    [self addSubview:deleteButton];
    
//    UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    [sendButton setTitle:NSLocalizedString(@"send", @"Send") forState:UIControlStateNormal];
//    [sendButton setFrame:CGRectMake((maxCol - 1) * itemWidth - 10, (maxRow - 1) * itemHeight + 5, itemWidth + 10, itemHeight - 10)];
//    [sendButton addTarget:self action:@selector(sendAction:) forControlEvents:UIControlEventTouchUpInside];
//    [sendButton setBackgroundColor:[UIColor colorWithRed:10 / 255.0 green:82 / 255.0 blue:104 / 255.0 alpha:1.0]];
//    [self addSubview:sendButton];
    
    for (int i = 0; i < totalPage; i ++) {
        for (int row = 0; row < emotionManager.emotionRow; row++) {
            for (int col = 0; col < maxCol; col++) {
                NSInteger index = i * pageSize + row * maxCol + col;
                if (emotionManager.emotionType != EMEmotionGif) {
                    if (index != 0 && (index - (pageSize-1))%pageSize == 0) {
                        [_faces insertObject:@"" atIndex:index];
                        break;
                    }
                }
                if (index < [_faces count]) {
                    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                    [button setBackgroundColor:[UIColor clearColor]];
                    [button setFrame:CGRectMake(i * CGRectGetWidth(self.frame) + col * itemWidth, row * itemHeight, itemWidth, itemHeight)];
                    [button.titleLabel setFont:[UIFont fontWithName:@"AppleColorEmoji" size:29.0]];
                    if (emotionManager.emotionType == EMEmotionGif) {
                        [button setImage:[UIImage imageNamed:[_faces objectAtIndex:index]] forState:UIControlStateNormal];
                        button.imageView.contentMode = UIViewContentModeScaleAspectFit;
                        [button addTarget:self action:@selector(sendGifAction:) forControlEvents:UIControlEventTouchUpInside];
                    } else if (emotionManager.emotionType == EMEmotionPng) {
                        [button setImage:[UIImage imageNamed:[_faces objectAtIndex:index]] forState:UIControlStateNormal];
                        button.imageView.contentMode = UIViewContentModeScaleAspectFit;
                        [button setImageEdgeInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
                        [button addTarget:self action:@selector(sendPngAction:) forControlEvents:UIControlEventTouchUpInside];
                    } else {
                        [button setTitle: [_faces objectAtIndex:index] forState:UIControlStateNormal];
                        [button addTarget:self action:@selector(selected:) forControlEvents:UIControlEventTouchUpInside];
                    }
                    button.tag = index;
                    [_scrollview addSubview:button];
                }
                else{
                    break;
                }
            }
        }
        if (emotionManager.emotionType != EMEmotionGif) {
            UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [deleteButton setBackgroundColor:[UIColor clearColor]];
            [deleteButton setFrame:CGRectMake(i * CGRectGetWidth(self.frame) + (emotionManager.emotionCol - 1) * itemWidth, (emotionManager.emotionRow - 1) * itemHeight, itemWidth, itemHeight)];
            [deleteButton setImage:[UIImage imageNamed:@"faceDelete"] forState:UIControlStateNormal];
            [deleteButton setImage:[UIImage imageNamed:@"faceDelete_select"] forState:UIControlStateHighlighted];
            deleteButton.tag = 10000;
            [deleteButton addTarget:self action:@selector(selected:) forControlEvents:UIControlEventTouchUpInside];
            [_scrollview addSubview:deleteButton];
        }
    }
}


-(void)selected:(UIButton*)bt
{
    if (bt.tag == 10000 && _delegate) {
        [_delegate deleteSelected:nil];
    } else{
        NSString *str = [_faces objectAtIndex:bt.tag];
        if (_delegate) {
            [_delegate selectedFacialView:str];
        }
    }
}

- (void)sendAction:(id)sender
{
    if (_delegate) {
        [_delegate sendFace];
    }
}

- (void)sendPngAction:(UIButton*)bt
{
    if (bt.tag == 10000 && _delegate) {
        [_delegate deleteSelected:nil];
    }else{
        NSString *str = [_faces objectAtIndex:bt.tag];
        if (_delegate) {
            str = [NSString stringWithFormat:@"\\::%@]",str];
            [_delegate selectedFacialView:str];
        }
    }
}

- (void)sendGifAction:(UIButton*)bt
{
    NSString *str = [_faces objectAtIndex:bt.tag];
    if (_delegate) {
        [_delegate sendFace:str];
    }
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    CGPoint offset =  scrollView.contentOffset;
    if (offset.x == 0) {
        _pageControl.currentPage = 0;
    } else {
        int page = offset.x / CGRectGetWidth(scrollView.frame);
        _pageControl.currentPage = page;
    }
}

@end
