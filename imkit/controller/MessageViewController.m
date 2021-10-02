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
#import <Masonry/Masonry.h>

#define INPUT_HEIGHT 52.0f

#define kTakePicActionSheetTag  101

#define FILE_SIZE_LIMIT 16*1024*1024

@interface MessageViewController()<LocationPickerControllerDelegate,
                                    EaseChatBarMoreViewDelegate,
                                    EMChatToolbarDelegate,
                                    UIImagePickerControllerDelegate,
                                    UIDocumentPickerDelegate,
                                    UINavigationControllerDelegate,
                                    UIGestureRecognizerDelegate,
                                    AVAudioRecorderDelegate,
                                    UITableViewDataSource,
                                    UITableViewDelegate>
@property(strong, nonatomic) EaseChatBarMoreView *chatBarMoreView;
@property(strong, nonatomic) EaseRecordView *recordView;


@property(nonatomic) AVAudioRecorder *recorder;
@property(nonatomic) NSTimer *recordingTimer;
@property(nonatomic) NSTimer *updateMeterTimer;
@property(nonatomic, assign) int seconds;
@property(nonatomic) BOOL recordCanceled;


@property(nonatomic) BOOL firstAppeared;
@end

@implementation MessageViewController


- (id)init {
    if (self = [super init]) {
        self.callEnabled = YES;
        self.isShowReply = YES;
        self.isShowReaded = YES;
        self.isShowUserName = NO;
    }
    return self;
}

#pragma mark - View lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.firstAppeared = NO;
    self.hasLaterMore = self.messageID > 0 ;
    self.hasEarlierMore = YES;
    [self loadData];
    [self setup];
    
    [self addObserver];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 50;
    [self.tableView reloadData];
    if (self.messageID > 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSInteger index = [self.messages indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                IMessage *m = (IMessage*)obj;
                if (m.msgId == self.messageID) {
                    *stop = YES;
                    return YES;
                }
                return NO;
            }];
            
            if (index != NSNotFound) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
            }
        });
    } else if (self.messages.count > 0){

        dispatch_async(dispatch_get_main_queue(), ^{
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(self.messages.count-1) inSection:0];
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
        });
       
   
    }
}

#pragma mark - View lifecycle
-(void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    if (!self.firstAppeared && self.messageID > 0) {
        NSInteger index = [self.messages indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            IMessage *m = (IMessage*)obj;
            if (m.msgId == self.messageID) {
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
    
    if (@available(iOS 13.0,*)) {
        self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    } else {
        self.view.backgroundColor = RGBACOLOR(235, 235, 235, 1);
    }

	self.tableView = [[UITableView alloc] initWithFrame:tableFrame style:UITableViewStylePlain];
	self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    
    if (self.tableHeaderView) {
        self.tableView.tableHeaderView = self.tableHeaderView;
    } else {
        UIView *refreshView = [[UIView alloc] initWithFrame:CGRectMake(0, 55, 0, 0)];
        self.tableView.tableHeaderView = refreshView;
        self.refreshControl = [[UIRefreshControl alloc] init];
        [self.refreshControl addTarget:self action:@selector(pullToRefresh) forControlEvents:UIControlEventValueChanged];
        [refreshView addSubview:self.refreshControl];
    }
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
- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
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
    dispatch_async(dispatch_get_main_queue(), ^{
        int section = 0;
        NSLog(@"scroll to row:%d section:%d", row, section);
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    });
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

- (void)openURL:(NSString*)u {
    NSURL *url = [NSURL URLWithString:u];
    if (![[UIApplication sharedApplication] canOpenURL:url]) {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", u]];
        if (![[UIApplication sharedApplication] canOpenURL:url]) {
            NSLog(@"can't open url:%@", u);
            return;
        }
    }
    if (@available(iOS 10.0, *)) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [[UIApplication sharedApplication] openURL:url];
#pragma clang diagnostic pop
    }
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
    
    NSLog(@"record...");
    
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
        [self.view makeToast:NSLocalizedString(@"message.recordTimeShort", nil) duration:0.7 position:CSToastPositionBottom];
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


-(void)onReply:(UIButton*)btn {
    int row = btn.tag & 0xffff;
    int section = (int)(btn.tag >> 16);
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    IMessage *message = [self getMessageWithIndex:indexPath.row];
    if (message == nil) {
        return;
    }
    
    [self openReply:message];
}

-(void)AudioAction:(UIButton*)btn{
    int row = btn.tag & 0xffff;
    int section = (int)(btn.tag >> 16);
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    IMessage *message = [self getMessageWithIndex:indexPath.row];
    if (message == nil) {
        return;
    }
    [self handleMesageClick:message view:btn];
}

-(void)handleUnreadClick:(UIButton*)btn {
    int row = btn.tag & 0xffff;
    int section = (int)(btn.tag >> 16);
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    IMessage *message = [self getMessageWithIndex:indexPath.row];
    if (message == nil) {
        return;
    }
    [self openUnread:message];
}

-(void)handleMessageViewClick:(UITapGestureRecognizer*)tap {
    int row = tap.view.tag & 0xffff;
    int section = (int)(tap.view.tag >> 16);
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    IMessage *message = [self getMessageWithIndex:indexPath.row];
    if (message == nil) {
        return;
    }
    
    [self handleMesageClick:message view:tap.view];
}

-(void)handleTextDoubleClick:(UITapGestureRecognizer*)tap {
    if (tap.state == UIGestureRecognizerStateRecognized) {
        NSLog(@"text double click");
    }
    int row = tap.view.tag & 0xffff;
    int section = (int)(tap.view.tag >> 16);
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    IMessage *message = [self getMessageWithIndex:indexPath.row];
    if (message == nil) {
        return;
    }

    [self handleMessageDoubleClick:message];
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



#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    IMessage *message = [self getMessageWithIndex:indexPath.row];
    if (message == nil) {
        return nil;
    }
    NSString *CellID = [self getMessageViewCellId:message];
    MessageViewCell *cell = (MessageViewCell *)[tableView dequeueReusableCellWithIdentifier:CellID];
    if(!cell) {
        if (message.notificationContent) {
           cell = [[MessageNotificationCell alloc] initWithType:message.type reuseIdentifier:CellID];
        } else if (message.isOutgoing) {
            OutMessageCell *outCell = [[OutMessageCell alloc] initWithType:message.type
                                                                 showReply:self.isShowReply
                                                                showReaded:self.isShowReaded
                                                           reuseIdentifier:CellID];
            [outCell.readedButton addTarget:self action:@selector(handleUnreadClick:) forControlEvents:UIControlEventTouchUpInside];
            cell = outCell;
        } else {
            InMessageCell *inCell = [[InMessageCell alloc] initWithType:message.type
                                                               showName:self.isShowUserName
                                                              showReply:self.isShowReply
                                                        reuseIdentifier:CellID];
            cell = inCell;
        }
        
        if (cell.replyButton) {
            [cell.replyButton addTarget:self action:@selector(onReply:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        if (message.type == MESSAGE_AUDIO) {
            MessageAudioView *audioView = (MessageAudioView*)cell.bubbleView;
            [audioView.playBtn addTarget:self action:@selector(AudioAction:) forControlEvents:UIControlEventTouchUpInside];
        } else if (message.type == MESSAGE_TEXT) {
            MessageTextView *textView = (MessageTextView*)cell.bubbleView;
            
            textView.label.urlLinkTapHandler = ^(KILabel *label, NSString *string, NSRange range) {
                NSLog(@"URL tapped %@", string);
                [self openURL:string];
            };
            
            UITapGestureRecognizer *tap  = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTextDoubleClick:)];
            tap.numberOfTapsRequired = 2;
            [textView.label addGestureRecognizer:tap];
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
        [cell.bubbleView addGestureRecognizer:recognizer];
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
    if ([cell isKindOfClass:[OutMessageCell class]]) {
        OutMessageCell *outCell = (OutMessageCell*)cell;
        outCell.readedButton.tag = tag;
    }
    cell.replyButton.tag = tag;
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
        int r = [self loadLaterData];
        if (r) {
            [self.tableView reloadData];
        }
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

#pragma mark - UIDocumentPickerDelegate
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    //获取授权
    BOOL fileUrlAuthozied = [urls.firstObject startAccessingSecurityScopedResource];
    if (fileUrlAuthozied) {
        //通过文件协调工具来得到新的文件地址，以此得到文件保护功能
        NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
        NSError *error;
        
        [fileCoordinator coordinateReadingItemAtURL:urls.firstObject options:0 error:&error byAccessor:^(NSURL *newURL) {
            //读取文件
            NSNumber *fileSizeValue = nil;
            BOOL r = [newURL getResourceValue:&fileSizeValue
                                       forKey:NSURLFileSizeKey
                                        error:nil];
            if (!r) {
                [self.view makeToast:@"文件访问失败" duration:0.7 position:CSToastPositionBottom];
                return;
            }
            
            if ([fileSizeValue longLongValue] > FILE_SIZE_LIMIT) {
                NSLog(@"file size too large");
                NSString *warning = [NSString stringWithFormat:@"文件大小不能超过%dM", FILE_SIZE_LIMIT/(1024*1024)];
                [self.view makeToast:warning duration:0.7 position:CSToastPositionBottom];
                return;
            }
            [self sendFileMessage:newURL];
            [self dismissViewControllerAnimated:YES completion:NULL];
        }];
        [urls.firstObject stopAccessingSecurityScopedResource];
    } else {
        //授权失败
    }
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
            NSLog(@"record permission granted:%d", granted);
        }];
    } else if (recordPermission == AVAudioSessionRecordPermissionDenied) {
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

-(void)forward:(id)sender {
    
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

#pragma mark - Gestures
- (void)handleLongPress:(UILongPressGestureRecognizer *)longPress {
    int row = longPress.view.tag & 0xffff;
    int section = (int)(longPress.view.tag >> 16);
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    IMessage *message = [self getMessageWithIndex:indexPath.row];
    if (message == nil) {
        return;
    }
    MessageViewCell *cell = (MessageViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    
    if(longPress.state != UIGestureRecognizerStateBegan
       || ![self becomeFirstResponder])
        return;
   
    NSMutableArray *menuItems = [self getMessageMenuItems:message];
    if ([menuItems count] == 0) {
        return;
    }
    
    self.selectedMessage = message;
    self.selectedCell = cell;

    UIMenuController *menu = [UIMenuController sharedMenuController];
    menu.menuItems = menuItems;
    CGRect targetRect = [cell convertRect:cell.bubbleView.bounds
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


/**
 *  按下录音按钮开始录音
 */
- (void)didStartRecordingVoiceAction {
    NSLog(@"didStartRecordingVoiceAction");
    [self.recordView recordButtonTouchDown];
    self.recordView.center = self.view.center;
    [self.view addSubview:self.recordView];
    [self.view bringSubviewToFront:self.recordView];
    [self recordStart];
}

/**
 *  手指向上滑动取消录音
 */
- (void)didCancelRecordingVoiceAction {
    [self.recordView removeFromSuperview];
    [self recordCancel];
}

/**
 *  松开手指完成录音
 */
- (void)didFinishRecoingVoiceAction {
    [self.recordView removeFromSuperview];
    [self recordEnd];
}

- (void)didDragInsideAction {
    [self.recordView recordButtonDragInside];
}

- (void)didDragOutsideAction{
    [self.recordView recordButtonDragOutside];
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
        picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
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

- (void)moreViewFileAction:(EaseChatBarMoreView *)moreView {
    NSArray *types = @[@"public.item"];
    UIDocumentPickerViewController *documentPickerVC = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:types inMode:UIDocumentPickerModeOpen];
    //设置代理
    documentPickerVC.delegate = self;
    //设置模态弹出方式
    documentPickerVC.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:documentPickerVC animated:YES completion:nil];
}

- (void)call {
    
}

- (void)openUnread:(IMessage*)msg {
    
}

- (void)openReply:(IMessage*)msg {
    
}

-(NSMutableArray*)getMessageMenuItems:(IMessage*)message {
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
    
    return menuItems;
       
}

@end
