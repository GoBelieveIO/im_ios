//
//  TextMessageViewController.m
//  imkit
//
//  Created by houxh on 15/3/16.
//  Copyright (c) 2015年 beetle. All rights reserved.
//

#import "TextMessageViewController.h"
#import <imsdk/IMService.h>

#import "IMessage.h"
#import "PeerMessageDB.h"
#import "MessageTableSectionHeaderView.h"
#import "MessageViewCell.h"
#import "Constants.h"

#define PAGE_COUNT 10

#define INPUT_HEIGHT 52.0f

#define navBarHeadButtonSize 35

#define kTakePicActionSheetTag  101


@interface TextMessageViewController()

@property (strong, nonatomic) UIView *inputBar;
@property (strong, nonatomic) UIButton *sendButton;
@property (strong, nonatomic) UITextField *inputTextField;
@property (strong, nonatomic) UITableView *tableView;

@property (strong, nonatomic) NSMutableArray *messageArray;
@property (strong, nonatomic) NSMutableArray *timestamps;
@property (strong, nonatomic) NSMutableArray *messages;


@property(nonatomic) UIRefreshControl *refreshControl;


- (void)setup;

#pragma mark - Actions
- (void)sendPressed:(UIButton *)sender;

#pragma mark - Messages view controller
- (void)scrollToBottomAnimated:(BOOL)animated;

#pragma mark - Keyboard notifications
- (void)handleWillShowKeyboard:(NSNotification *)notification;
- (void)handleWillHideKeyboard:(NSNotification *)notification;
@end


@implementation TextMessageViewController


-(id) init {
    if (self = [super init]) {
        self.messages = [NSMutableArray array];
    }
    return self;
}


#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setup];
    
    [self setNormalNavigationButtons];
    
    self.navigationItem.title = self.peerName;
    [self processConversationData];
    //content scroll to bottom
    [self.tableView reloadData];
    [self.tableView setContentOffset:CGPointMake(0, CGFLOAT_MAX)];
    
    [[IMService instance] addMessageObserver:self];
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
    
    UIView *inputBar = [[UIView alloc] initWithFrame:inputFrame];

    UIImageView *bkview = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    UIImage *img = [UIImage imageNamed:@"input-bar-flat.png"];
    UIImage *stretchImg = [img stretchableImageWithLeftCapWidth:1 topCapHeight:5];
    [bkview setImage:stretchImg];
    [self.inputBar addSubview:bkview];
    
    inputBar.backgroundColor = [UIColor whiteColor];
    inputBar.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin);
    inputBar.opaque = YES;
    
    
    CGRect frame = CGRectMake(4, 6, inputFrame.size.width - 64, 40);
    UITextField *textField = [[UITextField alloc] initWithFrame:frame];
    
    textField.backgroundColor = [UIColor clearColor];
    [textField setFont:[UIFont systemFontOfSize:16]];
    textField.layer.borderColor = [[UIColor colorWithWhite:.8 alpha:1.0] CGColor];
    textField.layer.borderWidth = 0.65f;
    textField.layer.cornerRadius = 6.0f;
    
    [inputBar addSubview:textField];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    frame = CGRectMake(inputFrame.size.width - 60, 6, 60, 40);
    button.frame = frame;
    [button setTitle:@"发送" forState:UIControlStateNormal];
    
    [button addTarget:self action:@selector(sendPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [inputBar addSubview:button];
    
    [self.view addSubview:inputBar];
    
    self.sendButton = button;
    self.inputTextField = textField;
    self.inputBar = inputBar;
    
    if ([[IMService instance] connectState] == STATE_CONNECTED) {
        [self enableSend];
    } else {
        [self disableSend];
    }
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
    [self.tableView addGestureRecognizer:tapRecognizer];
    tapRecognizer.numberOfTapsRequired = 1;
    tapRecognizer.delegate  = self;
}

- (void) processConversationData{
    int count = 0;
    id<IMessageIterator> iterator =  [[PeerMessageDB instance] newPeerMessageIterator: self.peerUID];
    IMessage *msg = [iterator next];
    while (msg) {
        if (msg.content.type == MESSAGE_TEXT) {
            [self.messages insertObject:msg atIndex:0];
            if (++count >= PAGE_COUNT) {
                break;
            }
        }
        msg = [iterator next];
    }
    
    [self initTableData];
    
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
    [self setEditing:NO animated:YES];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
    NSNotification* notification = [[NSNotification alloc] initWithName:CLEAR_SINGLE_CONV_NEW_MESSAGE_NOTIFY object:[NSNumber numberWithLongLong:self.peerUID] userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)dealloc
{
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.tableView = nil;

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


#pragma mark -
- (void) handlePanFrom:(UITapGestureRecognizer*)recognizer{
    [self.inputTextField resignFirstResponder];
}

#pragma mark - Actions
- (void)sendPressed:(UIButton *)sender
{
    NSString *text = self.inputTextField.text;
    if (text.length == 0) {
        return;
    }
    
    [self sendTextMessage:text];
    
    self.inputTextField.text = @"";
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
    
    CGRect tableViewFrame = CGRectMake(0.0f,  0.0f, w,  h - INPUT_HEIGHT - keyboardRect.size.height);
    CGFloat y = h - keyboardRect.size.height;
    y -= INPUT_HEIGHT;
    CGRect inputViewFrame = CGRectMake(0, y, self.inputBar.frame.size.width, INPUT_HEIGHT);
    self.inputBar.frame = inputViewFrame;
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
    
    CGRect inputViewFrame = CGRectOffset(self.inputBar.frame, 0, keyboardRect.size.height);
    CGRect tableViewFrame = self.tableView.frame;
    tableViewFrame.size.height += keyboardRect.size.height;
    
    self.inputBar.frame = inputViewFrame;
    self.tableView.frame = tableViewFrame;
    
    [self scrollToBottomAnimated:NO];
    [UIView commitAnimations];
}


#pragma mark - MessageObserver

-(void)onPeerMessage:(IMMessage*)im{
    if (im.sender != self.peerUID) {
        return;
    }
    NSLog(@"receive msg:%@",im);
    
    IMessage *m = [[IMessage alloc] init];
    m.sender = im.sender;
    m.receiver = im.receiver;
    m.msgLocalID = im.msgLocalID;
    MessageContent *content = [[MessageContent alloc] init];
    content.raw = im.content;
    m.content = content;
    m.timestamp = (int)time(NULL);
    
    if (m.content.type != MESSAGE_TEXT) {
        return;
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
}

-(void)disableSend {
    self.sendButton.enabled = NO;
}

-(void)enableSend {
    self.sendButton.enabled = YES;
}

//同IM服务器连接的状态变更通知
-(void)onConnectState:(int)state{
    if(state == STATE_CONNECTED){
        [self enableSend];
    } else {
        [self disableSend];
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
    }
    BubbleMessageType msgType;
    
    if(message.sender == self.currentUID) {
        msgType = BubbleMessageTypeOutgoing;
    }else{
        msgType = BubbleMessageTypeIncoming;
    }
    
    [cell setMessage:message msgType:msgType];
    
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


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
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
    NSString *format = @"MM-dd HH:mm";
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
    [formatter setDateFormat:format];
    [formatter setTimeZone:[NSTimeZone systemTimeZone]];
    
    return [formatter stringFromDate:date];
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
    [[IMService instance] removeMessageObserver:self];
    [self.navigationController popToRootViewControllerAnimated:YES];
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


@end
