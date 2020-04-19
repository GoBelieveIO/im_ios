//
//  HCDChatBoxFaceView.m
//  WeChatInputBar
//
//  Created by hcd on 2018/11/5.
//  Copyright © 2018 hcd. All rights reserved.
//

#import "HCDChatBoxFaceView.h"
#import "HCDChatFaceMenuView.h"
#import "HCDChatInputBarDefine.h"
#import "HCDChatFaceItemView.h"
#import "HCDChatFaceHeleper.h"
#import "UIView+HCD_Extension.h"

@interface HCDChatBoxFaceView()<UIScrollViewDelegate,HCDChatBoxFaceMenuViewDelegate>

@property (nonatomic, strong) HCDChatFaceGroup *curGroup;
@property (nonatomic, assign) int curPage;
@property (nonatomic, strong) UIView *topLine;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) HCDChatFaceMenuView *faceMenuView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray *facePageViewArray;

@end

@implementation HCDChatBoxFaceView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setBackgroundColor:DEFAULT_CHATBOX_COLOR];
        [self addSubview:self.topLine];
        [self addSubview:self.faceMenuView];
        [self addSubview:self.scrollView];
        [self addSubview:self.pageControl];
        for (HCDChatFaceItemView *pageView in self.facePageViewArray) {
            [self.scrollView addSubview:pageView];
        }
        
        [self.scrollView  setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height - HEIGHT_BOTTOM_VIEW - 18 - (isFullScreen() ? 39 : 0))];
        [self.pageControl setFrame:CGRectMake(0, self.scrollView.height + 3, frame.size.width, 8)];
        
        for (HCDChatFaceItemView *pageView in self.facePageViewArray) {
            [pageView setFrame:self.scrollView.bounds];
        }
        
        self.curGroup = [[[HCDChatFaceHeleper sharedFaceHelper] faceGroupArray] objectAtIndex:0];
        if (self.curGroup.facesArray == nil) {
            self.curGroup.facesArray = [[HCDChatFaceHeleper sharedFaceHelper] getFaceArrayByGroupID:self.curGroup.groupID];
        }
        
        [self reloadScrollView];
    }
    return self;
}


#pragma mark - HCDChatBoxFaceMenuViewDelegate
/**
 *  菜单发送按钮
 */
- (void)chatBoxFaceMenuViewSendButtonDown {
    if (_delegate && [_delegate respondsToSelector:@selector(chatBoxFaceViewDeleteButtonDown)]) {
        [_delegate chatBoxFaceViewSendButtonDown];
    }
}



#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    //
    int page = scrollView.contentOffset.x / self.width;
    if (page > _curPage && (page * SCREEN_WIDTH - scrollView.contentOffset.x) < SCREEN_WIDTH * 0.2) {
        
        // 向右翻
        [self showFacePageAtIndex:page];
        
    } else if (page < _curPage && (scrollView.contentOffset.x - page * SCREEN_WIDTH) < SCREEN_WIDTH * 0.2) {
        [self showFacePageAtIndex:page];
    }
}


#pragma mark - Event Response
- (void)didSelectedFace:(UIButton *)sender {
    if (sender.tag == -1) {
        if (_delegate && [_delegate respondsToSelector:@selector(chatBoxFaceViewDeleteButtonDown)]) {
            [_delegate chatBoxFaceViewDeleteButtonDown];
        }
    } else {
        HCDChatFace *face = [_curGroup.facesArray objectAtIndex:sender.tag];
        if (_delegate && [_delegate respondsToSelector:@selector(chatBoxFaceViewDidSelectedFace:type:)]) {
            [_delegate chatBoxFaceViewDidSelectedFace:face type:_curGroup.faceType];
        }
    }
}

- (void)pageControlClicked:(UIPageControl *)pageControl {
    [self showFacePageAtIndex:pageControl.currentPage];
    [self.scrollView scrollRectToVisible:CGRectMake(pageControl.currentPage * SCREEN_WIDTH, 0, SCREEN_WIDTH, self.scrollView.height) animated:YES];
}

/**
 *  不同的组对应的pagecontrol 就是不同的，你点击了不同的组，就要重新加载该组的 pageControl和 scrollView
 *
 */
#pragma mark - Private Methods
- (void)reloadScrollView {
    /**
     *  这里是要计算表情要显示多少页，要不是自己添加的表情，就是一页 20  个这个样显示，要是自己添加的，就是 8 个显示。
     *  这里的 page  计算，有141个表情， /20 = 7   %20 = 1  7+1=8 就是8页。
     */
    int page = (int)(self.curGroup.facesArray.count / (self.curGroup.faceType == HCDFaceTypeEmoji ? 23 : 9));
    //看还有没有剩余 如果有y 还需要一页来显示
    int more = (int)(self.curGroup.facesArray.count % (self.curGroup.faceType == HCDFaceTypeEmoji ? 23 : 9));
    page += (more > 0 ? 1 : 0);
    [self.pageControl setNumberOfPages:page];
    // WIDTH_SCREEN 屏幕宽
    [self.scrollView setContentSize:CGSizeMake(SCREEN_WIDTH * page, self.scrollView.height)];
    [self.scrollView scrollRectToVisible:CGRectMake(0, 0, SCREEN_WIDTH, self.scrollView.height) animated:NO];
    _curPage = -1;
    [self showFacePageAtIndex:0];
}

- (void)showFacePageAtIndex:(NSUInteger)index {
    // 第一次进去 _curPage = -1  第二次 0  返回第一张 1  再回第二张 0
    if (index == _curPage) {
        return;
    }
    
    [self.pageControl setCurrentPage:index];
    int count = _curGroup.faceType == HCDFaceTypeEmoji ? 23 : 9;
    if (_curPage == -1) {
        HCDChatFaceItemView *pageView1 = [self.facePageViewArray objectAtIndex:0];
        [pageView1 showFaceGroup:_curGroup formIndex:0 count:0];
        [pageView1 setOrigin:CGPointMake(-SCREEN_WIDTH, 0)];

        HCDChatFaceItemView *pageView2 = [self.facePageViewArray objectAtIndex:1];
        [pageView2 showFaceGroup:_curGroup formIndex:0 count:count];
        [pageView2 setOrigin:CGPointMake(0, 0)];
        
        HCDChatFaceItemView *pageView3 = [self.facePageViewArray objectAtIndex:2];
        [pageView3 showFaceGroup:_curGroup formIndex:count count:count];
        [pageView3 setOrigin:CGPointMake(SCREEN_WIDTH, 0)];
        
    } else {
        if (_curPage < index) {
            HCDChatFaceItemView *pageView1 = [self.facePageViewArray objectAtIndex:0];
            [pageView1 showFaceGroup:_curGroup formIndex:(int)(index + 1) * count count:count];
            [pageView1 setOrigin:CGPointMake((index + 1) * SCREEN_WIDTH, 0)];
            [self.facePageViewArray removeObjectAtIndex:0];
            [self.facePageViewArray addObject:pageView1];
        } else {
            HCDChatFaceItemView *pageView3 = [self.facePageViewArray objectAtIndex:2];
            [pageView3 showFaceGroup:_curGroup formIndex:(int)(index - 1) * count count:count];
            [pageView3 setOrigin:CGPointMake((index - 1) * SCREEN_WIDTH, 0)];
            [self.facePageViewArray removeObjectAtIndex:2];
            [self.facePageViewArray insertObject:pageView3 atIndex:0];
        }
    }
    _curPage = (int)index;
}

#pragma mark - Getter
- (UIView *)topLine {
    if (_topLine == nil) {
        _topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 0.5)];
        [_topLine setBackgroundColor:DEFAULT_LINE_GRAY_COLOR];
    }
    return _topLine;
}

- (HCDChatFaceMenuView *)faceMenuView {
    if (_faceMenuView == nil) {
        _faceMenuView = [[HCDChatFaceMenuView alloc] initWithFrame:CGRectMake(0, self.height - HEIGHT_BOTTOM_VIEW - (isFullScreen() ? 39 : 0), SCREEN_WIDTH, HEIGHT_BOTTOM_VIEW)];
        [_faceMenuView setDelegate:self];
    }
    return _faceMenuView;
}

- (UIPageControl *)pageControl {
    if (_pageControl == nil) {
        _pageControl = [[UIPageControl alloc] init];
        _pageControl.currentPageIndicatorTintColor = [UIColor grayColor];
        _pageControl.pageIndicatorTintColor = DEFAULT_LINE_GRAY_COLOR;
        [_pageControl addTarget:self action:@selector(pageControlClicked:) forControlEvents:UIControlEventValueChanged];
    }
    return _pageControl;
}

- (UIScrollView *)scrollView {
    if (_scrollView == nil) {
        _scrollView = [[UIScrollView alloc] init];
        [_scrollView setScrollsToTop:NO];
        [_scrollView setShowsHorizontalScrollIndicator:NO];
        [_scrollView setShowsVerticalScrollIndicator:NO];
        [_scrollView setDelegate:self];
        [_scrollView setPagingEnabled:YES];
        _scrollView.backgroundColor = DEFAULT_SCROLLVIEW_COLOR;
        
    }
    return _scrollView;
}

- (NSMutableArray *)facePageViewArray {
    if (_facePageViewArray == nil) {
        _facePageViewArray = [[NSMutableArray alloc] initWithCapacity:3];
        for (int i = 0; i < 3; i ++) {
            HCDChatFaceItemView *view = [[HCDChatFaceItemView alloc] initWithFrame:self.scrollView.bounds];
            [_facePageViewArray addObject:view];
            [view addTarget:self action:@selector(didSelectedFace:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    return _facePageViewArray;
}

@end
