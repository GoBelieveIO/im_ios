//
//  MessageAudioView.h
//  Message
//
//  Created by 杨朋亮 on 14-9-10.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import "BubbleView.h"
#import <AVFoundation/AVFoundation.h>
#import "IMessage.h"

#define kAudioViewCellHeight 58 

@interface MessageAudioView : BubbleView <AVAudioPlayerDelegate>

@property (nonatomic, strong) UIButton *playBtn;
@property (nonatomic, strong) UIButton *microPhoneBtn;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UILabel *timeLengthLabel;
@property (nonatomic, strong) UILabel *createTimeLabel;


@property (nonatomic ,strong) IMessage *msg;

-(void)initializeWithMsg:(IMessage *)msg withType:(BubbleMessageType)type withMsgStateType:(BubbleMessageReceiveStateType)stateType;

-(void)setPlaying:(BOOL)playing;
-(void)setDownloading:(BOOL)downloading;
-(void)setUploading:(BOOL)uploading;
-(void)setListened;

@end
