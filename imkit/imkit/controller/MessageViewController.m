//
//  MessageViewController
//  Created by daozhu on 14-6-16.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import "MessageViewController.h"
#import <imsdk/IMService.h>
#import "MBProgressHUD.h"
#import "HPGrowingTextView.h"

#import "IMessage.h"
#import "PeerMessageDB.h"

#import "FileCache.h"
#import "Outbox.h"
#import "AudioDownloader.h"
#import "DraftDB.h"

#import "IMHttpAPI.h"

#import "ConversationHeadButtonView.h"
#import "MessageTableSectionHeaderView.h"

#import "MessageInputView.h"

#import "MessageTextView.h"
#import "MessageAudioView.h"
#import "MessageImageView.h"
#import "MessageViewCell.h"
#import "BubbleView.h"

#import "MEESImageViewController.h"

#import "NSString+JSMessagesView.h"
#import "UIImage+Resize.h"
#import "UIView+Toast.h"

#import "Constants.h"

#define PAGE_COUNT 10

#define INPUT_HEIGHT 52.0f

#define navBarHeadButtonSize 35

#define kTakePicActionSheetTag  101


@interface MessageViewController()<MessageInputRecordDelegate, AudioDownloaderObserver, OutboxObserver, HPGrowingTextViewDelegate>

@property (nonatomic) NSTimer  *inputStatusTimer;
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) MessageInputView *inputToolBarView;
@property (assign, nonatomic, readonly) UIEdgeInsets originalTableViewContentInset;

@property (strong, nonatomic) NSMutableArray *messageArray;
@property (strong, nonatomic) NSMutableArray *timestamps;
@property (strong, nonatomic) NSMutableArray *messages;

@property (nonatomic,strong) UIImage *willSendImage;

@property (nonatomic) ConversationHeadButtonView *navigationBarButtonsView;
@property (nonatomic) int  inputTimestamp;

@property(nonatomic) AVAudioPlayer *player;
@property(nonatomic) NSIndexPath *playingIndexPath;
@property(nonatomic) NSTimer *playTimer;

@property(nonatomic) AVAudioRecorder *recorder;
@property(nonatomic) NSTimer *recordingTimer;
@property(nonatomic, assign) int seconds;
@property(nonatomic) BOOL recordCanceled;

@property(nonatomic) UIRefreshControl *refreshControl;

@property(nonatomic) IMessage *selectedMessage;
@property(nonatomic, weak) MessageViewCell *selectedCell;

- (void)setup;

#pragma mark - Actions
- (void)sendPressed:(UIButton *)sender;

#pragma mark - Messages view controller
- (void)scrollToBottomAnimated:(BOOL)animated;

#pragma mark - Keyboard notifications
- (void)handleWillShowKeyboard:(NSNotification *)notification;
- (void)handleWillHideKeyboard:(NSNotification *)notification;
@end

@implementation MessageViewController

-(id) init {
    if (self = [super init]) {
        self.messages = [NSMutableArray array];
    }
    return self;
}


- (void)loadView{
    [super loadView];
    
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
 
    [self setup];

    [self setNormalNavigationButtons];
    
    self.navigationBarButtonsView = [[[NSBundle mainBundle]loadNibNamed:@"ConversationHeadButtonView" owner:self options:nil] lastObject];
    self.navigationBarButtonsView.center = self.navigationController.navigationBar.center;
    self.navigationBarButtonsView.nameLabel.text = self.peerName;
    [self.navigationBarButtonsView.conectInformationLabel setText: [self getRemoteUserLastOnlineTimestamp]];
    [self.navigationBarButtonsView.conectInformationLabel setFont:[UIFont systemFontOfSize:11.0f]];
    
    self.navigationItem.titleView = self.navigationBarButtonsView;

    [self processConversationData];
    //content scroll to bottom
    [self.tableView reloadData];
    [self.tableView setContentOffset:CGPointMake(0, CGFLOAT_MAX)];
    
    [[IMService instance] addMessageObserver:self];
    [[Outbox instance] addBoxObserver:self];
    [[AudioDownloader instance] addDownloaderObserver:self];
}

-(void) viewDidAppear:(BOOL)animated{

}

-(void) viewDidDisappear:(BOOL)animated{
    
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
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
	self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    
    UIView *refreshView = [[UIView alloc] initWithFrame:CGRectMake(0, 55, 0, 0)];
    self.tableView.tableHeaderView = refreshView;
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(pullToRefresh) forControlEvents:UIControlEventValueChanged];
    [refreshView addSubview:self.refreshControl];
    
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
        self.inputToolBarView.sendButton.enabled = YES;
        self.inputToolBarView.recordButton.enabled = YES;
        self.inputToolBarView.mediaButton.enabled = YES;
        self.inputToolBarView.userInteractionEnabled = YES;
    } else {
        self.inputToolBarView.sendButton.enabled = NO;
        self.inputToolBarView.recordButton.enabled = NO;
        self.inputToolBarView.mediaButton.enabled = NO;
        self.inputToolBarView.userInteractionEnabled = NO;
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
    
    
    DraftDB *db = [DraftDB instance];
    NSString *draft = [db getDraft:self.peerUID];
    if (draft.length > 0) {
        self.inputToolBarView.sendButton.enabled = ([[IMService instance] connectState] == STATE_CONNECTED);
        self.inputToolBarView.sendButton.hidden = NO;
        self.inputToolBarView.recordButton.hidden = YES;
        self.inputToolBarView.textView.text = draft;
    }
}


-(void)initTableData {
    self.messageArray = [NSMutableArray array];
    self.timestamps = [NSMutableArray array];
    
    int count = [self.messages count];
    if (count == 0) {
        return;
    }
    
    NSDate *lastDate = nil;
    NSDate *curtDate = nil;
    NSMutableArray *msgBlockArray = nil;
    
    for (int i = count-1; i >= 0; i--) {
        IMessage *msg = [self.messages objectAtIndex:i];
        FileCache *cache = [FileCache instance];
        AudioDownloader *downloader = [AudioDownloader instance];
        if (msg.content.type == MESSAGE_AUDIO && msg.sender == self.peerUID) {
            NSString *path = [cache queryCacheForKey:msg.content.audio.url];
            if (!path && ![downloader isDownloading:msg]) {
                [downloader downloadAudio:msg];
            }
        }
        
        curtDate = [NSDate dateWithTimeIntervalSince1970: msg.timestamp];
        if ([self isSameDay:lastDate other:curtDate]) {
            [msgBlockArray insertObject:msg atIndex:0];
        } else {
            msgBlockArray  = [NSMutableArray arrayWithObject:msg];
            
            [self.messageArray insertObject:msgBlockArray atIndex:0];
            [self.timestamps insertObject:curtDate atIndex:0];
            lastDate = curtDate;
        }
    }
}

-(void)pullToRefresh {
    NSLog(@"pull to refresh...");
    [self.refreshControl endRefreshing];
    
    IMessage *last = [self.messages firstObject];
    if (last == nil) {
        return;
    }
    id<IMessageIterator> iterator =  [[PeerMessageDB instance] newPeerMessageIterator:self.peerUID last:last.msgLocalID];

    int count = 0;
    IMessage *msg = [iterator next];
    while (msg) {
        [self.messages insertObject:msg atIndex:0];
        if (++count >= PAGE_COUNT) {
            break;
        }
        msg = [iterator next];
    }
    if (count == 0) {
        return;
    }

    [self initTableData];

    [self.tableView reloadData];
    
    int section = 0;
    int row = 0;
    for (NSArray *block in self.messageArray) {
        if (count < block.count) {
            row = count;
            break;
        }
        count -= [block count];
        section++;
    }
    NSLog(@"scroll to row:%d section:%d", row, section);
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
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
    
    NSNotification* notification = [[NSNotification alloc] initWithName:CLEAR_SINGLE_CONV_NEW_MESSAGE_NOTIFY object:[NSNumber numberWithLongLong:self.peerUID] userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
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

    IMessage *msg = [[IMessage alloc] init];
    
    msg.sender = self.currentUID;
    msg.receiver = self.peerUID;
    
    MessageContent *content = [[MessageContent alloc] init];
    NSNumber *d = [NSNumber numberWithInt:self.seconds];
    NSString *url = [self localAudioURL];
    NSDictionary *dic = @{@"audio":@{@"url":url, @"duration":d}};
    NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic options:0 error:nil] encoding:NSUTF8StringEncoding];
    content.raw =  newStr;
    msg.content = content;
    msg.timestamp = (int)time(NULL);

    //todo 优化读文件次数
    NSData *data = [NSData dataWithContentsOfFile:[recorder.url path]];
    FileCache *fileCache = [FileCache instance];
    [fileCache storeFile:data forKey:url];

    [[PeerMessageDB instance] insertPeerMessage:msg uid:msg.receiver];
    
    [[Outbox instance] uploadAudio:msg];
    
    [[self class] playMessageSentSound];
    
    NSNotification* notification = [[NSNotification alloc] initWithName:SEND_FIRST_MESSAGE_OK object: msg userInfo:nil];
    
    [[NSNotificationCenter defaultCenter] postNotification:notification];
    
    [self insertMessage:msg];
}

#pragma mark - MessageObserver

-(void)onPeerMessage:(IMMessage*)im{
    if (im.sender != self.peerUID) {
        return;
    }
    [[self class] playMessageReceivedSound];
    NSLog(@"receive msg:%@",im);
    
    IMessage *m = [[IMessage alloc] init];
    m.sender = im.sender;
    m.receiver = im.receiver;
    m.msgLocalID = im.msgLocalID;
    MessageContent *content = [[MessageContent alloc] init];
    content.raw = im.content;
    m.content = content;
    m.timestamp = (int)time(NULL);

    if (m.content.type == MESSAGE_AUDIO) {
        AudioDownloader *downloader = [AudioDownloader instance];
        [downloader downloadAudio:m];
    }

    [self insertMessage:m];
}

//服务器ack
-(void)onPeerMessageACK:(int)msgLocalID uid:(int64_t)uid{
    if (uid != self.peerUID) {
        return;
    }
    IMessage *msg = [self getImMessageById:msgLocalID];
    msg.flags = msg.flags|MESSAGE_FLAG_ACK;
    [self reloadMessage:msgLocalID];
}

//接受方ack
-(void)onPeerMessageRemoteACK:(int)msgLocalID uid:(int64_t)uid{
    if (uid != self.peerUID) {
        return;
    }
    IMessage *msg = [self getImMessageById:msgLocalID];
    msg.flags = msg.flags|MESSAGE_FLAG_PEER_ACK;
    [self reloadMessage:msgLocalID];
}

-(void)onPeerMessageFailure:(int)msgLocalID uid:(int64_t)uid{
    if (uid != self.peerUID) {
        return;
    }
    IMessage *msg = [self getImMessageById:msgLocalID];
    msg.flags = msg.flags|MESSAGE_FLAG_FAILURE;
    [self reloadMessage:msgLocalID];
    
    [[PeerMessageDB instance] markPeerMessageFailure:msgLocalID uid:uid];
    
}

//对方正在输入
-(void)onPeerInputing:(int64_t)uid{
    if (uid != self.peerUID) {
        return;
    }
  
    [self.navigationBarButtonsView.conectInformationLabel setText:@"对方正在输入"];
  
    self.inputStatusTimer = [NSTimer scheduledTimerWithTimeInterval: 10
                                           target:self
                                         selector:@selector(changeStatusBack)
                                         userInfo:nil
                                        repeats:NO];
}

-(void)changeStatusBack{
    
    [self.inputStatusTimer invalidate];
    self.inputStatusTimer = nil;

    [self.navigationBarButtonsView.conectInformationLabel setText:[self getRemoteUserLastOnlineTimestamp]];
    [self.navigationBarButtonsView.conectInformationLabel setFont:[UIFont systemFontOfSize:11.0f]];
}


//同IM服务器连接的状态变更通知
-(void)onConnectState:(int)state{
    
    if (state == STATE_CONNECTING) {
        self.inputToolBarView.sendButton.enabled = NO;
        self.inputToolBarView.recordButton.enabled = NO;
        self.inputToolBarView.mediaButton.enabled = NO;
        self.inputToolBarView.userInteractionEnabled = NO;
    } else if(state == STATE_CONNECTED){
        HPGrowingTextView *textView = self.inputToolBarView.textView;
        self.inputToolBarView.sendButton.enabled = ([textView.text trimWhitespace].length > 0);
        self.inputToolBarView.recordButton.enabled = YES;
        self.inputToolBarView.mediaButton.enabled = YES;
        self.inputToolBarView.userInteractionEnabled = YES;
    } else if(state == STATE_CONNECTFAIL){
        self.inputToolBarView.sendButton.enabled = NO;
        self.inputToolBarView.recordButton.enabled = NO;
        self.inputToolBarView.mediaButton.enabled = NO;
        self.inputToolBarView.userInteractionEnabled = NO;
    } else if(state == STATE_UNCONNECTED){
        self.inputToolBarView.sendButton.enabled = NO;
        self.inputToolBarView.recordButton.enabled = NO;
        self.inputToolBarView.mediaButton.enabled = NO;
        self.inputToolBarView.userInteractionEnabled = NO;
    }
}
#pragma mark - UItableView cell process

- (void)scrollToBottomAnimated:(BOOL)animated
{
    if([self.messageArray count] == 0){
        return;
    }
    
    long lastSection = [self.messageArray count] - 1;
    NSMutableArray *array = [self.messageArray objectAtIndex: lastSection];
    long lastRow = [array count]-1;
    
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:lastRow inSection:lastSection]
						  atScrollPosition:UITableViewScrollPositionBottom
								  animated:animated];
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
        inputing.sender = self.currentUID;
        inputing.receiver =self.peerUID;
        
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
        
        message.flags |= MESSAGE_FLAG_LISTENED;
        if (message.receiver == self.currentUID) {
            [[PeerMessageDB instance] markPeerMesageListened:message.msgLocalID uid:message.sender];
            [audioView setListened];
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

- (void) handleTapImageView:(UITapGestureRecognizer*)tap{
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
    }
    BubbleMessageType msgType;

    if(message.sender == self.currentUID) {
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
    
    UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                             action:@selector(handleLongPress:)];
    [recognizer setMinimumPressDuration:0.4];
    [cell addGestureRecognizer:recognizer];
    
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

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 44;
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


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{

}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    
    
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

#pragma mark - Messages view data source

- (IMessage*)messageForRowAtIndexPath:(NSIndexPath *)indexPath{

    NSMutableArray *array = [self.messageArray objectAtIndex: indexPath.section];
    IMessage *msg =  ((IMessage*)[array objectAtIndex:indexPath.row]);
    if(msg){
        return msg;
    }
    return nil;
}


- (NSDate *)timestampForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.timestamps objectAtIndex:indexPath.row];
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

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	NSLog(@"Chose image!  Details:  %@", info);
    IMessage *msg = [[IMessage alloc] init];
    
    msg.sender = self.currentUID;
    msg.receiver = self.peerUID;
    
    MessageContent *content = [[MessageContent alloc] init];
    NSDictionary *dic = @{@"image":[self localImageURL]};
    NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic options:0 error:nil] encoding:NSUTF8StringEncoding];
    content.raw =  newStr;
    msg.content = content;
    msg.timestamp = (int)time(NULL);

    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    if (image.size.height == 0) {
        return;
    }
    
    float newHeigth = 640;
    float newWidth = newHeigth*image.size.width/image.size.height;

    UIImage *sizeImage = [image resizedImage:CGSizeMake(128, 128) interpolationQuality:kCGInterpolationDefault];
    image = [image resizedImage:CGSizeMake(newWidth, newHeigth) interpolationQuality:kCGInterpolationDefault];
    
    [[SDImageCache sharedImageCache] storeImage:image forKey:msg.content.imageURL];
    NSString *littleUrl =  [msg.content littleImageURL];
    [[SDImageCache sharedImageCache] storeImage:sizeImage forKey: littleUrl];
    
    [[PeerMessageDB instance] insertPeerMessage:msg uid:msg.receiver];
    
    [[Outbox instance] uploadImage:msg image:image];
    
    [[self class] playMessageSentSound];
    
    NSNotification* notification = [[NSNotification alloc] initWithName:SEND_FIRST_MESSAGE_OK object: msg userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
    
    [self insertMessage:msg];
	
    [self dismissViewControllerAnimated:YES completion:NULL];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    
}


- (void)sendMessage:(IMessage*)msg {
    [[PeerMessageDB instance] insertPeerMessage:msg uid:msg.receiver];
    
    Message *m = [[Message alloc] init];
    m.cmd = MSG_IM;
    IMMessage *im = [[IMMessage alloc] init];
    im.sender = msg.sender;
    im.receiver = msg.receiver;
    im.msgLocalID = msg.msgLocalID;
    im.content = msg.content.raw;
    m.body = im;
    [[IMService instance] sendPeerMessage:im];
    
    [[self class] playMessageSentSound];
    
    NSNotification* notification = [[NSNotification alloc] initWithName:SEND_FIRST_MESSAGE_OK object: msg userInfo:nil];
    
    [[NSNotificationCenter defaultCenter] postNotification:notification];
    
    [self insertMessage:msg];
}

-(void) sendTextMessage:(NSString*)text {
    IMessage *msg = [[IMessage alloc] init];
    
    msg.sender = self.currentUID;
    msg.receiver = self.peerUID;
    
    MessageContent *content = [[MessageContent alloc] init];
    NSDictionary *dic = @{@"text":text};
    NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic options:0 error:nil] encoding:NSUTF8StringEncoding];
    content.raw =  newStr;
    msg.content = content;
    msg.timestamp = (int)time(NULL);
    
    [self sendMessage:msg];
}

- (void) processConversationData{
    int count = 0;
    id<IMessageIterator> iterator =  [[PeerMessageDB instance] newPeerMessageIterator: self.peerUID];
    IMessage *msg = [iterator next];
    while (msg) {
        [self.messages insertObject:msg atIndex:0];
        if (++count >= PAGE_COUNT) {
            break;
        }
        msg = [iterator next];
    }
    
    [self initTableData];
    
}

-(void) insertMessage:(IMessage*)msg{
    NSAssert(msg.msgLocalID, @"");
    NSDate *curtDate = [NSDate dateWithTimeIntervalSince1970: msg.timestamp];
    NSMutableArray *msgBlockArray = nil;
    NSIndexPath *indexPath = nil;
    //收到第一个消息
    if ([self.messageArray count] == 0 ) {
        
        msgBlockArray = [[NSMutableArray alloc] init];
        [self.messageArray addObject: msgBlockArray];
        [msgBlockArray addObject:msg];
        
        [self.timestamps addObject: curtDate];
        
        indexPath = [NSIndexPath indexPathForRow:0 inSection:0];

    }else{
        NSDate *lastDate = [self.timestamps lastObject];
        if ([self isSameDay:lastDate other:curtDate]) {
            //same day
            msgBlockArray = [self.messageArray lastObject];
            [msgBlockArray addObject:msg];
            
            indexPath = [NSIndexPath indexPathForRow:[msgBlockArray count] - 1 inSection: [self.messageArray count] - 1];
        }else{
            //next day
            msgBlockArray = [[NSMutableArray alloc] init];
            [msgBlockArray addObject: msg];
            [self.messageArray addObject: msgBlockArray];
            [self.timestamps addObject:curtDate];
            indexPath = [NSIndexPath indexPathForRow:[msgBlockArray count] - 1 inSection: [self.messageArray count] - 1];
      
        }
    }
    
    [UIView beginAnimations:nil context:NULL];
    if (indexPath.row == 0 ) {
        
        NSUInteger sectionCount = indexPath.section;
        NSIndexSet *indices = [NSIndexSet indexSetWithIndex: sectionCount];
        [self.tableView beginUpdates];
        [self.tableView insertSections:indices withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
        
    }else{
        NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
        [indexPaths addObject:indexPath];
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
    }
    
    [self scrollToBottomAnimated:NO];
    
    [UIView commitAnimations];
}

#pragma mark - function
-(NSDateComponents*) getComponentOfDate:(NSDate *)date {
    if (date == nil) {
        return nil;
    }
    
	NSCalendar *calendar = [NSCalendar currentCalendar];
	[calendar setTimeZone:[NSTimeZone systemTimeZone]];
	NSDateComponents *comps = [[NSDateComponents alloc] init];
    NSInteger unitFlags = NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|\
        NSCalendarUnitWeekday|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond;
	comps = [calendar components:unitFlags fromDate:date];
    return comps;
}

-(NSString *) getConversationTimeString:(NSDate *)date{
    
    NSDateComponents *components = [self getComponentOfDate:date];
    NSDateComponents *todayComponents = [self getComponentOfDate:[NSDate date]];
    NSMutableString *outStr;
    
    if (components.year == todayComponents.year && components.day == todayComponents.day && components.month == todayComponents.month) {
        
        NSString *format = @"HH:mm";
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
        [formatter setDateFormat:format];
        [formatter setTimeZone:[NSTimeZone systemTimeZone]];
        
        NSString *timeStr = [formatter stringFromDate:date];
        
        if (components.hour > 11) {
            //下午
            outStr = [NSMutableString stringWithFormat:@"%@ %@",@"下午",timeStr];
        }else{
            //上午
            outStr = [NSMutableString stringWithFormat:@"%@ %@",@"上午",timeStr];
        }
        return outStr;
    }else{
        NSString *format = @"MM-dd HH:mm";
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
        [formatter setDateFormat:format];
        [formatter setTimeZone:[NSTimeZone systemTimeZone]];
        
        return [formatter stringFromDate:date];
    }
}

// 从数字获取对应的周时间字符串
-(NSString *) getWeekDayString:(int)iDay {
    switch (iDay) {
        case 1:
            return @"周日";
            break;
        case 2:
            return @"周一";
            break;
        case 3:
            return @"周二";
            break;
        case 4:
            return @"周三";
            break;
        case 5:
            return @"周四";
            break;
        case 6:
            return @"周五";
            break;
        case 7:
            return @"周六";
            break;
        default:
            return nil;
    }
    return nil;
}

-(BOOL)isSameDay:(NSDate*)date1 other:(NSDate*)date2 {
    NSDateComponents *c1 = [self getComponentOfDate:date1];
    NSDateComponents *c2 = [self getComponentOfDate:date2];
    return c1.year == c2.year && c1.month == c2.month && c1.day == c2.day;
}

-(BOOL)isYestoday:(NSDate*)date1 today:(NSDate*)date2 {
    NSDate *y = [date1 dateByAddingTimeInterval:-24*3600];
    return [self isSameDay:y other:date2];
}
-(BOOL)isBeforeYestoday:(NSDate*)date1 today:(NSDate*)date2 {
    NSDate *y = [date1 dateByAddingTimeInterval:-2*24*3600];
    return [self isSameDay:y other:date2];
}

-(BOOL)isInWeek:(NSDate*)date1 today:(NSDate*)date2 {
    NSDate *t = [date1 dateByAddingTimeInterval:-7*24*3600];
    return [t compare:date2] == NSOrderedAscending && ![self isSameDay:t other:date2];
}

-(BOOL)isInMonth:(NSDate*)date1 today:(NSDate*)date2 {
    NSDate *t = [date1 dateByAddingTimeInterval:-30*24*3600];
    return [t compare:date2] == NSOrderedAscending;
}

-(NSString*) getRemoteUserLastOnlineTimestamp{
    NSDate *lastDate =  [[NSDate alloc] initWithTimeIntervalSince1970:self.peerLastUpTimestamp];
    NSDate *todayDate = [NSDate date];
    
    NSDateComponents *upDate = [self getComponentOfDate:lastDate];
    
    NSString *timeStr = nil;
    if ([self isSameDay:lastDate other:todayDate])
        timeStr = [NSString stringWithFormat:@"最后上线时间: 今天%02zd:%02zd", upDate.hour, upDate.minute];
    else if ([self isYestoday:lastDate today:todayDate]) {
        timeStr = [NSString stringWithFormat:@"最后上线时间: 昨天%02zd:%02zd", upDate.hour, upDate.minute];
    } else if ([self isBeforeYestoday:lastDate today:todayDate]) {
        timeStr = [NSString stringWithFormat:@"最后上线时间: 前天%02zd:%02zd", upDate.hour, upDate.minute];
    } else if ([self isInWeek:lastDate today:todayDate]){
        const char *t[8] = {"", "周日", "周一", "周二", "周三", "周四", "周五", "周六"};
        timeStr = [NSString stringWithFormat:@"最后上线于%@的%02zd:%02zd", [NSString stringWithUTF8String:t[upDate.weekday]], upDate.hour, upDate.minute];
    } else if ([self isInMonth:lastDate today:todayDate]){
        timeStr = [NSString stringWithFormat:@"最后上线 %02zd-%02zd-%02zd %02zd:%02zd", upDate.year%100, upDate.month, upDate.day, upDate.hour, upDate.minute];
    } else {
        timeStr = [NSString stringWithFormat:@"最后上线%04zd年%02zd月%02zd日", upDate.year, upDate.month, upDate.day];
    }
    
    return timeStr;
}

-(void) setNormalNavigationButtons{
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"对话"
                                                             style:UIBarButtonItemStyleDone
                                                            target:self
                                                            action:@selector(returnMainTableViewController)];

    self.navigationItem.leftBarButtonItem = item;
}

- (IMessage*) getImMessageById:(int)msgLocalID{
    
    for ( long sectionIndex = [self.messageArray count] - 1; sectionIndex >= 0; sectionIndex--) {
        
        NSMutableArray *rowArrays = [self.messageArray objectAtIndex:sectionIndex];
        for (long rowindex = [rowArrays count ] - 1;rowindex >= 0 ; rowindex--) {
            
            IMessage *tmpMsg = (IMessage*) [rowArrays objectAtIndex:rowindex];
            if (tmpMsg.msgLocalID == msgLocalID) {
                return tmpMsg;
            }
        }
    }
    return nil;
}

- (NSIndexPath*) getIndexPathById:(int)msgLocalID{
    for ( long sectionIndex = [self.messageArray count] - 1; sectionIndex >= 0; sectionIndex--) {
        
        NSMutableArray *rowArrays = [self.messageArray objectAtIndex:sectionIndex];
        for (long rowindex = [rowArrays count ] - 1;rowindex >= 0 ; rowindex--) {
            
            IMMessage *tmpMsg = [rowArrays objectAtIndex:rowindex];
            if (tmpMsg.msgLocalID == msgLocalID) {
                
                NSIndexPath *findpath = [NSIndexPath indexPathForRow:rowindex inSection: sectionIndex];
                return findpath;
            }
        }
    }
    return nil;
}

- (void) reloadMessage:(int)msgLocalID{
    
    for ( long sectionIndex = [self.messageArray count] - 1; sectionIndex >= 0; sectionIndex--) {
        
        NSMutableArray *rowArrays = [self.messageArray objectAtIndex:sectionIndex];
        for (long rowindex = [rowArrays count ] - 1;rowindex >= 0 ; rowindex--) {
            
            IMMessage *tmpMsg = [rowArrays objectAtIndex:rowindex];
            if (tmpMsg.msgLocalID == msgLocalID) {
                
                NSIndexPath *findpath = [NSIndexPath indexPathForRow:rowindex inSection: sectionIndex];
                NSArray *array = [NSArray arrayWithObject:findpath];
                [self.tableView reloadRowsAtIndexPaths:array withRowAnimation:UITableViewRowAnimationNone];
            }
        }
    }
}

-(void)returnMainTableViewController {
    DraftDB *db = [DraftDB instance];
    [db setDraft:self.peerUID draft:self.inputToolBarView.textView.text];

    [[IMService instance] removeMessageObserver:self];
    [[Outbox instance] removeBoxObserver:self];
    [[AudioDownloader instance] removeDownloaderObserver:self];
//    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
//    delegate.tabBarController.selectedIndex = 2;
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - Outbox Observer
-(void)onAudioUploadSuccess:(IMessage*)msg URL:(NSString*)url {
    if (msg.receiver == self.peerUID) {
        NSIndexPath *indexPath = [self getIndexPathById:msg.msgLocalID];
        MessageViewCell *cell = (MessageViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        MessageAudioView *audioView = (MessageAudioView*)cell.bubbleView;
        [audioView setUploading:NO];
    }
}

-(void)onAudioUploadFail:(IMessage*)msg {
    if (msg.receiver == self.peerUID) {
        NSIndexPath *indexPath = [self getIndexPathById:msg.msgLocalID];
        MessageViewCell *cell = (MessageViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        MessageAudioView *audioView = (MessageAudioView*)cell.bubbleView;
        [audioView setUploading:NO];
        
        msg.flags = msg.flags|MESSAGE_FLAG_FAILURE;
        [self reloadMessage:msg.msgLocalID];
    }
}

-(void)onImageUploadSuccess:(IMessage*)msg URL:(NSString*)url {
    if (msg.receiver == self.peerUID) {
        NSIndexPath *indexPath = [self getIndexPathById:msg.msgLocalID];
        MessageViewCell *cell = (MessageViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        MessageImageView *imageView = (MessageImageView*)cell.bubbleView;
        [imageView setUploading:NO];
    }
}

-(void)onImageUploadFail:(IMessage*)msg {
    if (msg.receiver == self.peerUID) {
        NSIndexPath *indexPath = [self getIndexPathById:msg.msgLocalID];
        MessageViewCell *cell = (MessageViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        MessageImageView *imageView = (MessageImageView*)cell.bubbleView;
        [imageView setUploading:NO];
        

        msg.flags = msg.flags|MESSAGE_FLAG_FAILURE;
        [self reloadMessage:msg.msgLocalID];

    }
}

#pragma mark - Audio Downloader Observer
-(void)onAudioDownloadSuccess:(IMessage*)msg {
    if (msg.sender == self.peerUID) {
        NSIndexPath *indexPath = [self getIndexPathById:msg.msgLocalID];
        MessageViewCell *cell = (MessageViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        MessageAudioView *audioView = (MessageAudioView*)cell.bubbleView;
        [audioView setDownloading:NO];
    }
}

-(void)onAudioDownloadFail:(IMessage*)msg {
    if (msg.sender == self.peerUID) {
        NSIndexPath *indexPath = [self getIndexPathById:msg.msgLocalID];
        MessageViewCell *cell = (MessageViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        MessageAudioView *audioView = (MessageAudioView*)cell.bubbleView;
        [audioView setDownloading:NO];
    }
}
/*
 * 复用ID区分来去类型
 */
-(NSString*) getMessageViewCellId:(IMessage*)msg{
    if(msg.sender == self.currentUID){
        return [NSString stringWithFormat:@"MessageCell_%d%d", msg.content.type,BubbleMessageTypeOutgoing];
    }else{
        return [NSString stringWithFormat:@"MessageCell_%d%d", msg.content.type,BubbleMessageTypeIncoming];
    }
}

#pragma mark - MessageInputRecordDelegate

-(void) recordStart{
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

 -(void) recordCancel:(CGFloat)xMove{
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

-(void) recordEnd{
    if (self.recorder.recording) {
        NSLog(@"stop record...");
        [self stopRecord];
    }
}

- (void)resend:(id)sender
{
    
    [self resignFirstResponder];
    
    NSLog(@"resend...");
    if (self.selectedMessage == nil) {
        return;
    }
    
    IMessage *message = self.selectedMessage;
    message.flags = message.flags & (~MESSAGE_FLAG_FAILURE);
    PeerMessageDB *db = [PeerMessageDB instance];
    [db erasePeerMessageFailure:message.msgLocalID uid:message.receiver];

    if (message.content.type == MESSAGE_AUDIO) {
        [[Outbox instance] uploadAudio:message];
    } else if (message.content.type == MESSAGE_IMAGE) {
        UIImage *image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:message.content.imageURL];
        if (!image) {
            return;
        }
        [[Outbox instance] uploadImage:message image:image];
    } else {
        Message *m = [[Message alloc] init];
        m.cmd = MSG_IM;
        IMMessage *im = [[IMMessage alloc] init];
        im.sender = message.sender;
        im.receiver = message.receiver;
        im.msgLocalID = message.msgLocalID;
        im.content = message.content.raw;
        m.body = im;
        [[IMService instance] sendPeerMessage:im];
    }
    
    if (self.selectedCell == nil) {
        return;
    }
    int row = self.selectedCell.tag & 0xffff;
    int section = (int)(self.selectedCell.tag >> 16);
    NSIndexPath *findpath = [NSIndexPath indexPathForRow:row inSection:section];
    NSArray *array = [NSArray arrayWithObject:findpath];
    [self.tableView reloadRowsAtIndexPaths:array withRowAnimation:UITableViewRowAnimationNone];
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


+ (void)playSoundWithName:(NSString *)name type:(NSString *)type {
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:type];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        SystemSoundID sound;
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:path], &sound);
        AudioServicesPlaySystemSound(sound);
    }
    else {
        NSLog(@"Error: audio file not found at path: %@", path);
    }
}

+ (void)playMessageReceivedSound {
    [self playSoundWithName:@"messageReceived" type:@"aiff"];
}

+ (void)playMessageSentSound {
    [self playSoundWithName:@"messageSent" type:@"aiff"];
}

@end
