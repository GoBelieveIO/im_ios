/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "MessageViewController.h"
#import "IMService.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <SDWebImage/UIImageView+WebCache.h>

#import "FileCache.h"
#import "AudioDownloader.h"

#import "MessageTextView.h"
#import "MessageAudioView.h"
#import "MessageImageView.h"
#import "MessageLocationView.h"
#import "MessageLinkView.h"
#import "MessageNotificationView.h"
#import "MessageVOIPView.h"
#import "MessageUnknownView.h"
#import "MessageViewCell.h"
#import "MessageNotificationCell.h"
#import "OutMessageCell.h"
#import "InMessageCell.h"

#import "KILabel.h"
#import "MEESImageViewController.h"
#import "NSString+JSMessagesView.h"
#import "UIImage+Resize.h"
#import "UIView+Toast.h"
#import "MapViewController.h"
#import "LocationPickerController.h"
#import "WebViewController.h"
#import "OverlayViewController.h"

#import "EaseChatToolbar.h"
#import "EaseEmoji.h"
#import "EaseEmotionManager.h"

#define INPUT_HEIGHT 52.0f

#define kTakePicActionSheetTag  101

//应用启动时间
static int uptime = 0;

@interface MessageViewController()<LocationPickerControllerDelegate, EMChatToolbarDelegate>

@property(strong, nonatomic) EaseChatToolbar *chatToolbar;

@property(strong, nonatomic) EaseChatBarMoreView *chatBarMoreView;

@property(strong, nonatomic) EaseFaceView *faceView;

@property(strong, nonatomic) EaseRecordView *recordView;

@property (nonatomic,strong) UIImage *willSendImage;
@property (nonatomic) int  inputTimestamp;

@property(nonatomic) IMessage *playingMessage;
@property(nonatomic) AVAudioPlayer *player;
@property(nonatomic) NSTimer *playTimer;

@property(nonatomic) AVAudioRecorder *recorder;
@property(nonatomic) NSTimer *recordingTimer;
@property(nonatomic) NSTimer *updateMeterTimer;
@property(nonatomic, assign) int seconds;
@property(nonatomic) BOOL recordCanceled;

@property(nonatomic) IMessage *selectedMessage;
@property(nonatomic, weak) MessageViewCell *selectedCell;

@property(nonatomic) BOOL firstAppeared;

- (void)setup;

- (void)pullToRefresh;

- (void)AudioAction:(UIButton*)btn;
- (void)handleTapImageView:(UITapGestureRecognizer*)tap;
- (void)handleLongPress:(UILongPressGestureRecognizer *)longPress;

@end

@implementation MessageViewController

+(void)load {
    uptime = (int)time(NULL);
}

- (id)init {
    if (self = [super init]) {

    }
    return self;
}


#pragma mark - View lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.firstAppeared = NO;
    self.hasLateMore = self.messageID > 0 ;
    self.hasEarlierMore = YES;
    
    [self loadConversationData];
    [self setup];
    
    [self addObserver];

    self.tableView.estimatedRowHeight = 0;
    [self.tableView reloadData];
    if (self.messageID > 0) {
        NSInteger index = [self.messages indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            IMessage *m = (IMessage*)obj;
            if (m.msgLocalID == self.messageID) {
                *stop = YES;
                return YES;
            }
            return NO;
        }];
        
        if (index != NSNotFound) {
            CGFloat middle = self.tableView.bounds.size.height/2;
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            CGRect r = [self.tableView rectForRowAtIndexPath:indexPath];
            CGFloat offset = r.origin.y - middle;
            if ((offset + self.tableView.bounds.size.height) > self.tableView.contentSize.height) {
                [self.tableView setContentOffset:CGPointMake(0, CGFLOAT_MAX)];
            } else {
                [self.tableView setContentOffset:CGPointMake(0, offset)];
            }
        }
    } else {
        //scroll tableview to bottom
        [self.tableView setContentOffset:CGPointMake(0, CGFLOAT_MAX)];
    }
}

#pragma mark - View lifecycle
-(void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    if (!self.firstAppeared && self.messageID > 0) {
        NSInteger index = [self.messages indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            IMessage *m = (IMessage*)obj;
            if (m.msgLocalID == self.messageID) {
                *stop = YES;
                return YES;
            }
            return NO;
        }];
        
        if (index != NSNotFound) {
            CGFloat middle = self.tableView.bounds.size.height/2;
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            CGRect r = [self.tableView rectForRowAtIndexPath:indexPath];
            CGFloat offset = r.origin.y - middle;
            if ((offset + self.tableView.bounds.size.height) > self.tableView.contentSize.height) {
                [self.tableView setContentOffset:CGPointMake(0, CGFLOAT_MAX)];
            } else {
                [self.tableView setContentOffset:CGPointMake(0, offset)];
            }
        }
    }
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.firstAppeared = YES;
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (!self.navigationController || [self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
        [self onBack];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)setup {
    int w = self.view.bounds.size.width;
    int h = self.view.bounds.size.height;

    CGRect tableFrame = CGRectMake(0.0f, 0, w, h - [EaseChatToolbar defaultHeight]);
    
    self.view.backgroundColor = RGBACOLOR(235, 235, 235, 1);

	self.tableView = [[UITableView alloc] initWithFrame:tableFrame style:UITableViewStylePlain];
	self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    
    UIView *refreshView = [[UIView alloc] initWithFrame:CGRectMake(0, 55, 0, 0)];
    self.tableView.tableHeaderView = refreshView;
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(pullToRefresh) forControlEvents:UIControlEventValueChanged];
    [refreshView addSubview:self.refreshControl];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
	[self.view addSubview:self.tableView];
    
    //初始化页面
    CGFloat chatbarHeight = [EaseChatToolbar defaultHeight];
    EMChatToolbarType barType = EMChatToolbarTypeChat;
    self.chatToolbar = [[EaseChatToolbar alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - chatbarHeight, self.view.frame.size.width, chatbarHeight) type:barType];
    [(EaseChatToolbar *)self.chatToolbar setDelegate:self];
    self.chatBarMoreView = (EaseChatBarMoreView*)[(EaseChatToolbar *)self.chatToolbar moreView];
    self.faceView = (EaseFaceView*)[(EaseChatToolbar *)self.chatToolbar faceView];
    self.recordView = (EaseRecordView*)[(EaseChatToolbar *)self.chatToolbar recordView];
    self.chatToolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:self.chatToolbar];
    self.inputBar = self.chatToolbar;
    
    EaseEmotionManager *manager= [[EaseEmotionManager alloc] initWithType:EMEmotionDefault emotionRow:3 emotionCol:7 emotions:[EaseEmoji allEmoji]];
    [self.faceView setEmotionManagers:@[manager]];
    
    if ([[IMService instance] connectState] == STATE_CONNECTED) {
        [self enableSend];
    } else {
        [self disableSend];
    }
  
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
    [self.tableView addGestureRecognizer:tapRecognizer];
    tapRecognizer.numberOfTapsRequired = 1;
    tapRecognizer.delegate  = self;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMenuWillShowNotification:)
                                                 name:UIMenuControllerWillShowMenuNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMenuWillHideNotification:)
                                                 name:UIMenuControllerWillHideMenuNotification
                                               object:nil];
}

-(void)addObserver {
    [[AudioDownloader instance] addDownloaderObserver:self];
}

-(void)removeObserver {
    [[AudioDownloader instance] removeDownloaderObserver:self];
}

- (void)loadConversationData {
    NSArray *messages;
    if (self.messageID > 0) {
        messages = [self.messageDB loadConversationData:self.messageID];
    } else {
        messages = [self.messageDB loadConversationData];
    }
    
    if (messages.count == 0) {
        return;
    }
    //去掉重复的消息
    NSMutableSet *uuidSet = [NSMutableSet set];
    for (NSInteger i = 0; i < messages.count; i++) {
        IMessage *msg = [messages objectAtIndex:i];
        if (msg.uuid.length > 0 && [uuidSet containsObject:msg.uuid]) {
            continue;
        }
        
        [self.messages addObject:msg];
        if (msg.uuid.length > 0) {
            [uuidSet addObject:msg.uuid];
        }
    }
    
    int count = (int)self.messages.count;
    [self downloadMessageContent:self.messages count:count];
    [self updateNotificationDesc:self.messages count:count];
    [self checkMessageFailureFlag:self.messages count:count];
    [self loadSenderInfo:self.messages count:count];
    [self checkMessageFailureFlag:self.messages count:count];
    
    [self initTableViewData];
}


- (void)loadEarlierData {
    if (!self.hasEarlierMore) {
        return;
    }
    //找出第一条实体消息
    IMessage *last = nil;
    for (NSInteger i = 0; i < self.messages.count; i++) {
        IMessage *m = [self.messages objectAtIndex:i];
        if (m.type != MESSAGE_TIME_BASE) {
            last = m;
            break;
        }
    }
    if (last == nil) {
        return;
    }
    
    NSMutableSet *uuidSet = [NSMutableSet set];
    for (IMessage *msg in self.messages) {
        if (msg.uuid.length > 0) {
            [uuidSet addObject:msg.uuid];
        }
    }
    
    NSArray *newMessages = [self.messageDB loadEarlierData:last.msgLocalID];
    if (newMessages.count == 0) {
        self.hasEarlierMore = NO;
        return;
    }
    NSLog(@"load earlier messages:%zd", newMessages.count);

    //过滤掉重复的消息
    int count = 0;
    for (NSInteger i = newMessages.count - 1; i >= 0; i--) {
        IMessage *msg = [newMessages objectAtIndex:i];
        if (msg.uuid.length > 0 && [uuidSet containsObject:msg.uuid]) {
            continue;
        }
        
        count++;
        [self.messages insertObject:msg atIndex:0];
        if (msg.uuid.length > 0) {
            [uuidSet addObject:msg.uuid];
        }
    }

    
    [self loadSenderInfo:self.messages count:count];
    [self downloadMessageContent:self.messages count:count];
    [self updateNotificationDesc:self.messages count:count];
    [self checkMessageFailureFlag:self.messages count:count];
    
    [self initTableViewData];
    [self.tableView reloadData];
    
    int c = 0;
    int section = 0;
    int row = 0;
    for (NSInteger i = 0; i < self.messages.count; i++) {
        row++;
        IMessage *m = [self.messages objectAtIndex:i];
        if (m.type == MESSAGE_TIME_BASE) {
            continue;
        }
        c++;
        if (c >= count) {
            break;
        }
    }
    NSLog(@"scroll to row:%d section:%d", row, section);
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
}

//加载后面的聊天记录
-(void)loadLateData {
    if (!self.hasLateMore || self.messages.count == 0) {
        return;
    }
    int messageID = 0;
    for (NSInteger i = self.messages.count - 1; i > 0; i--) {
        IMessage *msg = [self.messages objectAtIndex:i];
        if (msg.msgLocalID) {
            messageID = msg.msgLocalID;
            break;
        }
    }
    
    if (messageID == 0) {
        return;
    }
    
    NSArray *newMessages = [self.messageDB loadLateData:messageID];

    if (newMessages.count == 0) {
        self.hasLateMore = NO;
        return;
    }

    //过滤掉重复的消息
    NSMutableArray *tmpMessages = [NSMutableArray array];
    int count = 0;
    NSMutableSet *uuidSet = [NSMutableSet set];
    for (IMessage *msg in newMessages) {
        if (msg.uuid.length > 0 && [uuidSet containsObject:msg.uuid]) {
            continue;
        }
        count++;
        [tmpMessages addObject:msg];
        if (msg.uuid.length > 0) {
            [uuidSet addObject:msg.uuid];
        }
    }
    newMessages = tmpMessages;
    
    NSLog(@"load late messages:%d", count);
    [self loadSenderInfo:newMessages count:count];
    [self downloadMessageContent:newMessages count:count];
    [self updateNotificationDesc:newMessages count:count];
    [self checkMessageFailureFlag:newMessages count:count];
    
    [self insertMessages:newMessages];
}


- (void)onBack {
    [self stopPlayer];
    [self removeObserver];
}

- (void)setDraft:(NSString *)draft {
    if (draft.length > 0) {
        [self.chatToolbar setText:draft];
    }
}

- (NSString*)getDraft {
    NSString *draft = self.chatToolbar.inputTextView.text;
    if (!draft) {
        draft = @"";
    }
    return draft;
}




#pragma mark -
- (void) handlePanFrom:(UITapGestureRecognizer*)recognizer{
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self.chatToolbar endEditing:YES];
    }
}

#pragma mark - Actions
- (void)updateMeter:(NSTimer*)timer {
    double voiceMeter = 0;
    if ([self.recorder isRecording]) {
        [self.recorder updateMeters];
        //获取音量的平均值  [recorder averagePowerForChannel:0];
        //音量的最大值  [recorder peakPowerForChannel:0];
        double lowPassResults = pow(10, (0.05 * [self.recorder peakPowerForChannel:0]));
        voiceMeter = lowPassResults;
    }
    [self.recordView setVoiceImage:voiceMeter];
}

- (void)timerFired:(NSTimer*)timer {
    self.seconds = self.seconds + 1;
    int minute = self.seconds/60;
    int s = self.seconds%60;
    NSString *str = [NSString stringWithFormat:@"%02d:%02d", minute, s];
    NSLog(@"timer:%@", str);
    int countdown = 60 - self.seconds;
    if (countdown <= 10) {
        [self.recordView setCountdown:countdown];
    }
    if (countdown <= 0) {
        [self.recordView removeFromSuperview];
        [self recordEnd];
    }
}

- (void)pullToRefresh {
    NSLog(@"pull to refresh...");
    [self.refreshControl endRefreshing];
    [self loadEarlierData];
}

- (void)startRecord {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryRecord error:nil];
    BOOL r = [session setActive:YES error:nil];
    if (!r) {
        NSLog(@"activate audio session fail");
        return;
    }
    NSLog(@"start record...");
    
    NSArray *pathComponents = [NSArray arrayWithObjects:
                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               @"MyAudioMemo.wav",
                               nil];
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    
    // Define the recorder setting
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:8000] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt:2] forKey:AVNumberOfChannelsKey];
    
    self.recorder = [[AVAudioRecorder alloc] initWithURL:outputFileURL settings:recordSetting error:NULL];
    self.recorder.delegate = self;
    self.recorder.meteringEnabled = YES;
    if (![self.recorder prepareToRecord]) {
        NSLog(@"prepare record fail");
        return;
    }
    if (![self.recorder record]) {
        NSLog(@"start record fail");
        return;
    }
    
    
    self.recordCanceled = NO;
    self.seconds = 0;
    self.recordingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
    
    self.updateMeterTimer = [NSTimer scheduledTimerWithTimeInterval:0.05
                                              target:self
                                            selector:@selector(updateMeter:)
                                            userInfo:nil
                                             repeats:YES];
}

-(void)stopRecord {
    [self.recorder stop];
    [self.recordingTimer invalidate];
    self.recordingTimer = nil;
    [self.updateMeterTimer invalidate];
    self.updateMeterTimer = nil;

    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    BOOL r = [audioSession setActive:NO error:nil];
    if (!r) {
        NSLog(@"deactivate audio session fail");
    }
}


#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return YES;
}


#pragma mark - menu notification
- (void)handleMenuWillHideNotification:(NSNotification *)notification
{
    self.selectedCell.selectedToShowCopyMenu = NO;
    self.selectedCell = nil;
    self.selectedMessage = nil;
}

- (void)handleMenuWillShowNotification:(NSNotification *)notification
{
    self.selectedCell.selectedToShowCopyMenu = YES;
}


#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    NSLog(@"player finished");
    self.playingMessage.progress = 0;
    self.playingMessage.playing = NO;
    self.playingMessage = nil;
    if ([self.playTimer isValid]) {
        [self.playTimer invalidate];
        self.playTimer = nil;
    }
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    NSLog(@"player decode error");
    self.playingMessage.progress = 0;
    self.playingMessage.playing = NO;
    self.playingMessage = nil;
    
    if ([self.playTimer isValid]) {
        [self.playTimer invalidate];
        self.playTimer = nil;
    }
}

#pragma mark - AVAudioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    NSLog(@"record finish:%d", flag);
    if (!flag) {
        return;
    }
    if (self.recordCanceled) {
        return;
    }
    if (self.seconds < 1) {
        NSLog(@"record time too short");
        [self.view makeToast:@"录音时间太短了" duration:0.7 position:@"bottom"];
        return;
    }
    
    [self sendAudioMessage:[recorder.url path] second:self.seconds];
}

- (void)disableSend {
    self.chatToolbar.userInteractionEnabled = NO;
}

- (void)enableSend {
    self.chatToolbar.userInteractionEnabled = YES;
}

- (void)updateSlider {
    self.playingMessage.progress = 100*self.player.currentTime/self.player.duration;
}

- (void)stopPlayer {
    if (self.player && [self.player isPlaying]) {
        [self.player stop];
        if ([self.playTimer isValid]) {
            [self.playTimer invalidate];
            self.playTimer = nil;
        }
        self.playingMessage.progress = 0;
        self.playingMessage.playing = NO;
        self.playingMessage = nil;
    }
}

-(void)AudioAction:(UIButton*)btn{
    int row = btn.tag & 0xffff;
    int section = (int)(btn.tag >> 16);
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    IMessage *message = [self messageForRowAtIndexPath:indexPath];
    if (message == nil) {
        return;
    }

    if (self.playingMessage != nil && self.playingMessage.msgLocalID == message.msgLocalID) {
        [self stopPlayer];
    } else {
        [self stopPlayer];

        FileCache *fileCache = [FileCache instance];
        MessageAudioContent *content = message.audioContent;
        NSString *url = content.url;
        NSString *path = [fileCache queryCacheForKey:url];
        if (path != nil) {
            if (!message.isListened) {
                message.flags |= MESSAGE_FLAG_LISTENED;
                [self markMesageListened:message];
            }

            message.progress = 0;
            message.playing = YES;
            
            // Setup audio session
            AVAudioSession *session = [AVAudioSession sharedInstance];
            [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
            
            //设置为与当前音频播放同步的Timer
            self.playTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateSlider) userInfo:nil repeats:YES];
            self.playingMessage = message;
            
            if (![[self class] isHeadphone]) {
                //打开外放
                [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker
                                           error:nil];
                
            }
            NSURL *u = [NSURL fileURLWithPath:path];
            self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:u error:nil];
            [self.player setDelegate:self];
            [self.player play];

        }
    }
}

-(void)handleMessageViewClick:(UITapGestureRecognizer*)tap {
    int row = tap.view.tag & 0xffff;
    int section = (int)(tap.view.tag >> 16);
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    IMessage *message = [self messageForRowAtIndexPath:indexPath];
    if (message == nil) {
        return;
    }
    
    if (message.type == MESSAGE_IMAGE) {
        [self handleTapImageView:tap];
    } else if (message.type == MESSAGE_LOCATION) {
        [self handleTapLocationView:tap];
    } else if (message.type == MESSAGE_LINK) {
        [self handleTapLinkView:tap];
    } else if (message.type == MESSAGE_VOIP) {
        [self handleTapVOIPView:tap];
    }
}

-(void)handleTextDoubleClick:(UITapGestureRecognizer*)tap {
    if (tap.state == UIGestureRecognizerStateRecognized) {
        NSLog(@"text double click");
    }
    
    int row = tap.view.tag & 0xffff;
    int section = (int)(tap.view.tag >> 16);
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    IMessage *message = [self messageForRowAtIndexPath:indexPath];
    if (message == nil) {
        return;
    }
    
    OverlayViewController *ctrl = [[OverlayViewController alloc] init];
    ctrl.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    ctrl.modalPresentationStyle = UIModalPresentationOverFullScreen;
    NSString *text = message.textContent.text;
    ctrl.text = text;
    
    [self presentViewController:ctrl animated:YES completion:^{
        
    }];
//    [OverlayLabel showText:text];
}

- (void) handleTapVOIPView:(UITapGestureRecognizer*)tap {
    int row = tap.view.tag & 0xffff;
    int section = (int)(tap.view.tag >> 16);
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    IMessage *message = [self messageForRowAtIndexPath:indexPath];
    if (message == nil) {
        return;
    }
    if (message.isOutgoing) {
        [self recall:message.voipContent.videoEnabled];
    }
}

- (void) handleTapImageView:(UITapGestureRecognizer*)tap {
    int row = tap.view.tag & 0xffff;
    int section = (int)(tap.view.tag >> 16);
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    IMessage *message = [self messageForRowAtIndexPath:indexPath];
    if (message == nil) {
        return;
    }
    MessageImageContent *content = message.imageContent;
    NSString *littleUrl = [content littleImageURL];
    
    if ([[SDImageCache sharedImageCache] diskImageExistsWithKey:content.imageURL]) {
        UIImage *cacheImg = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey: content.imageURL];
        MEESImageViewController * imgcontroller = [[MEESImageViewController alloc] init];
        [imgcontroller setImage:cacheImg];
        [imgcontroller setTappedThumbnail:tap.view];
        imgcontroller.isFullSize = YES;
        [self presentViewController:imgcontroller animated:YES completion:nil];
    } else if([[SDImageCache sharedImageCache] diskImageExistsWithKey:littleUrl]){
        UIImage *cacheImg = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey: littleUrl];
        MEESImageViewController * imgcontroller = [[MEESImageViewController alloc] init];
        [imgcontroller setImage:cacheImg];
        imgcontroller.isFullSize = NO;
        [imgcontroller setImgUrl:content.imageURL];
        [imgcontroller setTappedThumbnail:tap.view];
        [self presentViewController:imgcontroller animated:YES completion:nil];
    }
}

- (void) handleTapLinkView:(UITapGestureRecognizer*)tap {
    int row = tap.view.tag & 0xffff;
    int section = (int)(tap.view.tag >> 16);
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    IMessage *message = [self messageForRowAtIndexPath:indexPath];
    if (message == nil) {
        return;
    }
    
    NSLog(@"click link");
    
    WebViewController *ctl = [[WebViewController alloc] init];
    ctl.url = message.linkContent.url;
    [self.navigationController pushViewController:ctl animated:YES];
}

- (void) handleTapLocationView:(UITapGestureRecognizer*)tap {
    int row = tap.view.tag & 0xffff;
    int section = (int)(tap.view.tag >> 16);
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    IMessage *message = [self messageForRowAtIndexPath:indexPath];
    if (message == nil) {
        return;
    }
    
    MessageLocationContent *content = message.locationContent;
    MapViewController *ctl = [[MapViewController alloc] init];
    ctl.friendCoordinate = content.location;
    [self.navigationController pushViewController:ctl animated:YES];
}


#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    IMessage *message = [self messageForRowAtIndexPath:indexPath];
    if (message == nil) {
        return nil;
    }
    NSString *CellID = [self getMessageViewCellId:message];
    MessageViewCell *cell = (MessageViewCell *)[tableView dequeueReusableCellWithIdentifier:CellID];
    if(!cell) {
        if (message.notificationContent) {
           cell = [[MessageNotificationCell alloc] initWithType:message.type reuseIdentifier:CellID];
        } else if (message.isOutgoing) {
            cell = [[OutMessageCell alloc] initWithType:message.type reuseIdentifier:CellID];
        } else {
            InMessageCell *inCell = [[InMessageCell alloc] initWithType:message.type reuseIdentifier:CellID];
            inCell.showName = self.isShowUserName;
            cell = inCell;
        }
        
        if (message.type == MESSAGE_AUDIO) {
            MessageAudioView *audioView = (MessageAudioView*)cell.bubbleView;
            [audioView.playBtn addTarget:self action:@selector(AudioAction:) forControlEvents:UIControlEventTouchUpInside];
        } else if (message.type == MESSAGE_TEXT) {
            MessageTextView *textView = (MessageTextView*)cell.bubbleView;
            
            textView.label.urlLinkTapHandler = ^(KILabel *label, NSString *string, NSRange range) {
                NSLog(@"URL tapped %@", string);
                NSURL *url = [NSURL URLWithString:string];
                if (![[UIApplication sharedApplication] canOpenURL:url]) {
                    url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", string]];
                    if (![[UIApplication sharedApplication] canOpenURL:url]) {
                        NSLog(@"can't open url:%@", string);
                        return;
                    }
                }
                if ([[UIApplication sharedApplication] respondsToSelector:@selector(openURL:options:completionHandler:)]) {
                    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                }else{
                    [[UIApplication sharedApplication] openURL:url];
                }
            };
            
            UITapGestureRecognizer *tap  = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTextDoubleClick:)];
            tap.numberOfTapsRequired = 2;
            [textView.label addGestureRecognizer:tap];
            
            UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                     action:@selector(handleLongPress:)];
            [recognizer setMinimumPressDuration:0.4];
            [textView.label addGestureRecognizer:recognizer];
            
        } else {
            //todo listen only containerview
            UITapGestureRecognizer *tap0  = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleMessageViewClick:)];
            [tap0 setNumberOfTouchesRequired: 1];
            [cell.bubbleView addGestureRecognizer:tap0];
            
            UITapGestureRecognizer *tap  = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleMessageViewClick:)];
            [tap setNumberOfTouchesRequired: 1];
            [cell.containerView addGestureRecognizer:tap];
        }
        UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                 action:@selector(handleLongPress:)];
        [recognizer setMinimumPressDuration:0.4];
        [cell.containerView addGestureRecognizer:recognizer];
    }

    cell.msg = message;
    
    NSInteger tag = indexPath.section<<16 | indexPath.row;
    if (message.type == MESSAGE_AUDIO) {
        MessageAudioView *audioView = (MessageAudioView*)cell.bubbleView;
        audioView.playBtn.tag = tag;
    } else if (message.type == MESSAGE_TEXT) {
        MessageTextView *textView = (MessageTextView*)cell.bubbleView;
        textView.label.tag = tag;
    }

    cell.containerView.tag = tag;
    cell.bubbleView.tag = tag;
    cell.tag = tag;
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

#pragma mark -  UITableViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    UIEdgeInsets inset = scrollView.contentInset;
    CGFloat h = scrollView.bounds.size.height - inset.top - inset.bottom;
    CGFloat dis = scrollView.contentSize.height - (scrollView.contentOffset.y + h);
    if (dis < 100) {
        [self loadLateData];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    IMessage *msg = [self messageForRowAtIndexPath:indexPath];
    if (msg == nil) {
        NSLog(@"opps");
        return 0;
    }
    int nameHeight = 0;
    if (self.isShowUserName && msg.isIncomming) {
        nameHeight = NAME_LABEL_HEIGHT;
    }
    
    switch (msg.type) {
        case MESSAGE_TEXT:
            return [MessageViewCell cellHeightMessage:msg] + nameHeight;
        case  MESSAGE_IMAGE:
            return [MessageViewCell cellHeightMessage:msg] + nameHeight;
        case MESSAGE_AUDIO:
            return kMessageAudioViewHeight + nameHeight;
        case MESSAGE_LOCATION:
            return kMessageLocationViewHeight + nameHeight;
        case MESSAGE_HEADLINE:
        case MESSAGE_TIME_BASE:
        case MESSAGE_GROUP_NOTIFICATION:
        case MESSAGE_GROUP_VOIP:
            return kMessageNotificationViewHeight;
        case MESSAGE_LINK:
            return kMessageLinkViewHeight + nameHeight;
        case MESSAGE_VOIP:
            return kMessageVOIPViewHeight;
        default:
            return kMessageUnknowViewHeight + nameHeight;
    }
}


/*
 * 复用ID区分来去类型
 */
- (NSString*)getMessageViewCellId:(IMessage*)msg{
    if (msg.notificationContent) {
        return @"MessageCellNotification";
    } else if(msg.isOutgoing) {
        return [NSString stringWithFormat:@"MessageCell_%d%d", msg.type, 0];
    } else {
        return [NSString stringWithFormat:@"MessageCell_%d%d", msg.type, 1];
    }
}

- (void)didFinishSelectAddress:(CLLocationCoordinate2D)location address:(NSString *)address {
    [self sendLocationMessage:location address:address];
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	NSLog(@"Chose image!  Details:  %@", info);
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];

    [self sendImageMessage:image];
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - MessageInputRecordDelegate
- (void)recordStart {
    if (self.recorder.recording) {
        return;
    }
    
    [self stopPlayer];
    
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (granted) {
            [self startRecord];
        } else {
            [self.view makeToast:@"无法录音,请到设置-隐私-麦克风,允许程序访问"];
        }
    }];
}

- (void)recordCancel {
    NSLog(@"touch cancel");
    
    if (self.recorder.recording) {
        NSLog(@"cancel record...");
        self.recordCanceled = YES;
        [self stopRecord];
    }
}

- (void)recordCancel:(CGFloat)xMove {
    [self recordCancel];
}

-(void)recordEnd {
    if (self.recorder.recording) {
        NSLog(@"stop record...");
        self.recordCanceled = NO;
        [self stopRecord];
    }
}

- (void)resend:(id)sender {
    [self resignFirstResponder];
    
    NSLog(@"resend...");
    if (self.selectedMessage == nil) {
        return;
    }
    
    IMessage *message = self.selectedMessage;
    [self resendMessage:message];
}

- (void)copyText:(id)sender {
    if (self.selectedMessage.type != MESSAGE_TEXT) {
        return;
    }
    NSLog(@"copy...");

    MessageTextContent *content = self.selectedMessage.textContent;
    [[UIPasteboard generalPasteboard] setString:content.text];
    [self resignFirstResponder];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

#pragma mark - Gestures
- (void)handleLongPress:(UILongPressGestureRecognizer *)longPress {
    int row = longPress.view.tag & 0xffff;
    int section = (int)(longPress.view.tag >> 16);
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    IMessage *message = [self messageForRowAtIndexPath:indexPath];
    if (message == nil) {
        return;
    }
    MessageViewCell *cell = (MessageViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    
    if(longPress.state != UIGestureRecognizerStateBegan
       || ![self becomeFirstResponder])
        return;
   
    NSMutableArray *menuItems = [NSMutableArray array];
    if (message.type == MESSAGE_TEXT) {
        UIMenuItem *item = [[UIMenuItem alloc] initWithTitle:@"拷贝" action:@selector(copyText:)];
        [menuItems addObject:item];
    }
    if (message.isFailure) {
        UIMenuItem *item = [[UIMenuItem alloc] initWithTitle:@"重发" action:@selector(resend:)];
        [menuItems addObject:item];
    }
    if ([menuItems count] == 0) {
        return;
    }
    
    self.selectedMessage = message;
    self.selectedCell = cell;

    UIMenuController *menu = [UIMenuController sharedMenuController];
    menu.menuItems = menuItems;
    CGRect targetRect = [cell convertRect:longPress.view.frame
                                 fromView:cell.bubbleView];
    [menu setTargetRect:CGRectInset(targetRect, 0.0f, 4.0f) inView:cell];

    [menu setMenuVisible:YES animated:YES];
}


+ (BOOL)isHeadphone {
    AVAudioSessionRouteDescription* route = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription* desc in [route outputs]) {
        if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones])
            return YES;
    }
    return NO;
}


-(void)checkMessageFailureFlag:(IMessage*)msg {
    if (msg.isOutgoing) {
        if (msg.timestamp < uptime) {
            if (!msg.isACK) {
                //上次运行的时候，程序异常崩溃
                [self markMessageFailure:msg];
                msg.flags = msg.flags|MESSAGE_FLAG_FAILURE;
            }
        }
    }
}

-(void)checkMessageFailureFlag:(NSArray*)messages count:(int)count {
    for (int i = 0; i < count; i++) {
        IMessage *msg = [messages objectAtIndex:i];
        [self checkMessageFailureFlag:msg];
    }
}


- (void)updateNotificationDesc:(IMessage*)message {
    if (message.type == MESSAGE_GROUP_NOTIFICATION) {
        MessageGroupNotificationContent *notification = message.groupNotificationContent;
        int type = notification.notificationType;
        if (type == NOTIFICATION_GROUP_CREATED) {
            if (self.currentUID == notification.master) {
                NSString *desc = [NSString stringWithFormat:@"您创建了\"%@\"群组", notification.groupName];
                notification.notificationDesc = desc;
            } else {
                NSString *desc = [NSString stringWithFormat:@"您加入了\"%@\"群组", notification.groupName];
                notification.notificationDesc = desc;
            }
        } else if (type == NOTIFICATION_GROUP_DISBANDED) {
            notification.notificationDesc = @"群组已解散";
        } else if (type == NOTIFICATION_GROUP_MEMBER_ADDED) {
            IUser *u = [self getUser:notification.member];
            if (u.name.length > 0) {
                NSString *name = u.name;
                NSString *desc = [NSString stringWithFormat:@"%@加入群", name];
                notification.notificationDesc = desc;
            } else {
                NSString *name = u.identifier;
                NSString *desc = [NSString stringWithFormat:@"%@加入群", name];
                notification.notificationDesc = desc;
                [self asyncGetUser:notification.member cb:^(IUser *u) {
                    NSString *desc = [NSString stringWithFormat:@"%@加入群", u.name];
                    notification.notificationDesc = desc;
                }];
            }
        } else if (type == NOTIFICATION_GROUP_MEMBER_LEAVED) {
            IUser *u = [self getUser:notification.member];
            if (u.name.length > 0) {
                NSString *name = u.name;
                NSString *desc = [NSString stringWithFormat:@"%@离开群", name];
                notification.notificationDesc = desc;
            } else {
                NSString *name = u.identifier;
                NSString *desc = [NSString stringWithFormat:@"%@离开群", name];
                notification.notificationDesc = desc;
                [self asyncGetUser:notification.member cb:^(IUser *u) {
                    NSString *desc = [NSString stringWithFormat:@"%@离开群", u.name];
                    notification.notificationDesc = desc;
                }];
            }
        } else if (type == NOTIFICATION_GROUP_NAME_UPDATED) {
            NSString *desc = [NSString stringWithFormat:@"群组更名为%@", notification.groupName];
            notification.notificationDesc = desc;
        } else if (type == NOTIFICATION_GROUP_NOTICE_UPDATED) {
            NSString *desc = [NSString stringWithFormat:@"群公告:%@", notification.notice];
            notification.notificationDesc = desc;
        }
    } else if (message.type == MESSAGE_GROUP_VOIP) {
        MessageGroupVOIPContent *content = (MessageGroupVOIPContent*)message.groupVOIPContent;
        if (content.finished) {
            content.notificationDesc = @"语音通话已经结束";
        } else {
            IUser *u = [self getUser:content.initiator];
            if (u.name.length > 0) {
                NSString *name = u.name;
                NSString *desc = [NSString stringWithFormat:@"%@发起了语音聊天", name];
                content.notificationDesc = desc;
            } else {
                NSString *name = u.identifier;
                NSString *desc = [NSString stringWithFormat:@"%@发起了语音聊天", name];
                content.notificationDesc = desc;
                [self asyncGetUser:content.initiator cb:^(IUser *u) {
                    NSString *desc = [NSString stringWithFormat:@"%@发起了语音聊天", u.name];
                    content.notificationDesc = desc;
                }];
            }
        }
    }
}

- (void)updateNotificationDesc:(NSArray*)messages count:(int)count {
    for (int i = 0; i < count; i++) {
        IMessage *msg = [messages objectAtIndex:i];
        [self updateNotificationDesc:msg];
    }
}


- (void)downloadMessageContent:(IMessage*)msg {
    FileCache *cache = [FileCache instance];
    AudioDownloader *downloader = [AudioDownloader instance];
    if (msg.type == MESSAGE_AUDIO) {
        MessageAttachmentContent *attachment = [self.attachments objectForKey:[NSNumber numberWithInt:msg.msgLocalID]];
        
        if (attachment.url.length > 0) {
            MessageAudioContent *content = [msg.audioContent cloneWithURL:attachment.url];
            msg.rawContent = content.raw;
        }
        
        MessageAudioContent *content = msg.audioContent;

        NSString *path = [cache queryCacheForKey:content.url];
        NSLog(@"url:%@, %@", content.url, path);
        if (!path && ![downloader isDownloading:msg]) {
            [downloader downloadAudio:msg];
        }
        msg.downloading = [downloader isDownloading:msg];
    } else if (msg.type == MESSAGE_LOCATION) {
        MessageLocationContent *content = msg.locationContent;
        NSString *url = content.snapshotURL;
        if(![[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:url] &&
           ![[SDImageCache sharedImageCache] diskImageExistsWithKey:url]){
            [self createMapSnapshot:msg];
        }
        //加载附件中的地址
        MessageAttachmentContent *attachment = [self.attachments objectForKey:[NSNumber numberWithInt:msg.msgLocalID]];
        if (attachment && attachment.address) {
            content.address = attachment.address;
        }
        
        if (content.address.length == 0) {
            [self reverseGeocodeLocation:msg];
        }
    } else if (msg.type == MESSAGE_IMAGE) {
        NSLog(@"image url:%@", msg.imageContent.imageURL);
        MessageAttachmentContent *attachment = [self.attachments objectForKey:[NSNumber numberWithInt:msg.msgLocalID]];
        
        if (attachment.url.length > 0) {
            MessageImageContent *content = [msg.imageContent cloneWithURL:attachment.url];
            msg.rawContent = content.raw;
        }
    }
    

}

- (void)downloadMessageContent:(NSArray*)messages count:(int)count {
    for (int i = 0; i < count; i++) {
        IMessage *msg = [messages objectAtIndex:i];
        [self downloadMessageContent:msg];
    }
}


- (void)loadSenderInfo:(IMessage*)msg {
    msg.senderInfo = [self getUser:msg.sender];
    if (msg.senderInfo.name.length == 0) {
        [self asyncGetUser:msg.sender cb:^(IUser *u) {
            msg.senderInfo = u;
        }];
    }
}
- (void)loadSenderInfo:(NSArray*)messages count:(int)count {
    for (int i = 0; i < count; i++) {
        IMessage *msg = [messages objectAtIndex:i];
        [self loadSenderInfo:msg];
    }
}

-(NSString*)guid {
    CFUUIDRef    uuidObj = CFUUIDCreate(nil);
    NSString    *uuidString = (__bridge NSString *)CFUUIDCreateString(nil, uuidObj);
    CFRelease(uuidObj);
    return uuidString;
}
-(NSString*)localImageURL {
    return [NSString stringWithFormat:@"http://localhost/images/%@.png", [self guid]];
}

-(NSString*)localAudioURL {
    return [NSString stringWithFormat:@"http://localhost/audios/%@.m4a", [self guid]];
}

-(void)reverseGeocodeLocation:(IMessage*)msg {
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    MessageLocationContent *content = msg.locationContent;
    CLLocationCoordinate2D location = content.location;
    msg.geocoding = YES;
    CLLocation *loc = [[CLLocation alloc] initWithLatitude:location.latitude longitude:location.longitude];
    [geocoder reverseGeocodeLocation:loc completionHandler:^(NSArray *array, NSError *error) {
        if (!error && array.count > 0) {
            CLPlacemark *placemark = [array objectAtIndex:0];
            content.address = placemark.name;

            [self saveMessageAttachment:msg address:placemark.name];
        }
        msg.geocoding = NO;
    }];
}

- (void)createMapSnapshot:(IMessage*)msg {
    MessageLocationContent *content = msg.locationContent;
    CLLocationCoordinate2D location = content.location;
    NSString *url = content.snapshotURL;
    
    MKMapSnapshotOptions *options = [[MKMapSnapshotOptions alloc] init];
    options.scale = [[UIScreen mainScreen] scale];
    options.showsPointsOfInterest = YES;
    options.showsBuildings = YES;
    options.region = MKCoordinateRegionMakeWithDistance(location, 360, 200);
    options.mapType = MKMapTypeStandard;
    MKMapSnapshotter *snapshotter = [[MKMapSnapshotter alloc] initWithOptions:options];
    
    msg.downloading = YES;
    [snapshotter startWithCompletionHandler:^(MKMapSnapshot *snapshot, NSError *e) {
        if (e) {
            NSLog(@"error:%@", e);
        }
        else {
            NSLog(@"map snapshot success");
            [[SDImageCache sharedImageCache] storeImage:snapshot.image forKey:url];
        }
        msg.downloading = NO;
    }];

}

- (void)sendMessage:(IMessage *)msg withImage:(UIImage*)image {
    NSAssert(NO, @"not implement");
}

- (void)sendMessage:(IMessage*)message {
    NSAssert(NO, @"not implement");
}

#pragma mark - send message
- (void)sendLocationMessage:(CLLocationCoordinate2D)location address:(NSString*)address {
    IMessage *msg = [self.messageDB newOutMessage];
    
    MessageLocationContent *content = [[MessageLocationContent alloc] initWithLocation:location];
    msg.rawContent = content.raw;
    
    content = msg.locationContent;
    content.address = address;
    
    msg.timestamp = (int)time(NULL);
    msg.isOutgoing = YES;
    
    [self loadSenderInfo:msg];
    
    [self saveMessage:msg];
    [self sendMessage:msg];
    
    [self createMapSnapshot:msg];
    if (content.address.length == 0) {
        [self reverseGeocodeLocation:msg];
    } else {
        [self saveMessageAttachment:msg address:content.address];
    }
    [self insertMessage:msg];
}

- (void)sendAudioMessage:(NSString*)path second:(int)second {
    IMessage *msg = [self.messageDB newOutMessage];

    
    MessageAudioContent *content = [[MessageAudioContent alloc] initWithAudio:[self localAudioURL] duration:second];
    
    msg.rawContent = content.raw;
    msg.timestamp = (int)time(NULL);
    msg.isOutgoing = YES;
    
    [self loadSenderInfo:msg];
    
    //todo 优化读文件次数
    NSData *data = [NSData dataWithContentsOfFile:path];
    FileCache *fileCache = [FileCache instance];
    [fileCache storeFile:data forKey:content.url];
    
    [self saveMessage:msg];
    [self sendMessage:msg];
    [self insertMessage:msg];
}

-(UIImage*)resizeImage:(UIImage*)image {
    //宽高均 <= 1280，图片尺寸大小保持不变
    //宽或高 > 1280 && 宽高比 <= 2，取较大值等于1280，较小值等比例压缩
    //宽或高 > 1280 && 宽高比 > 2 && 宽或高 < 1280，图片尺寸大小保持不变
    //宽高均 > 1280 && 宽高比 > 2，取较小值等于1280，较大值等比例压缩
    
    CGFloat w = image.size.width;
    CGFloat h = image.size.height;

    CGFloat newWidth, newHeight;
    CGFloat r;
    if (w > h) {
        r = w/h;
    } else {
        r = h/w;
    }
    
    if (w <= 1280 && h <= 1280) {
        newWidth = w;
        newHeight = h;
    } else{
        if ( r > 2) {
            if (w > 1280 && h > 1280 ) {
                if (w > h) {
                    newHeight = 1280;
                    newWidth = newHeight*r;
                } else {
                    newWidth = 1280;
                    newHeight = newWidth*r;
                }
            } else {
                newHeight = h;
                newWidth = w;
            }
        } else {
            if (w > h) {
                newWidth = 1280;
                newHeight = newWidth/r;
            } else {
                newHeight = 1280;
                newWidth = newHeight/r;
            }
        }
    }

    if (newWidth == w && newHeight == h) {
        return image;
    }
    
    return [image resize:CGSizeMake(newWidth, newHeight)];
}
- (void)sendImageMessage:(UIImage*)image {
    if (image.size.height == 0) {
        return;
    }
 
    UIImage *sizeImage = [image resize:CGSizeMake(256, 256)];
    image = [self resizeImage:image];
    int newWidth = image.size.width;
    int newHeight = image.size.height;
    NSLog(@"image size:%f %f resize to %d %d", image.size.width, image.size.height, newWidth, newHeight);
    
    IMessage *msg = [self.messageDB newOutMessage];
    MessageImageContent *content = [[MessageImageContent alloc] initWithImageURL:[self localImageURL] width:newWidth height:newHeight];
    msg.rawContent = content.raw;
    msg.timestamp = (int)time(NULL);
    msg.isOutgoing = YES;
    
    [self loadSenderInfo:msg];
    
    [[SDImageCache sharedImageCache] storeImage:image forKey:content.imageURL];
    NSString *littleUrl =  [content littleImageURL];
    [[SDImageCache sharedImageCache] storeImage:sizeImage forKey: littleUrl];
    
    [self saveMessage:msg];
    
    [self sendMessage:msg withImage:image];
    [self insertMessage:msg];
}

-(void) sendTextMessage:(NSString*)text {
    IMessage *msg = [self.messageDB newOutMessage];
    
    MessageTextContent *content = [[MessageTextContent alloc] initWithText:text];
    msg.rawContent = content.raw;
    msg.timestamp = (int)time(NULL);
    msg.isOutgoing = YES;
    [self loadSenderInfo:msg];
    [self saveMessage:msg];
    [self sendMessage:msg];
    [self insertMessage:msg];
}

-(void)resendMessage:(IMessage*)message {
    message.flags = message.flags & (~MESSAGE_FLAG_FAILURE);
    [self eraseMessageFailure:message];
    [self sendMessage:message];
}

- (IUser*)getUser:(int64_t)uid {
    return [self.userDelegate getUser:uid];
}

- (void)asyncGetUser:(int64_t)uid cb:(void(^)(IUser*))cb {
    [self.userDelegate asyncGetUser:uid cb:cb];
}

#pragma mark InterfaceOrientation
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.tableView reloadData];
    [self.tableView setNeedsLayout];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    
}

#pragma mark - EMChatToolbarDelegate
- (void)chatToolbarDidChangeFrameToHeight:(CGFloat)toHeight {
    CGRect rect = self.tableView.frame;
    rect.origin.y = 0;
    rect.size.height = self.view.frame.size.height - toHeight;
    self.tableView.frame = rect;
    [self scrollToBottomAnimated:NO];
}

- (void)inputTextViewWillBeginEditing:(EaseTextView *)inputTextView {
    if (self.messageID > 0) {
        //重新加载数据
        self.messageID = 0;
        self.messages = [NSMutableArray array];
        [self loadConversationData];
        [self.tableView reloadData];
    }
}

- (void)didSendText:(NSString *)text {
    if (text && text.length > 0) {
        [self sendTextMessage:text];
    }
}

- (BOOL)_canRecord {
    __block BOOL bCanRecord = YES;
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0"] != NSOrderedAscending)
    {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
            [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
                bCanRecord = granted;
            }];
        }
    }
    
    return bCanRecord;
}

/**
 *  按下录音按钮开始录音
 */
- (void)didStartRecordingVoiceAction:(UIView *)recordView {
    if ([self.recordView isKindOfClass:[EaseRecordView class]]) {
        [(EaseRecordView *)self.recordView recordButtonTouchDown];
    }

    if ([self _canRecord]) {
        EaseRecordView *tmpView = (EaseRecordView *)recordView;
        tmpView.center = self.view.center;
        [self.view addSubview:tmpView];
        [self.view bringSubviewToFront:recordView];
        
        [self recordStart];
    }
}

/**
 *  手指向上滑动取消录音
 */
- (void)didCancelRecordingVoiceAction:(UIView *)recordView {
    [self.recordView removeFromSuperview];
    [self recordCancel];
}

/**
 *  松开手指完成录音
 */
- (void)didFinishRecoingVoiceAction:(UIView *)recordView {
    [self.recordView removeFromSuperview];
    [self recordEnd];
}

- (void)didDragInsideAction:(UIView *)recordView {
    
    if ([self.recordView isKindOfClass:[EaseRecordView class]]) {
        [(EaseRecordView *)self.recordView recordButtonDragInside];
    }

}

- (void)didDragOutsideAction:(UIView *)recordView {
    if ([self.recordView isKindOfClass:[EaseRecordView class]]) {
        [(EaseRecordView *)self.recordView recordButtonDragOutside];
    }
}

- (BOOL)isInConversation:(IMessage*)msg {
    if (!self.messages.count) {
        return NO;
    }
    for (NSInteger i = self.messages.count - 1; i >= 0; i--) {
        IMessage *m = [self.messages objectAtIndex:i];
        if ([m.uuid isEqualToString:msg.uuid]) {
            return YES;
        }
    }
    return NO;
}


#pragma mark - Outbox Observer
- (void)onAudioUploadSuccess:(IMessage*)msg URL:(NSString*)url {
    if ([self isInConversation:msg]) {
        IMessage *m = [self getMessageWithID:msg.msgLocalID];
        m.uploading = NO;
        MessageAudioContent *content = msg.audioContent;
        NSString *c = [[FileCache instance] queryCacheForKey:content.url];
        if (c.length > 0) {
            NSData *data = [NSData dataWithContentsOfFile:c];
            if (data.length > 0) {
                [[FileCache instance] storeFile:data forKey:url];
            }
        }
    }
}

-(void)onAudioUploadFail:(IMessage*)msg {
    if ([self isInConversation:msg]) {
        IMessage *m = [self getMessageWithID:msg.msgLocalID];
        m.flags = m.flags|MESSAGE_FLAG_FAILURE;
        m.uploading = NO;
    }
}

- (void)onImageUploadSuccess:(IMessage*)msg URL:(NSString*)url {
    if ([self isInConversation:msg]) {
        IMessage *m = [self getMessageWithID:msg.msgLocalID];
        m.uploading = NO;
    }
}

- (void)onImageUploadFail:(IMessage*)msg {
    if ([self isInConversation:msg]) {
        IMessage *m = [self getMessageWithID:msg.msgLocalID];
        m.flags = m.flags|MESSAGE_FLAG_FAILURE;
        m.uploading = NO;
    }
}



#pragma mark - Audio Downloader Observer
- (void)onAudioDownloadSuccess:(IMessage*)msg {
    if ([self isInConversation:msg]) {
        IMessage *m = [self getMessageWithID:msg.msgLocalID];
        m.downloading = NO;
    }
}

- (void)onAudioDownloadFail:(IMessage*)msg {
    if ([self isInConversation:msg]) {
        IMessage *m = [self getMessageWithID:msg.msgLocalID];
        m.downloading = NO;
    }
}


#pragma mark - EaseChatBarMoreViewDelegate
- (void)moreView:(EaseChatBarMoreView *)moreView didItemInMoreViewAtIndex:(NSInteger)index {

}

- (void)moreViewPhotoAction:(EaseChatBarMoreView *)moreView {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate  = self;
    picker.allowsEditing = NO;
    picker.mediaTypes = @[(NSString *)kUTTypeImage];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:NULL];
}

- (void)moreViewTakePicAction:(EaseChatBarMoreView *)moreView {

#if TARGET_IPHONE_SIMULATOR
    NSString *s = NSLocalizedString(@"message.simulatorNotSupportCamera", @"simulator does not support taking picture");
    [self.view makeToast:s];
#elif TARGET_OS_IPHONE
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate  = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.mediaTypes = @[(NSString *)kUTTypeImage];
    [self presentViewController:picker animated:YES completion:NULL];
#endif
}

- (void)moreViewLocationAction:(EaseChatBarMoreView *)moreView {
    LocationPickerController *ctl = [[LocationPickerController alloc] init];
    ctl.selectAddressdelegate = self;
    [self.navigationController pushViewController:ctl animated:YES];
}

- (void)moreViewVideoCallAction:(EaseChatBarMoreView *)moreView {
    [self call];
}

- (void)call {
    
}

- (void)recall:(BOOL)video {
    
}
@end
