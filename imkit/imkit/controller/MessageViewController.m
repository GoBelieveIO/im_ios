//
//  MessageViewController
//  Created by daozhu on 14-6-16.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import "MessageViewController.h"
#import <imsdk/IMService.h>
#import "MBProgressHUD.h"
#import "HPGrowingTextView.h"

#import "MessageTableSectionHeaderView.h"

#import "FileCache.h"
#import "Outbox.h"
#import "AudioDownloader.h"

#import "MessageInputView.h"

#import "MessageTextView.h"
#import "MessageAudioView.h"
#import "MessageImageView.h"
#import "MessageViewCell.h"

#import "MEESImageViewController.h"

#import "NSString+JSMessagesView.h"
#import "UIImage+Resize.h"
#import "UIView+Toast.h"


#define INPUT_HEIGHT 52.0f

#define kTakePicActionSheetTag  101


@interface MessageViewController()<MessageInputRecordDelegate, HPGrowingTextViewDelegate>

@property (strong, nonatomic) MessageInputView *inputToolBarView;
@property (assign, nonatomic, readonly) UIEdgeInsets originalTableViewContentInset;

@property (nonatomic,strong) UIImage *willSendImage;
@property (nonatomic) int  inputTimestamp;

@property(nonatomic) NSIndexPath *playingIndexPath;
@property(nonatomic) AVAudioPlayer *player;
@property(nonatomic) NSTimer *playTimer;

@property(nonatomic) AVAudioRecorder *recorder;
@property(nonatomic) NSTimer *recordingTimer;
@property(nonatomic, assign) int seconds;
@property(nonatomic) BOOL recordCanceled;

@property(nonatomic) IMessage *selectedMessage;
@property(nonatomic, weak) MessageViewCell *selectedCell;

- (void)setup;

#pragma mark - Actions
- (void)sendPressed:(UIButton *)sender;


#pragma mark - Keyboard notifications
- (void)handleWillShowKeyboard:(NSNotification *)notification;
- (void)handleWillHideKeyboard:(NSNotification *)notification;

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

    [self loadConversationData];
    
    //content scroll to bottom
    [self.tableView reloadData];
    [self.tableView setContentOffset:CGPointMake(0, CGFLOAT_MAX)];
}


- (void)setup
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    int w = CGRectGetWidth(screenBounds);
    int h = CGRectGetHeight(screenBounds);


    CGRect tableFrame = CGRectMake(0.0f,  0.0f, w,  h - INPUT_HEIGHT);
    CGRect inputFrame = CGRectMake(0.0f, h - INPUT_HEIGHT, w, INPUT_HEIGHT);
    
    UIImage *backColor = [UIImage imageNamed:@"chatBack"];
    UIColor *color = [[UIColor alloc] initWithPatternImage:backColor];
    [self.view setBackgroundColor:color];

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
	
    self.inputToolBarView = [[MessageInputView alloc] initWithFrame:inputFrame andDelegate:self];
    self.inputToolBarView.textView.maxHeight = 100;
    self.inputToolBarView.textView.delegate = self;

    [self.inputToolBarView.sendButton addTarget:self action:@selector(sendPressed:)
                               forControlEvents:UIControlEventTouchUpInside];
    
    [self.inputToolBarView.mediaButton addTarget:self action:@selector(cameraAction:)
                                forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.inputToolBarView];
    
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

- (void)setDraft:(NSString *)draft {
    if (draft.length > 0) {
        self.inputToolBarView.sendButton.enabled = ([[IMService instance] connectState] == STATE_CONNECTED);
        self.inputToolBarView.sendButton.hidden = NO;
        self.inputToolBarView.recordButton.hidden = YES;
        self.inputToolBarView.textView.text = draft;
    }
}

- (NSString*)getDraft {
    return self.inputToolBarView.textView.text;
}

#pragma mark - View lifecycle
- (void)viewWillAppear:(BOOL)animated
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleWillShowKeyboard:)
												 name:UIKeyboardWillShowNotification
                                               object:nil];
    
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleWillHideKeyboard:)
												 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.inputToolBarView resignFirstResponder];
    [self setEditing:NO animated:YES];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    NSLog(@"*** %@: didReceiveMemoryWarning ***", self.class);
}

- (void)dealloc
{
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.tableView = nil;
    self.inputToolBarView.textView.delegate = nil;
    self.inputToolBarView = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - View rotation
- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.tableView reloadData];
    [self.tableView setNeedsLayout];
}

#pragma mark -
- (void) handlePanFrom:(UITapGestureRecognizer*)recognizer{
    
    [self.inputToolBarView.textView resignFirstResponder];
}

#pragma mark - Actions
- (void)sendPressed:(UIButton *)sender
{
    NSString *text = [self.inputToolBarView.textView.text trimWhitespace];
    
    [self sendTextMessage:text];
    
    [self.inputToolBarView setNomarlShowing];
    if (INPUT_HEIGHT < self.inputToolBarView.frame.size.height) {
        CGFloat e = INPUT_HEIGHT - self.inputToolBarView.frame.size.height;
        [self extendInputViewHeight:e];
    }
}

- (void)timerFired:(NSTimer*)timer {
    self.seconds = self.seconds + 1;
    int minute = self.seconds/60;
    int s = self.seconds%60;
    NSString *str = [NSString stringWithFormat:@"%02d:%02d", minute, s];
    NSLog(@"timer:%@", str);
    self.inputToolBarView.timerLabel.text = str;
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
    
    [self.inputToolBarView setRecordShowing];
    
    self.recordCanceled = NO;
    self.seconds = 0;
    self.recordingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
}

-(void)stopRecord {
    [self.recorder stop];
    [self.recordingTimer invalidate];
    self.recordingTimer = nil;
    self.inputToolBarView.textView.hidden = NO;
    self.inputToolBarView.mediaButton.hidden = NO;
    self.inputToolBarView.recordingView.hidden = YES;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    BOOL r = [audioSession setActive:NO error:nil];
    if (!r) {
        NSLog(@"deactivate audio session fail");
    }
}

- (void)cameraAction:(id)sender
{
    [self cameraPressed:sender];
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


#pragma mark - Keyboard notifications
- (void)handleWillShowKeyboard:(NSNotification *)notification{
    NSLog(@"keyboard show");
    CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	NSTimeInterval animationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    UIViewAnimationCurve animationCurve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    [UIView setAnimationBeginsFromCurrentState:YES];
    
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    int h = CGRectGetHeight(screenBounds);
    int w = CGRectGetWidth(screenBounds);
    
    CGRect tableViewFrame = CGRectMake(0.0f,  0.0f, w,  h - self.inputToolBarView.frame.size.height - keyboardRect.size.height);
    CGFloat y = h - keyboardRect.size.height;
    y -= self.inputToolBarView.frame.size.height;
    CGRect inputViewFrame = CGRectMake(0, y, self.inputToolBarView.frame.size.width, self.inputToolBarView.frame.size.height);
    self.inputToolBarView.frame = inputViewFrame;
    self.tableView.frame = tableViewFrame;
    [self scrollToBottomAnimated:NO];
    [UIView commitAnimations];

}

- (void)handleWillHideKeyboard:(NSNotification *)notification{
    NSLog(@"keyboard hide");
    CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	NSTimeInterval animationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    UIViewAnimationCurve animationCurve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    [UIView setAnimationBeginsFromCurrentState:YES];
    
    CGRect inputViewFrame = CGRectOffset(self.inputToolBarView.frame, 0, keyboardRect.size.height);
    CGRect tableViewFrame = self.tableView.frame;
    tableViewFrame.size.height += keyboardRect.size.height;
    
    self.inputToolBarView.frame = inputViewFrame;
    self.tableView.frame = tableViewFrame;

    [self scrollToBottomAnimated:NO];
    [UIView commitAnimations];
}

#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    NSLog(@"player finished");
    MessageViewCell *cell = (MessageViewCell*)[self.tableView cellForRowAtIndexPath:self.playingIndexPath];
    if (cell == nil) {
        return;
    }
    
    self.playingIndexPath = nil;
    if ([self.playTimer isValid]) {
        [self.playTimer invalidate];
        self.playTimer = nil;
    }

    MessageAudioView *audioView = (MessageAudioView*)cell.bubbleView;

    audioView.progressView.progress = 1.0f;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [audioView.playBtn setImage:[UIImage imageNamed:@"Play"] forState:UIControlStateNormal];
        [audioView.playBtn setImage:[UIImage imageNamed:@"PlayPressed"] forState:UIControlStateSelected];
        audioView.progressView.progress = 0.0f;
        
    });
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    NSLog(@"player decode error");
    MessageViewCell *cell = (MessageViewCell*)[self.tableView cellForRowAtIndexPath:self.playingIndexPath];
    if (cell == nil) {
        return;
    }
    
    self.playingIndexPath = nil;
    if ([self.playTimer isValid]) {
        [self.playTimer invalidate];
        self.playTimer = nil;
    }
    
    MessageAudioView *audioView = (MessageAudioView*)cell.bubbleView;
    audioView.progressView.progress = 1.0f;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [audioView.playBtn setImage:[UIImage imageNamed:@"Play"] forState:UIControlStateNormal];
        [audioView.playBtn setImage:[UIImage imageNamed:@"PlayPressed"] forState:UIControlStateSelected];
        audioView.progressView.progress = 0.0f;
        
    });
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
        return;
    }
    
    [self sendAudioMessage:[recorder.url path] second:self.seconds];
}

- (void)disableSend {
    self.inputToolBarView.sendButton.enabled = NO;
    self.inputToolBarView.recordButton.enabled = NO;
    self.inputToolBarView.mediaButton.enabled = NO;
    self.inputToolBarView.userInteractionEnabled = NO;
}

- (void)enableSend {
    HPGrowingTextView *textView = self.inputToolBarView.textView;
    self.inputToolBarView.sendButton.enabled = ([textView.text trimWhitespace].length > 0);
    self.inputToolBarView.recordButton.enabled = YES;
    self.inputToolBarView.mediaButton.enabled = YES;
    self.inputToolBarView.userInteractionEnabled = YES;
}

-(void)extendInputViewHeight:(CGFloat)e {

    
    CGRect frame = self.inputToolBarView.frame;
    CGRect inputFrame = CGRectMake(frame.origin.x, frame.origin.y-e, frame.size.width, frame.size.height+e);

    frame = self.tableView.frame;
    CGRect tableFrame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height-e);
    
    if (inputFrame.origin.y < 60) {
        return;
    }
    NSLog(@"input frame:%f %f %f %f", inputFrame.origin.x, inputFrame.origin.y, inputFrame.size.width, inputFrame.size.height);
    NSLog(@"table frame:%f %f %f %f", tableFrame.origin.x, tableFrame.origin.y, tableFrame.size.width, tableFrame.size.height);
    [UIView beginAnimations:nil context:NULL];
    self.inputToolBarView.frame = inputFrame;
    self.tableView.frame = tableFrame;
    [UIView commitAnimations];
}


#pragma mark - HPGrowingTextViewDelegate
- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height
{

    NSLog(@"change height:%f", height);
    HPGrowingTextView *textView = growingTextView;
    NSLog(@"text:%@, height:%f", textView.text, height);
    if (height > textView.frame.size.height) {
        CGFloat e = height - textView.frame.size.height;
        [self extendInputViewHeight:e];
    } else if (height < textView.frame.size.height) {
        CGFloat e = height - textView.frame.size.height;
        [self extendInputViewHeight:e];
    }
}

- (void)growingTextViewDidChange:(HPGrowingTextView *)textView {

    if ([textView.text trimWhitespace].length > 0) {
        self.inputToolBarView.sendButton.enabled = ([[IMService instance] connectState] == STATE_CONNECTED);
        self.inputToolBarView.sendButton.hidden = NO;
        
        self.inputToolBarView.recordButton.hidden = YES;
    } else {
        self.inputToolBarView.sendButton.hidden = YES;
        
        self.inputToolBarView.recordButton.enabled = ([[IMService instance] connectState] == STATE_CONNECTED);
        self.inputToolBarView.recordButton.hidden = NO;
    }
    
    if((time(NULL) -  self.inputTimestamp) > 10){
        
        self.inputTimestamp = (int)time(NULL);
        MessageInputing *inputing = [[MessageInputing alloc ] init];
        inputing.sender = self.sender;
        inputing.receiver =self.receiver;
        
        [[IMService instance] sendInputing: inputing];
    }
}

- (void)updateSlider {
    IMessage *message = [self messageForRowAtIndexPath:self.playingIndexPath];
    if (message == nil) {
        return;
    }

    MessageViewCell *cell = (MessageViewCell*)[self.tableView cellForRowAtIndexPath:self.playingIndexPath];
    if (cell == nil) {
        return;
    }
    MessageAudioView *audioView = (MessageAudioView*)cell.bubbleView;
    audioView.progressView.progress = self.player.currentTime/self.player.duration;
}

-(void)AudioAction:(UIButton*)btn{
    int row = btn.tag & 0xffff;
    int section = (int)(btn.tag >> 16);
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    IMessage *message = [self messageForRowAtIndexPath:indexPath];
    if (message == nil) {
        return;
    }

    if (self.playingIndexPath != nil &&
        indexPath.section == self.playingIndexPath.section &&
        indexPath.row == self.playingIndexPath.row) {

        MessageViewCell *cell = (MessageViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        if (cell == nil) {
            return;
        }
        MessageAudioView *audioView = (MessageAudioView*)cell.bubbleView;
        if (self.player && [self.player isPlaying]) {
            [self.player stop];
            if ([self.playTimer isValid]) {
                [self.playTimer invalidate];
                self.playTimer = nil;
            }
            self.playingIndexPath = nil;
            [audioView setPlaying:NO];
        }
    } else {
        if (self.player && [self.player isPlaying]) {
            [self.player stop];
            if ([self.playTimer isValid]) {
                [self.playTimer invalidate];
                self.playTimer = nil;
            }

            MessageViewCell *cell = (MessageViewCell*)[self.tableView cellForRowAtIndexPath:self.playingIndexPath];
            if (cell != nil) {
                MessageAudioView *audioView = (MessageAudioView*)cell.bubbleView;
                [audioView setPlaying:NO];
            }
            self.playingIndexPath = nil;
        }
        
        MessageViewCell *cell = (MessageViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        if (cell == nil) {
            return;
        }
        MessageAudioView *audioView = (MessageAudioView*)cell.bubbleView;
        FileCache *fileCache = [FileCache instance];
        NSString *url = message.content.audio.url;
        
        if (!message.isListened) {
            message.flags |= MESSAGE_FLAG_LISTENED;
            [audioView setListened];
        
            [self markMesageListened:message];
        }
        
        NSString *path = [fileCache queryCacheForKey:url];
        if (path != nil) {
            // Setup audio session
            AVAudioSession *session = [AVAudioSession sharedInstance];
            [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
            
            [audioView setPlaying:YES];
            
            if (![[self class] isHeadphone]) {
                //打开外放
                [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker
                                           error:nil];
                
            }
            NSURL *u = [NSURL fileURLWithPath:path];
            self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:u error:nil];
            [self.player setDelegate:self];
            
            //设置为与当前音频播放同步的Timer
            self.playTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateSlider) userInfo:nil repeats:YES];
            self.playingIndexPath = indexPath;

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
    NSString *littleUrl = [message.content littleImageURL];
    
    if ([[SDImageCache sharedImageCache] diskImageExistsWithKey:message.content.imageURL]) {
        UIImage *cacheImg = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey: message.content.imageURL];
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
        [imgcontroller setImgUrl:message.content.imageURL];
        [imgcontroller setTappedThumbnail:tap.view];
        [self presentViewController:imgcontroller animated:YES completion:nil];
    }
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
        cell = [[MessageViewCell alloc] initWithType:message.content.type reuseIdentifier:CellID];
        if (message.content.type == MESSAGE_AUDIO) {
            MessageAudioView *audioView = (MessageAudioView*)cell.bubbleView;
            [audioView.microPhoneBtn addTarget:self action:@selector(AudioAction:) forControlEvents:UIControlEventTouchUpInside];
            [audioView.playBtn addTarget:self action:@selector(AudioAction:) forControlEvents:UIControlEventTouchUpInside];
        } else if(message.content.type == MESSAGE_IMAGE) {
            UITapGestureRecognizer *tap  = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapImageView:)];
            [tap setNumberOfTouchesRequired: 1];
            MessageImageView *imageView = (MessageImageView*)cell.bubbleView;
            [imageView.imageView addGestureRecognizer:tap];
        } else if(message.content.type == MESSAGE_TEXT){
            
        }
        UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                 action:@selector(handleLongPress:)];
        [recognizer setMinimumPressDuration:0.4];
        [cell addGestureRecognizer:recognizer];
    }
    BubbleMessageType msgType;
    
    if(message.sender == self.sender) {
        msgType = BubbleMessageTypeOutgoing;
    }else{
        msgType = BubbleMessageTypeIncoming;
    }
    
    [cell setMessage:message msgType:msgType];
    
    
    if (message.content.type == MESSAGE_AUDIO) {
        MessageAudioView *audioView = (MessageAudioView*)cell.bubbleView;
        audioView.microPhoneBtn.tag = indexPath.section<<16 | indexPath.row;
        audioView.playBtn.tag = indexPath.section<<16 | indexPath.row;
        
        if (self.playingIndexPath != nil &&
            self.playingIndexPath.section == indexPath.section &&
            self.playingIndexPath.row == indexPath.row) {
            [audioView setPlaying:YES];
            audioView.progressView.progress = self.player.currentTime/self.player.duration;
        } else {
            [audioView setPlaying:NO];
        }
        
        [audioView setUploading:[[Outbox instance] isUploading:message]];
        [audioView setDownloading:[[AudioDownloader instance] isDownloading:message]];
    } else if (message.content.type == MESSAGE_IMAGE) {
        MessageImageView *imageView = (MessageImageView*)cell.bubbleView;
        imageView.imageView.tag = indexPath.section<<16 | indexPath.row;
        [imageView setUploading:[[Outbox instance] isUploading:message]];
    }
    cell.tag = indexPath.section<<16 | indexPath.row;
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.timestamps != nil) {
        return [self.timestamps count];
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.messageArray != nil) {
        
        NSMutableArray *array = [self.messageArray objectAtIndex: section];
        return [array count];
    }
    
    return 1;
}



#pragma mark -  UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    IMessage *msg = [self messageForRowAtIndexPath:indexPath];
    if (msg == nil) {
        NSLog(@"opps");
        return 0;
    }
    switch (msg.content.type) {
        case MESSAGE_TEXT:
            return [BubbleView cellHeightForText:msg.content.text];
        case  MESSAGE_IMAGE:
            return kMessageImagViewHeight;
            break;
        case MESSAGE_AUDIO:
            return kAudioViewCellHeight;
            break;
        case MESSAGE_LOCATION:
            return 40;
        default:
            return 0;
    }
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView == self.tableView) {
        if (indexPath.section == 0 &&  indexPath.row == 0) {
            return NO;
        }else{
            return YES;
        }
    }
    return NO;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (CGFloat)widthOfString:(NSString *)string withFont:(UIFont *)font {
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
    return [[[NSAttributedString alloc] initWithString:string attributes:attributes] size].width;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    MessageTableSectionHeaderView *sectionView = [[[NSBundle mainBundle]loadNibNamed:@"MessageTableSectionHeaderView" owner:self options:nil] lastObject];
    NSDate *curtDate = [self.timestamps objectAtIndex: section];
    NSDateComponents *components = [self getComponentOfDate:curtDate];
    NSDate *todayDate = [NSDate date];
    NSString *timeStr = nil;
    if ([self isSameDay:curtDate other:todayDate]) {
        timeStr = [NSString stringWithFormat:@"%02zd:%02zd",components.hour,components.minute];
        sectionView.sectionHeader.text = timeStr;
    } else if ([self isInWeek:curtDate today:todayDate]) {
        timeStr = [self getWeekDayString: components.weekday];
        sectionView.sectionHeader.text = timeStr;
    }else{
        timeStr = [self getConversationTimeString:curtDate];
        sectionView.sectionHeader.text = timeStr;
    }
    
    CGFloat width = [self widthOfString:timeStr withFont:[UIFont systemFontOfSize:MES_SECTION_TIMER_FONT_SIZE]] + 12;
    if (width>(self.view.frame.size.width/2)) {
        width = self.view.frame.size.width/2;
    }
    CGRect frame = sectionView.sectionHeader.frame;
    frame.size.width = width;
    frame.origin.x = (sectionView.frame.size.width - width)/2;
    [sectionView.sectionHeader setFrame:frame];
    
    sectionView.alpha = 0.9;
    return sectionView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 44;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}


/*
 * 复用ID区分来去类型
 */
- (NSString*)getMessageViewCellId:(IMessage*)msg{
    if(msg.sender == self.sender) {
        return [NSString stringWithFormat:@"MessageCell_%d%d", msg.content.type, BubbleMessageTypeOutgoing];
    } else {
        return [NSString stringWithFormat:@"MessageCell_%d%d", msg.content.type, BubbleMessageTypeIncoming];
    }
}


#pragma mark - Messages view delegate


- (void)cameraPressed:(id)sender{
    
    if ([self.inputToolBarView.textView isFirstResponder]) {
        [self.inputToolBarView.textView resignFirstResponder];
    }
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:nil
                                  delegate:self
                                  cancelButtonTitle:@"取消"
                                  destructiveButtonTitle:nil
                                  otherButtonTitles:@"摄像头拍照", @"从相册选取",nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    actionSheet.tag = kTakePicActionSheetTag;
    [actionSheet showInView:self.view];
    

}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (actionSheet.tag==kTakePicActionSheetTag) {
        if (buttonIndex == 0) {
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            picker.delegate  = self;
            picker.allowsEditing = NO;
            picker.sourceType = UIImagePickerControllerSourceTypeCamera;
            [self presentViewController:picker animated:YES completion:NULL];
        }else if(buttonIndex == 1){
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            picker.delegate  = self;
            picker.allowsEditing = NO;
            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            [self presentViewController:picker animated:YES completion:NULL];
        }
    }
}



#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	NSLog(@"Chose image!  Details:  %@", info);
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];

    [self sendImageMessage:image];
 
    [self dismissViewControllerAnimated:YES completion:NULL];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    
}

#pragma mark - MessageInputRecordDelegate
- (void)recordStart {
    if (self.recorder.recording) {
        return;
    }
    
    if (self.player && [self.player isPlaying]) {
        [self.player stop];
        if ([self.playTimer isValid]) {
            [self.playTimer invalidate];
            self.playTimer = nil;
        }
        
        MessageViewCell *cell = (MessageViewCell*)[self.tableView cellForRowAtIndexPath:self.playingIndexPath];
        if (cell != nil) {
            MessageAudioView *audioView = (MessageAudioView*)cell.bubbleView;
            [audioView.playBtn setImage:[UIImage imageNamed:@"Play"] forState:UIControlStateNormal];
            [audioView.playBtn setImage:[UIImage imageNamed:@"PlayPressed"] forState:UIControlStateSelected];
            audioView.progressView.progress = 0.0f;
        }
        self.playingIndexPath = nil;
    }
    
    
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (granted) {
            [self startRecord];
        } else {
            [self.view makeToast:@"无法录音,请到设置-隐私-麦克风,允许程序访问"];
        }
    }];
}

- (void)recordCancel:(CGFloat)xMove {
    NSLog(@"touch cancel");
   
     if (xMove < 0) {
         [self.inputToolBarView slipLabelFrame:xMove];
     }
     if (xMove < -50 && self.recorder.recording) {
         NSLog(@"cancel record...");
         self.recordCanceled = YES;
         [self stopRecord];
     }
}

-(void)recordEnd {
    if (self.recorder.recording) {
        NSLog(@"stop record...");
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
    if (self.selectedMessage.content.type != MESSAGE_TEXT) {
        return;
    }
    NSLog(@"copy...");

    [[UIPasteboard generalPasteboard] setString:self.selectedMessage.content.text];
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


    if (message.content.type == MESSAGE_TEXT) {
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


+ (BOOL)isHeadphone
{
    AVAudioSessionRouteDescription* route = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription* desc in [route outputs]) {
        if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones])
            return YES;
    }
    return NO;
}

@end
