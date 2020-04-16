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

#import "EaseRecordView.h"
//#import "EMCDDeviceManager.h"

@interface EaseRecordView ()
{
    // 显示动画的ImageView
    UIImageView *_recordAnimationView;
    // 提示文字
    UILabel *_textLabel;
    
    // 倒计时
    UILabel *_countdownLabel;
}

@end

@implementation EaseRecordView

+ (void)initialize
{
    // UIAppearance Proxy Defaults
    EaseRecordView *recordView = [self appearance];
    recordView.voiceMessageAnimationImages = @[@"VoiceSearchFeedback001",@"VoiceSearchFeedback002",@"VoiceSearchFeedback003",@"VoiceSearchFeedback004",@"VoiceSearchFeedback005",@"VoiceSearchFeedback006",@"VoiceSearchFeedback007",@"VoiceSearchFeedback008",@"VoiceSearchFeedback009",@"VoiceSearchFeedback010",@"VoiceSearchFeedback011",@"VoiceSearchFeedback012",@"VoiceSearchFeedback013",@"VoiceSearchFeedback014",@"VoiceSearchFeedback015",@"VoiceSearchFeedback016",@"VoiceSearchFeedback017",@"VoiceSearchFeedback018",@"VoiceSearchFeedback019",@"VoiceSearchFeedback020"];
    recordView.upCancelText = NSLocalizedString(@"message.toolBar.record.upCancel", @"Fingers up slide, cancel sending");
    recordView.loosenCancelText = NSLocalizedString(@"message.toolBar.record.loosenCancel", @"loosen the fingers, to cancel sending");
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        UIView *bgView = [[UIView alloc] initWithFrame:self.bounds];
        bgView.backgroundColor = [UIColor grayColor];
        bgView.layer.cornerRadius = 5;
        bgView.layer.masksToBounds = YES;
        bgView.alpha = 0.6;
        [self addSubview:bgView];
        
        _recordAnimationView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 0, self.bounds.size.width - 20, self.bounds.size.height - 30)];
        _recordAnimationView.image = [UIImage imageNamed:@"VoiceSearchFeedback001"];
        _recordAnimationView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_recordAnimationView];
        
        _textLabel = [[UILabel alloc] initWithFrame:CGRectMake(5,
                                                               self.bounds.size.height - 30,
                                                               self.bounds.size.width - 10,
                                                               25)];
        
        _textLabel.textAlignment = NSTextAlignmentCenter;
        _textLabel.backgroundColor = [UIColor clearColor];
        _textLabel.text = NSLocalizedString(@"message.toolBar.record.upCancel", @"Fingers up slide, cancel sending");
        [self addSubview:_textLabel];
        _textLabel.font = [UIFont systemFontOfSize:13];
        _textLabel.textColor = [UIColor whiteColor];
        _textLabel.layer.cornerRadius = 5;
        _textLabel.layer.borderColor = [[UIColor redColor] colorWithAlphaComponent:0.5].CGColor;
        _textLabel.layer.masksToBounds = YES;
        
        CGRect rect = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height-30);
        _countdownLabel = [[UILabel alloc] initWithFrame:rect];
        _countdownLabel.textAlignment = NSTextAlignmentCenter;
        _countdownLabel.hidden = YES;
        _countdownLabel.font = [UIFont systemFontOfSize:32];
        _countdownLabel.textColor = [UIColor whiteColor];
        [self addSubview:_countdownLabel];
    }
    return self;
}

#pragma mark - setter
- (void)setVoiceMessageAnimationImages:(NSArray *)voiceMessageAnimationImages
{
    _voiceMessageAnimationImages = voiceMessageAnimationImages;
}

- (void)setUpCancelText:(NSString *)upCancelText
{
    _upCancelText = upCancelText;
    _textLabel.text = _upCancelText;
}

- (void)setLoosenCancelText:(NSString *)loosenCancelText
{
    _loosenCancelText = loosenCancelText;
}

// 录音按钮按下
-(void)recordButtonTouchDown
{
    // 需要根据声音大小切换recordView动画
    _textLabel.text = _upCancelText;
    _textLabel.backgroundColor = [UIColor clearColor];
    
    _countdownLabel.hidden = YES;
    _recordAnimationView.hidden = NO;
}

// 手指在录音按钮内部时离开
-(void)recordButtonTouchUpInside
{

}
// 手指在录音按钮外部时离开
-(void)recordButtonTouchUpOutside
{
}
// 手指移动到录音按钮内部
-(void)recordButtonDragInside
{
    _textLabel.text = _upCancelText;
    _textLabel.backgroundColor = [UIColor clearColor];
}

// 手指移动到录音按钮外部
-(void)recordButtonDragOutside
{
    _textLabel.text = _loosenCancelText;
    _textLabel.backgroundColor = [UIColor redColor];
}

-(void)setCountdown:(int)countdown {
    _countdownLabel.text = [NSString stringWithFormat:@"%d", countdown];
    _countdownLabel.hidden = NO;
    _recordAnimationView.hidden = YES;
}

-(void)setVoiceImage:(double)voiceMeter {
    _recordAnimationView.image = [UIImage imageNamed:[_voiceMessageAnimationImages objectAtIndex:0]];
    double voiceSound = voiceMeter;
    int index = voiceSound*[_voiceMessageAnimationImages count];
    if (index >= [_voiceMessageAnimationImages count]) {
        _recordAnimationView.image = [UIImage imageNamed:[_voiceMessageAnimationImages lastObject]];
    } else {
        _recordAnimationView.image = [UIImage imageNamed:[_voiceMessageAnimationImages objectAtIndex:index]];
    }
}

@end
