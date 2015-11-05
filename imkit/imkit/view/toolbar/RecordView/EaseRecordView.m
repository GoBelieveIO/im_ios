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
    NSTimer *_timer;
    // 显示动画的ImageView
    UIImageView *_recordAnimationView;
    // 提示文字
    UILabel *_textLabel;
}

@end

@implementation EaseRecordView

+ (void)initialize
{
    // UIAppearance Proxy Defaults
    EaseRecordView *recordView = [self appearance];
    recordView.voiceMessageAnimationImages = @[@"imkitResource.bundle/VoiceSearchFeedback001",@"imkitResource.bundle/VoiceSearchFeedback002",@"imkitResource.bundle/VoiceSearchFeedback003",@"imkitResource.bundle/VoiceSearchFeedback004",@"imkitResource.bundle/VoiceSearchFeedback005",@"imkitResource.bundle/VoiceSearchFeedback006",@"imkitResource.bundle/VoiceSearchFeedback007",@"imkitResource.bundle/VoiceSearchFeedback008",@"imkitResource.bundle/VoiceSearchFeedback009",@"imkitResource.bundle/VoiceSearchFeedback010",@"imkitResource.bundle/VoiceSearchFeedback011",@"imkitResource.bundle/VoiceSearchFeedback012",@"imkitResource.bundle/VoiceSearchFeedback013",@"imkitResource.bundle/VoiceSearchFeedback014",@"imkitResource.bundle/VoiceSearchFeedback015",@"imkitResource.bundle/VoiceSearchFeedback016",@"imkitResource.bundle/VoiceSearchFeedback017",@"imkitResource.bundle/VoiceSearchFeedback018",@"imkitResource.bundle/VoiceSearchFeedback019",@"imkitResource.bundle/VoiceSearchFeedback020"];
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
        _recordAnimationView.image = [UIImage imageNamed:@"imkitResource.bundle/VoiceSearchFeedback001"];
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
    /*
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.05
                                              target:self
                                            selector:@selector(setVoiceImage)
                                            userInfo:nil
                                             repeats:YES];*/
    
}
// 手指在录音按钮内部时离开
-(void)recordButtonTouchUpInside
{
//    [_timer invalidate];
}
// 手指在录音按钮外部时离开
-(void)recordButtonTouchUpOutside
{
//    [_timer invalidate];
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




-(void)setVoiceImage:(double)voiceMeter {
    _recordAnimationView.image = [UIImage imageNamed:[_voiceMessageAnimationImages objectAtIndex:0]];
    double voiceSound = voiceMeter;
    int index = voiceSound*[_voiceMessageAnimationImages count];
    if (index >= [_voiceMessageAnimationImages count]) {
        _recordAnimationView.image = [UIImage imageNamed:[_voiceMessageAnimationImages lastObject]];
    } else {
        _recordAnimationView.image = [UIImage imageNamed:[_voiceMessageAnimationImages objectAtIndex:index]];
    }
    
    /*
    if (0 < voiceSound <= 0.05) {
        [_recordAnimationView setImage:[UIImage imageNamed:@"imkitResource.bundle/imkitResource.bundle/VoiceSearchFeedback001"]];
    }else if (0.05<voiceSound<=0.10) {
        [_recordAnimationView setImage:[UIImage imageNamed:@"imkitResource.bundle/imkitResource.bundle/VoiceSearchFeedback002"]];
    }else if (0.10<voiceSound<=0.15) {
        [_recordAnimationView setImage:[UIImage imageNamed:@"imkitResource.bundle/imkitResource.bundle/VoiceSearchFeedback003"]];
    }else if (0.15<voiceSound<=0.20) {
        [_recordAnimationView setImage:[UIImage imageNamed:@"imkitResource.bundle/imkitResource.bundle/VoiceSearchFeedback004"]];
    }else if (0.20<voiceSound<=0.25) {
        [_recordAnimationView setImage:[UIImage imageNamed:@"imkitResource.bundle/imkitResource.bundle/VoiceSearchFeedback005"]];
    }else if (0.25<voiceSound<=0.30) {
        [_recordAnimationView setImage:[UIImage imageNamed:@"imkitResource.bundle/imkitResource.bundle/VoiceSearchFeedback006"]];
    }else if (0.30<voiceSound<=0.35) {
        [_recordAnimationView setImage:[UIImage imageNamed:@"imkitResource.bundle/imkitResource.bundle/VoiceSearchFeedback007"]];
    }else if (0.35<voiceSound<=0.40) {
        [_recordAnimationView setImage:[UIImage imageNamed:@"imkitResource.bundle/imkitResource.bundle/VoiceSearchFeedback008"]];
    }else if (0.40<voiceSound<=0.45) {
        [_recordAnimationView setImage:[UIImage imageNamed:@"imkitResource.bundle/imkitResource.bundle/VoiceSearchFeedback009"]];
    }else if (0.45<voiceSound<=0.50) {
        [_recordAnimationView setImage:[UIImage imageNamed:@"imkitResource.bundle/imkitResource.bundle/VoiceSearchFeedback010"]];
    }else if (0.50<voiceSound<=0.55) {
        [_recordAnimationView setImage:[UIImage imageNamed:@"imkitResource.bundle/imkitResource.bundle/VoiceSearchFeedback011"]];
    }else if (0.55<voiceSound<=0.60) {
        [_recordAnimationView setImage:[UIImage imageNamed:@"imkitResource.bundle/imkitResource.bundle/VoiceSearchFeedback012"]];
    }else if (0.60<voiceSound<=0.65) {
        [_recordAnimationView setImage:[UIImage imageNamed:@"imkitResource.bundle/imkitResource.bundle/VoiceSearchFeedback013"]];
    }else if (0.65<voiceSound<=0.70) {
        [_recordAnimationView setImage:[UIImage imageNamed:@"imkitResource.bundle/imkitResource.bundle/VoiceSearchFeedback014"]];
    }else if (0.70<voiceSound<=0.75) {
        [_recordAnimationView setImage:[UIImage imageNamed:@"imkitResource.bundle/imkitResource.bundle/VoiceSearchFeedback015"]];
    }else if (0.75<voiceSound<=0.80) {
        [_recordAnimationView setImage:[UIImage imageNamed:@"imkitResource.bundle/imkitResource.bundle/VoiceSearchFeedback016"]];
    }else if (0.80<voiceSound<=0.85) {
        [_recordAnimationView setImage:[UIImage imageNamed:@"imkitResource.bundle/imkitResource.bundle/VoiceSearchFeedback017"]];
    }else if (0.85<voiceSound<=0.90) {
        [_recordAnimationView setImage:[UIImage imageNamed:@"imkitResource.bundle/imkitResource.bundle/VoiceSearchFeedback018"]];
    }else if (0.90<voiceSound<=0.95) {
        [_recordAnimationView setImage:[UIImage imageNamed:@"imkitResource.bundle/imkitResource.bundle/VoiceSearchFeedback019"]];
    }else {
        [_recordAnimationView setImage:[UIImage imageNamed:@"imkitResource.bundle/imkitResource.bundle/VoiceSearchFeedback020"]];
    }*/
}

@end
