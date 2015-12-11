/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "MessageViewController.h"
#import <imsdk/IMService.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "Constants.h"
#import "FileCache.h"
#import "AudioDownloader.h"

#import "MessageTextView.h"
#import "MessageAudioView.h"
#import "MessageImageView.h"
#import "MessageLocationView.h"
#import "MessageLinkView.h"
#import "MessageViewCell.h"
#import "MessageNotificationView.h"
#import "MessageTimeBaseView.h"

#import "MEESImageViewController.h"

#import "NSString+JSMessagesView.h"
#import "UIImage+Resize.h"
#import "UIView+Toast.h"
#import "MapViewController.h"
#import "LocationPickerController.h"
#import "WebViewController.h"

#import "EaseChatToolbar.h"
#import "EaseEmoji.h"
#import "EaseEmotionManager.h"

#define INPUT_HEIGHT 52.0f

#define kTakePicActionSheetTag  101


@interface MessageViewController()<AudioDownloaderObserver, 
    LocationPickerControllerDelegate, EMChatToolbarDelegate>

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

- (void)setup;

- (void)pullToRefresh;

- (void)AudioAction:(UIButton*)btn;
- (void)handleTapImageView:(UITapGestureRecognizer*)tap;
- (void)handleLongPress:(UILongPressGestureRecognizer *)longPress;

@end

@implementation MessageViewController

-(id) init {
    if (self = [super init]) {
        self.textMode = NO;
    }
    return self;
}



#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
 
    [self setup];
 
    [self loadSenderInfo];
    [self loadConversationData];
    
    //scroll tableview to bottom
    [self.tableView setContentOffset:CGPointMake(0, CGFLOAT_MAX)];
}

- (void)loadSenderInfo {
    self.senderInfo = [self.userDelegate getUser:self.sender];
    if (self.senderInfo.name.length == 0) {
        __weak MessageViewController *wself = self;
        [self.userDelegate asyncGetUser:self.sender cb:^(IUser *u) {
            wself.senderInfo = u;
            for (IMessage *msg in self.messages) {
                if (msg.sender == wself.sender) {
                    msg.senderInfo = wself.senderInfo;
                }
            }
        }];
    }
}

- (void)setup
{
    int w = self.view.bounds.size.width;
    int h = self.view.bounds.size.height;
    
    self.automaticallyAdjustsScrollViewInsets = NO;

    int y = kStatusBarHeight + KNavigationBarHeight;
    CGRect tableFrame = CGRectMake(0.0f, y, w, h - [EaseChatToolbar defaultHeight] - 64);
    
    self.view.backgroundColor = RGBACOLOR(235, 235, 237, 1);

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

-(void)setSenderInfo:(IUser *)senderInfo {
    [super setSenderInfo:senderInfo];
    
    for (IMessage *msg in self.messages) {
        if (msg.sender == self.sender) {
            msg.senderInfo = self.senderInfo;
        }
    }
}

#pragma mark - View lifecycle
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self setEditing:NO animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    NSLog(@"*** %@: didReceiveMemoryWarning ***", self.class);
}

- (void)dealloc {
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.tableView = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

#pragma mark - Text view delegate
- (void)textViewDidBeginEditing:(UITextView *)textView {

}

- (void)textViewDidEndEditing:(UITextView *)textView {

}

#pragma mark - menu notification
- (void)handleMenuWillHideNotification:(NSNotification *)notification
{
    self.selectedCell.bubbleView.selectedToShowCopyMenu = NO;
    self.selectedCell = nil;
    self.selectedMessage = nil;
}

- (void)handleMenuWillShowNotification:(NSNotification *)notification
{
    self.selectedCell.bubbleView.selectedToShowCopyMenu = YES;
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
        cell = [[MessageViewCell alloc] initWithType:message.type reuseIdentifier:CellID];
        if (message.type == MESSAGE_AUDIO) {
            MessageAudioView *audioView = (MessageAudioView*)cell.bubbleView;
            [audioView.playBtn addTarget:self action:@selector(AudioAction:) forControlEvents:UIControlEventTouchUpInside];
        } else if(message.type == MESSAGE_IMAGE) {
            UITapGestureRecognizer *tap  = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapImageView:)];
            [tap setNumberOfTouchesRequired: 1];
            MessageImageView *imageView = (MessageImageView*)cell.bubbleView;
            [imageView.imageView addGestureRecognizer:tap];
        } else if (message.type == MESSAGE_LOCATION) {
            UITapGestureRecognizer *tap  = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapLocationView:)];
            [tap setNumberOfTouchesRequired: 1];
            MessageLocationView *imageView = (MessageLocationView*)cell.bubbleView;
            [imageView.imageView addGestureRecognizer:tap];
        } else if (message.type == MESSAGE_LINK) {
            UITapGestureRecognizer *tap  = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapLinkView:)];
            [tap setNumberOfTouchesRequired: 1];
            MessageLinkView *linkView = (MessageLinkView*)cell.bubbleView;
            [linkView addGestureRecognizer:tap];
        } else if(message.type == MESSAGE_TEXT){
            
        }
        UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                 action:@selector(handleLongPress:)];
        [recognizer setMinimumPressDuration:0.4];
        [cell addGestureRecognizer:recognizer];
    }
    BubbleMessageType msgType;
    
    if (message.type == MESSAGE_TIME_BASE) {
        MessageTimeBaseContent *timeBase = message.timeBaseContent;
        timeBase.timeDesc = [self formatSectionTime:[NSDate dateWithTimeIntervalSince1970:timeBase.timestamp]];
        NSLog(@"time...:%@", timeBase.timeDesc);
    }
    
    if (message.sender == self.sender) {
        msgType = BubbleMessageTypeOutgoing;
        [cell setMessage:message msgType:msgType showName:NO];
    } else {
        msgType = BubbleMessageTypeIncoming;
        BOOL showName = self.isShowUserName;
        if (message.type == MESSAGE_GROUP_NOTIFICATION || message.type == MESSAGE_TIME_BASE) {
            showName = NO;
        }
        [cell setMessage:message msgType:msgType showName:showName];
    }
    
    if (message.type == MESSAGE_AUDIO) {
        MessageAudioView *audioView = (MessageAudioView*)cell.bubbleView;
        audioView.playBtn.tag = indexPath.section<<16 | indexPath.row;
    } else if (message.type == MESSAGE_IMAGE) {
        MessageImageView *imageView = (MessageImageView*)cell.bubbleView;
        imageView.imageView.tag = indexPath.section<<16 | indexPath.row;
    } else if (message.type == MESSAGE_LOCATION) {
        MessageLocationView *locationView = (MessageLocationView*)cell.bubbleView;
        locationView.imageView.tag = indexPath.section<<16 | indexPath.row;
    } else if (message.type == MESSAGE_LINK) {
        MessageLinkView *linkView = (MessageLinkView*)cell.bubbleView;
        linkView.tag = indexPath.section<<16 | indexPath.row;
    }
    
    cell.tag = indexPath.section<<16 | indexPath.row;
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.messages.count;
}


#pragma mark -  UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    IMessage *msg = [self messageForRowAtIndexPath:indexPath];
    if (msg == nil) {
        NSLog(@"opps");
        return 0;
    }
    int nameHeight = 0;
    if (self.isShowUserName && msg.sender != self.sender) {
        nameHeight = NAME_LABEL_HEIGHT;
    }
    
    switch (msg.type) {
        case MESSAGE_TEXT: {
            MessageTextContent *content = msg.textContent;
            int h = [MessageTextView cellHeightForText:content.text];
            h = MAX(40, h);
            return  h + nameHeight;
        }
        case  MESSAGE_IMAGE:
            return kMessageImagViewHeight + nameHeight;
            break;
        case MESSAGE_AUDIO:
            return kAudioViewCellHeight + nameHeight;
            break;
        case MESSAGE_LOCATION:
            return kMessageLocationViewHeight + nameHeight;
        case MESSAGE_GROUP_NOTIFICATION:
            return kMessageNotificationViewHeight;
        case MESSAGE_LINK:
            return kMessageLinkViewHeight + nameHeight;
        case MESSAGE_TIME_BASE:
            return kMessageTimeBaseViewHeight;
        default:
            return 0;
    }
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return NO;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

/*
 * 复用ID区分来去类型
 */
- (NSString*)getMessageViewCellId:(IMessage*)msg{
    if(msg.sender == self.sender) {
        return [NSString stringWithFormat:@"MessageCell_%d%d", msg.type, BubbleMessageTypeOutgoing];
    } else {
        return [NSString stringWithFormat:@"MessageCell_%d%d", msg.type, BubbleMessageTypeIncoming];
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

- (void)copyText:(id)sender
{
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
- (void)handleLongPress:(UILongPressGestureRecognizer *)longPress
{
    MessageViewCell *targetView = (MessageViewCell*)longPress.view;

    int row = targetView.tag & 0xffff;
    int section = (int)(targetView.tag >> 16);
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    IMessage *message = [self messageForRowAtIndexPath:indexPath];
    if (message == nil) {
        return;
    }
    
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
    self.selectedCell = targetView;
    
    UIMenuController *menu = [UIMenuController sharedMenuController];
    menu.menuItems = menuItems;
    CGRect targetRect = [targetView convertRect:[targetView.bubbleView bubbleFrame]
                                 fromView:targetView.bubbleView];
    [menu setTargetRect:CGRectInset(targetRect, 0.0f, 4.0f) inView:targetView];

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


- (void)updateNotificationDesc:(IMessage*)message {
    MessageNotificationContent *notification = message.notificationContent;
    if (message.type == MESSAGE_GROUP_NOTIFICATION) {
        int type = notification.notificationType;
        if (type == NOTIFICATION_GROUP_CREATED) {
            if (self.sender == notification.master) {
                NSString *desc = [NSString stringWithFormat:@"您创建了\"%@\"群组", notification.groupName];
                notification.notificationDesc = desc;
            } else {
                NSString *desc = [NSString stringWithFormat:@"您加入了\"%@\"群组", notification.groupName];
                notification.notificationDesc = desc;
            }
        } else if (type == NOTIFICATION_GROUP_DISBANDED) {
            notification.notificationDesc = @"群组已解散";
        } else if (type == NOTIFICATION_GROUP_MEMBER_ADDED) {
            IUser *u = [self.userDelegate getUser:notification.member];
            if (u.name.length > 0) {
                NSString *name = u.name;
                NSString *desc = [NSString stringWithFormat:@"%@加入群", name];
                notification.notificationDesc = desc;
            } else {
                NSString *name = u.identifier;
                NSString *desc = [NSString stringWithFormat:@"%@加入群", name];
                notification.notificationDesc = desc;
                [self.userDelegate asyncGetUser:notification.member cb:^(IUser *u) {
                    NSString *desc = [NSString stringWithFormat:@"%@加入群", u.name];
                    notification.notificationDesc = desc;
                }];
            }
        } else if (type == NOTIFICATION_GROUP_MEMBER_LEAVED) {
            IUser *u = [self.userDelegate getUser:notification.member];
            if (u.name.length > 0) {
                NSString *name = u.name;
                NSString *desc = [NSString stringWithFormat:@"%@离开群", name];
                notification.notificationDesc = desc;
            } else {
                NSString *name = u.identifier;
                NSString *desc = [NSString stringWithFormat:@"%@离开群", name];
                notification.notificationDesc = desc;
                [self.userDelegate asyncGetUser:notification.member cb:^(IUser *u) {
                    NSString *desc = [NSString stringWithFormat:@"%@离开群", u.name];
                    notification.notificationDesc = desc;
                }];
            }
        } else if (type == NOTIFICATION_GROUP_NAME_UPDATED) {
            NSString *desc = [NSString stringWithFormat:@"群组更名为%@", notification.groupName];
            notification.notificationDesc = desc;
        }
    }
}

- (BOOL)isMessageOutgoing:(IMessage*)msg {
    return msg.sender == self.sender;
}

- (void)downloadMessageContent:(IMessage*)msg {
    FileCache *cache = [FileCache instance];
    AudioDownloader *downloader = [AudioDownloader instance];
    if (msg.type == MESSAGE_AUDIO) {
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
        content.address = attachment.address;
        
        if (content.address.length == 0) {
            [self reverseGeocodeLocation:msg];
        }
    } else if (msg.type == MESSAGE_IMAGE) {
        NSLog(@"image url:%@", msg.imageContent.imageURL);
    } else if (msg.type == MESSAGE_GROUP_NOTIFICATION) {
        [self updateNotificationDesc:msg];
    }
    


    //群组聊天
    if (msg.sender == self.sender) {
        msg.senderInfo = self.senderInfo;
    } else if (msg.sender > 0) {
        msg.senderInfo = [self.userDelegate getUser:msg.sender];
        if (msg.senderInfo.name.length == 0) {
            [self.userDelegate asyncGetUser:msg.sender cb:^(IUser *u) {
                msg.senderInfo = u;
            }];
        }
    } else {
        //群组通知消息的sender==0
    }
}

- (void)downloadMessageContent:(NSArray*)messages count:(int)count {
    for (int i = 0; i < count; i++) {
        IMessage *msg = [messages objectAtIndex:i];
        [self downloadMessageContent:msg];
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

            //以附件的形式存储，以免第二次查询
            MessageAttachmentContent *att = [[MessageAttachmentContent alloc] initWithAttachment:msg.msgLocalID address:placemark.name];
            IMessage *attachment = [[IMessage alloc] init];
            attachment.sender = msg.sender;
            attachment.receiver = msg.receiver;
            attachment.rawContent = att.raw;
            [self saveMessage:attachment];
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

- (void)sendLocationMessage:(CLLocationCoordinate2D)location address:(NSString*)address {
    IMessage *msg = [[IMessage alloc] init];
    
    msg.sender = self.sender;
    msg.receiver = self.receiver;

    MessageLocationContent *content = [[MessageLocationContent alloc] initWithLocation:location];
    msg.rawContent = content.raw;
    
    content = msg.locationContent;
    content.address = address;
    
    msg.timestamp = (int)time(NULL);
    msg.senderInfo = self.senderInfo;
    
    [self saveMessage:msg];
    
    [self sendMessage:msg];
    
    [[self class] playMessageSentSound];
    
    [self createMapSnapshot:msg];
    if (content.address.length == 0) {
        [self reverseGeocodeLocation:msg];
    } else {
        MessageAttachmentContent *att = [[MessageAttachmentContent alloc] initWithAttachment:msg.msgLocalID address:content.address];
        IMessage *attachment = [[IMessage alloc] init];
        attachment.sender = msg.sender;
        attachment.receiver = msg.receiver;
        attachment.rawContent = att.raw;
        
        [self saveMessage:attachment];
    }
    [self insertMessage:msg];
}

- (void)sendAudioMessage:(NSString*)path second:(int)second {
    IMessage *msg = [[IMessage alloc] init];
    
    msg.sender = self.sender;
    msg.receiver = self.receiver;
    
    MessageAudioContent *content = [[MessageAudioContent alloc] initWithAudio:[self localAudioURL] duration:second];
    
    msg.rawContent = content.raw;
    msg.timestamp = (int)time(NULL);
    msg.senderInfo = self.senderInfo;
    
    //todo 优化读文件次数
    NSData *data = [NSData dataWithContentsOfFile:path];
    FileCache *fileCache = [FileCache instance];
    [fileCache storeFile:data forKey:content.url];
    
    [self saveMessage:msg];
    
    [self sendMessage:msg];
    
    [[self class] playMessageSentSound];

    [self insertMessage:msg];
}


- (void)sendImageMessage:(UIImage*)image {
    if (image.size.height == 0) {
        return;
    }
    
    
    IMessage *msg = [[IMessage alloc] init];
    
    msg.sender = self.sender;
    msg.receiver = self.receiver;
    
    MessageImageContent *content = [[MessageImageContent alloc] initWithImageURL:[self localImageURL]];
    msg.rawContent = content.raw;
    msg.timestamp = (int)time(NULL);
    msg.senderInfo = self.senderInfo;
   
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    
    float newHeigth = screenHeight;
    float newWidth = newHeigth*image.size.width/image.size.height;
    
    UIImage *sizeImage = [image resizedImage:CGSizeMake(128, 128) interpolationQuality:kCGInterpolationDefault];
    image = [image resizedImage:CGSizeMake(newWidth, newHeigth) interpolationQuality:kCGInterpolationDefault];
    
    [[SDImageCache sharedImageCache] storeImage:image forKey:content.imageURL];
    NSString *littleUrl =  [content littleImageURL];
    [[SDImageCache sharedImageCache] storeImage:sizeImage forKey: littleUrl];
    
    [self saveMessage:msg];

    [self sendMessage:msg withImage:image];

    [self insertMessage:msg];
    
    [[self class] playMessageSentSound];
}

-(void) sendTextMessage:(NSString*)text {
    IMessage *msg = [[IMessage alloc] init];
    
    msg.sender = self.sender;
    msg.receiver = self.receiver;
    
    MessageTextContent *content = [[MessageTextContent alloc] initWithText:text];
    msg.rawContent = content.raw;
    msg.timestamp = (int)time(NULL);
    msg.senderInfo = self.senderInfo;
    
    [self saveMessage:msg];
    
    [self sendMessage:msg];
    
    [[self class] playMessageSentSound];
    
    [self insertMessage:msg];
}


-(void)resendMessage:(IMessage*)message {
    message.flags = message.flags & (~MESSAGE_FLAG_FAILURE);
    [self eraseMessageFailure:message];
    [self sendMessage:message];
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
- (void)chatToolbarDidChangeFrameToHeight:(CGFloat)toHeight
{
    CGRect rect = self.tableView.frame;
    rect.origin.y = kStatusBarHeight + KNavigationBarHeight;
    rect.size.height = self.view.frame.size.height - toHeight - kStatusBarHeight - KNavigationBarHeight;
    self.tableView.frame = rect;
    [self scrollToBottomAnimated:NO];
}

- (void)inputTextViewWillBeginEditing:(EaseTextView *)inputTextView
{

}

- (void)didSendText:(NSString *)text
{
    if (text && text.length > 0) {
        [self sendTextMessage:text];
    }
}

- (BOOL)_canRecord
{
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
- (void)didStartRecordingVoiceAction:(UIView *)recordView
{
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
- (void)didCancelRecordingVoiceAction:(UIView *)recordView
{
    [self.recordView removeFromSuperview];
    [self recordCancel];
}

/**
 *  松开手指完成录音
 */
- (void)didFinishRecoingVoiceAction:(UIView *)recordView
{
    [self.recordView removeFromSuperview];
    [self recordEnd];
}

- (void)didDragInsideAction:(UIView *)recordView
{
    
    if ([self.recordView isKindOfClass:[EaseRecordView class]]) {
        [(EaseRecordView *)self.recordView recordButtonDragInside];
    }

}

- (void)didDragOutsideAction:(UIView *)recordView
{
    if ([self.recordView isKindOfClass:[EaseRecordView class]]) {
        [(EaseRecordView *)self.recordView recordButtonDragOutside];
    }

}


#pragma mark - EaseChatBarMoreViewDelegate

- (void)moreView:(EaseChatBarMoreView *)moreView didItemInMoreViewAtIndex:(NSInteger)index
{

}

- (void)moreViewPhotoAction:(EaseChatBarMoreView *)moreView
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate  = self;
    picker.allowsEditing = NO;
    picker.mediaTypes = @[(NSString *)kUTTypeImage];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:NULL];
}

- (void)moreViewTakePicAction:(EaseChatBarMoreView *)moreView
{

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

- (void)moreViewLocationAction:(EaseChatBarMoreView *)moreView
{
    LocationPickerController *ctl = [[LocationPickerController alloc] init];
    ctl.selectAddressdelegate = self;
    [self.navigationController pushViewController:ctl animated:YES];
}

@end
