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
#import <SDWebImage/SDWebImage.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

#import "FileCache.h"
#import "AudioDownloader.h"

#import "MessageTextView.h"
#import "MessageAudioView.h"
#import "MessageImageView.h"
#import "MessageLocationView.h"
#import "MessageLinkView.h"
#import "MessageNotificationView.h"
#import "MessageVOIPView.h"
#import "MessageFileView.h"
#import "MessageVideoView.h"
#import "MessageClassroomView.h"
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
#import "AVURLAsset+Video.h"
#import "MapViewController.h"
#import "LocationPickerController.h"
#import "WebViewController.h"
#import "OverlayViewController.h"
#import "FileDownloadViewController.h"

#import "EaseChatToolbar.h"

#define INPUT_HEIGHT 52.0f

#define kTakePicActionSheetTag  101



@interface MessageViewController()<LocationPickerControllerDelegate,
                                    EaseChatBarMoreViewDelegate,
                                    EMChatToolbarDelegate,
                                    FileDownloadViewControllerDelegate,
                                    UIDocumentInteractionControllerDelegate>



@property(strong, nonatomic) EaseChatBarMoreView *chatBarMoreView;
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

+ (BOOL)isHeadphone {
    AVAudioSessionRouteDescription* route = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription* desc in [route outputs]) {
        if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones])
            return YES;
    }
    return NO;
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
    
    [self loadData];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
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
    self.chatToolbar = [[EaseChatToolbar alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - chatbarHeight, self.view.frame.size.width, chatbarHeight)];
    self.chatToolbar.delegate = self;
    if (!self.callEnabled) {
        [self.chatToolbar setupSubviews:@{@(BUTTON_CALL_TAG):@(YES)}];
    } else {
        [self.chatToolbar setupSubviews:nil];
    }
    EaseChatBarMoreView *chatBarMoreView = (EaseChatBarMoreView*)[(EaseChatToolbar *)self.chatToolbar moreView];
    chatBarMoreView.delegate = self;
    self.recordView = [[EaseRecordView alloc] initWithFrame:CGRectMake(90, 130, 140, 140)];
    self.chatToolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:self.chatToolbar];
    self.inputBar = self.chatToolbar;

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

#pragma mark - View rotation
- (BOOL)shouldAutorotate
{
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
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
    int row = [self loadEarlierData];
    [self.tableView reloadData];
    int section = 0;
    NSLog(@"scroll to row:%d section:%d", row, section);
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
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

#pragma mark - Keyboard notifications
- (void)handleKeyboardWillChangeFrame:(NSNotification *)notification{
    NSLog(@"keyboard change frame");
    [self.chatToolbar chatKeyboardWillChangeFrame:notification];
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}


#pragma mark - menu notification
- (void)handleMenuWillHideNotification:(NSNotification *)notification {
    self.selectedCell.selectedToShowCopyMenu = NO;
    self.selectedCell = nil;
    self.selectedMessage = nil;
}

- (void)handleMenuWillShowNotification:(NSNotification *)notification {
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
        [self.view makeToast:NSLocalizedString(@"message.recordTimeShort", nil) duration:0.7 position:@"bottom"];
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
    } else if (message.type == MESSAGE_VIDEO) {
        [self handleTapVideoView:tap];
    } else if (message.type == MESSAGE_FILE) {
        [self handleTapFileView:tap];
    } else if (message.type == MESSAGE_CLASSROOM) {
        [self handleTapClassroomView:tap];
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
    
    if ([[SDImageCache sharedImageCache] diskImageDataExistsWithKey:content.imageURL]) {
        UIImage *cacheImg = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey: content.imageURL];
        MEESImageViewController * imgcontroller = [[MEESImageViewController alloc] init];
        [imgcontroller setImage:cacheImg];
        [imgcontroller setTappedThumbnail:tap.view];
        imgcontroller.isFullSize = YES;
        [self presentViewController:imgcontroller animated:YES completion:nil];
    } else if([[SDImageCache sharedImageCache] diskImageDataExistsWithKey:littleUrl]){
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

- (void) handleTapVideoView:(UITapGestureRecognizer*)tap {
    int row = tap.view.tag & 0xffff;
    int section = (int)(tap.view.tag >> 16);
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    IMessage *message = [self messageForRowAtIndexPath:indexPath];
    if (message == nil) {
        return;
    }

    MessageVideoContent *content = message.videoContent;
    if ([[FileCache instance] isCached:content.videoURL]) {
        if (message.secret) {
            NSString *path = [[FileCache instance] cachePathForKey:content.videoURL];
            NSString *mp4Path = [NSString stringWithFormat:@"%@.mp4", path];
            if (![[NSFileManager defaultManager] fileExistsAtPath:mp4Path]) {
                [[NSFileManager defaultManager] linkItemAtPath:path toPath:mp4Path error:nil];
            }
            [self playVideo:mp4Path];
        } else {
            NSString *path = [[FileCache instance] cachePathForKey:content.videoURL];
            [self playVideo:path];
        }
    } else {
        FileDownloadViewController *ctrl = [[FileDownloadViewController alloc] init];
        ctrl.url = content.videoURL;
        ctrl.size = content.size;
        ctrl.message = message;
        ctrl.delegate = self;
        [self.navigationController pushViewController:ctrl animated:YES];
    }
}

-(void)handleTapFileView:(UITapGestureRecognizer*)tap {
    int row = tap.view.tag & 0xffff;
    int section = (int)(tap.view.tag >> 16);
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    IMessage *message = [self messageForRowAtIndexPath:indexPath];
    if (message == nil) {
        return;
    }
    
    MessageFileContent *content = message.fileContent;
    
    if ([[FileCache instance] isCached:content.fileURL]) {
        NSString *path = [[FileCache instance] cachePathForKey:content.fileURL];
        NSURL *fileURL = [NSURL fileURLWithPath:path];
        UIDocumentInteractionController *documentVc = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
        documentVc.delegate = self;
        [documentVc presentPreviewAnimated:YES];
    } else {
        //first download file to local storage
        FileDownloadViewController *ctrl = [[FileDownloadViewController alloc] init];
        ctrl.url = content.fileURL;
        ctrl.size = content.fileSize;
        ctrl.message = message;
        ctrl.delegate = self;
        [self.navigationController pushViewController:ctrl animated:YES];
    }
}

-(void)handleTapClassroomView:(UITapGestureRecognizer*)tap {
    int row = tap.view.tag & 0xffff;
    int section = (int)(tap.view.tag >> 16);
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    IMessage *message = [self messageForRowAtIndexPath:indexPath];
    if (message == nil) {
        return;
    }
    if (message.sender == self.currentUID) {
        return;
    }
    [self openClassroomViewController:message];
}

-(void)fileDownloadSuccess:(NSString *)url message:(IMessage *)msg {
    //pop fileviewcontroller
    [self.navigationController popViewControllerAnimated:NO];

    if (msg.type == MESSAGE_FILE) {
        NSString *path = [[FileCache instance] cachePathForKey:url];
        NSURL *fileURL = [NSURL fileURLWithPath:path];
        UIDocumentInteractionController *documentVc = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
        documentVc.delegate = self;
        [documentVc presentPreviewAnimated:YES];
    } else if (msg.type == MESSAGE_VIDEO) {
        NSString *path = [[FileCache instance] cachePathForKey:url];
        if (msg.secret) {
            NSString *mp4Path = [NSString stringWithFormat:@"%@.mp4", path];
            if (![[NSFileManager defaultManager] fileExistsAtPath:mp4Path]) {
                [[NSFileManager defaultManager] linkItemAtPath:path toPath:mp4Path error:nil];
            }
            [self playVideo:mp4Path];
        } else {
            [self playVideo:path];
        }
    }
}

-(void)playVideo:(NSString*)mpath {
    NSURL *url=[NSURL fileURLWithPath:mpath];
    AVAsset *asset = [AVAsset assetWithURL:url];
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
    AVPlayer *avplayer = [AVPlayer playerWithPlayerItem:item];
    AVPlayerViewController *moviePlayer= [[AVPlayerViewController alloc] init];
    moviePlayer.player = avplayer;
    [self presentViewController:moviePlayer animated:YES completion:^{
        [avplayer play];
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:@"status"]){
        if (playerItem.status == AVPlayerItemStatusReadyToPlay){
            NSLog(@"playerItem is ready");
        } else if(playerItem.status == AVPlayerStatusUnknown){
            NSLog(@"playerItem Unknown错误");
        }
        else if (playerItem.status == AVPlayerStatusFailed){
            NSLog(@"playerItem 失败");
        }
    }
}

- (int)deleteMessage:(IMessage*)msg {
    int index = [super deleteMessage:msg];
    if (index != -1) {
        NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [indexPaths addObject:indexPath];
        [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    }
    return index;
}

- (int)replaceMessage:(IMessage*)msg dest:(IMessage*)other {
    int index = [super replaceMessage:msg dest:other];
    if (index != -1) {
        NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [indexPaths addObject:indexPath];
        [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    return index;
}

- (BOOL)insertMessage:(IMessage*)msg {
    BOOL newTimeBase = [super insertMessage:msg];
    
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    if (newTimeBase) {
        NSIndexPath *indexPath = nil;
        indexPath = [NSIndexPath indexPathForRow:self.messages.count - 2 inSection:0];
        [indexPaths addObject:indexPath];
    }
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.messages.count - 1 inSection:0];
    [indexPaths addObject:indexPath];
    
    [UIView beginAnimations:nil context:NULL];
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    [self scrollToBottomAnimated:NO];
    [UIView commitAnimations];
    return newTimeBase;
}

- (void)scrollToBottomAnimated:(BOOL)animated {
    if (self.messages.count == 0) {
        return;
    }
    long lastRow = [self.messages count] - 1;
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:lastRow inSection:0]
                          atScrollPosition:UITableViewScrollPositionBottom
                                  animated:animated];
}


#pragma mark - UIDocumentInteractionController 代理方法
- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller{
    return self.navigationController;
}

- (UIView *)documentInteractionControllerViewForPreview:(UIDocumentInteractionController *)controller{
    return self.view;
}

- (CGRect)documentInteractionControllerRectForPreview:(UIDocumentInteractionController *)controller{
    return self.view.bounds;
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
        int r = [self loadLateData];
        if (r) {
            [self.tableView reloadData];
        }
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
        case MESSAGE_ACK:
            return kMessageNotificationViewHeight;
        case MESSAGE_LINK:
            return kMessageLinkViewHeight + nameHeight;
        case MESSAGE_VOIP:
            return kMessageVOIPViewHeight;
        case MESSAGE_FILE:
            return kMessageFileViewHeight + nameHeight;
        case MESSAGE_VIDEO:
            return kMessageVideoViewHeight + nameHeight;
        case MESSAGE_CLASSROOM:
            return kMessageClassroomViewHeight + nameHeight;
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
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	NSLog(@"didFinishPickingMediaWithInfo  Details:  %@", info);
    NSString  *type = [info objectForKey:UIImagePickerControllerMediaType];
    if ([type isEqualToString:(NSString*)kUTTypeImage]) {
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        [self sendImageMessage:image];
    } else if ([type isEqualToString:(NSString*)kUTTypeMovie]) {
        NSURL *url = [info objectForKey:UIImagePickerControllerMediaURL];
        [self sendVideoMessage:url];
    }

    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - MessageInputRecordDelegate
- (void)recordStart {
    if (self.recorder.recording) {
        return;
    }
    
    [self stopPlayer];
    AVAudioSessionRecordPermission recordPermission = [AVAudioSession sharedInstance].recordPermission;
    if (recordPermission == AVAudioSessionRecordPermissionGranted) {
           [self startRecord];
    } else if (recordPermission == AVAudioSessionRecordPermissionUndetermined) {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            if (granted) {
                [self startRecord];
            }
        }];
    } else if (recordPermission == AVAudioSessionRecordPermissionUndetermined) {
        [self.view makeToast:NSLocalizedString(@"message.recordPermissionWarning", nil)];
    }
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

- (void)revoke:(id)sender {
    NSLog(@"revoke...");
    [self resignFirstResponder];
    if (self.selectedMessage == nil) {
        return;
    }
    IMessage *message = self.selectedMessage;
    [self revokeMessage:message];
}

- (void)resend:(id)sender {
    NSLog(@"resend...");
    
    [self resignFirstResponder];
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
        UIMenuItem *item = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"message.copy", nil) action:@selector(copyText:)];
        [menuItems addObject:item];
    }
    if (message.isFailure) {
        UIMenuItem *item = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"message.resend", nil) action:@selector(resend:)];
        [menuItems addObject:item];
    }
    
    int now = (int)time(NULL);
    if (now >= message.timestamp && (now - message.timestamp) < (REVOKE_EXPIRE - 10) && message.isOutgoing) {
        UIMenuItem *item = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"message.revoke", nil) action:@selector(revoke:)];
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
        [self loadData];
        [self.tableView reloadData];
    }
}

- (void)didSendText:(NSString *)text {
    [self didSendText:text withAt:nil];
}

- (void)didSendText:(NSString *)text withAt:(NSArray *)atUsers {
    if (text && text.length > 0) {
        NSMutableArray *array = [NSMutableArray array];
        NSMutableArray *atNames = [NSMutableArray array];
        for (IUser *u in atUsers) {
            NSAssert(u.name, @"");
            [array addObject:@(u.uid)];
            [atNames addObject:u.name];
        }
        
        [self sendTextMessage:text at:array atNames:atNames];
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

- (void)onVideoUploadSuccess:(IMessage *)msg URL:(NSString *)url thumbnailURL:(NSString *)thumbURL {
    if ([self isInConversation:msg]) {
        IMessage *m = [self getMessageWithID:msg.msgLocalID];
        m.uploading = NO;
    }
}

- (void)onVideoUploadFail:(IMessage *)msg {
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

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        

    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"message.takePhoto", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
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
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"message.recordVideo", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
#if TARGET_IPHONE_SIMULATOR
        NSString *s = NSLocalizedString(@"message.simulatorNotSupportCamera", @"simulator does not support taking picture");
        [self.view makeToast:s];
#elif TARGET_OS_IPHONE
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate  = self;
        picker.allowsEditing = NO;
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        picker.mediaTypes = @[(NSString *)kUTTypeMovie];
        picker.videoQuality = UIImagePickerControllerQualityTypeLow;
        picker.videoMaximumDuration = 6;
        [self presentViewController:picker animated:YES completion:NULL];
#endif
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
    

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

-(void)openClassroomViewController:(IMessage *)msg {
    
}
@end
