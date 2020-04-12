/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "TextMessageViewController.h"
#import "IMService.h"

#import "IMessage.h"
#import "PeerMessageDB.h"
#import "MessageNotificationCell.h"
#import "OutMessageCell.h"
#import "InMessageCell.h"
#import "MessageViewCell.h"
#import "MessageTextView.h"
#import "NSDate+Format.h"

#define NAME_LABEL_HEIGHT 20

#define INPUT_HEIGHT 52.0f

#define navBarHeadButtonSize 35

#define kTakePicActionSheetTag  101


@interface TextMessageViewController()

@property (strong, nonatomic) UIView *inputBar;
@property (strong, nonatomic) UIButton *sendButton;
@property (strong, nonatomic) UITextField *inputTextField;

- (void)setup;

#pragma mark - Actions
- (void)sendPressed:(UIButton *)sender;

#pragma mark - Keyboard notifications
- (void)handleWillShowKeyboard:(NSNotification *)notification;
- (void)handleWillHideKeyboard:(NSNotification *)notification;

@end


@implementation TextMessageViewController


-(id) init {
    if (self = [super init]) {

    }
    return self;
}


#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setup];


    [self loadData];
    //content scroll to bottom
    [self.tableView reloadData];
    [self.tableView setContentOffset:CGPointMake(0, CGFLOAT_MAX)];
}

- (void)setup {
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = RGBACOLOR(235, 235, 237, 1);
    
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    int w = CGRectGetWidth(screenBounds);
    int h = CGRectGetHeight(screenBounds);
    
    CGRect tableFrame = CGRectMake(0.0f, 0, w, h - INPUT_HEIGHT);
    CGRect inputFrame = CGRectMake(0.0f, h - INPUT_HEIGHT, w, INPUT_HEIGHT);

    
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

- (void)pullToRefresh {
    NSLog(@"pull to refresh...");
    [self.refreshControl endRefreshing];
    [self loadEarlierData];
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

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
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


- (void)scrollToBottomAnimated:(BOOL)animated
{
    if (self.messages.count == 0) {
        return;
    }
    long lastRow = [self.messages count] - 1;
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:lastRow inSection:0]
                          atScrollPosition:UITableViewScrollPositionBottom
                                  animated:animated];
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
    
    int y = 0;
    
    CGRect tableViewFrame = CGRectMake(0.0f,  y, w,  h - INPUT_HEIGHT - keyboardRect.size.height - y);
    y = h - keyboardRect.size.height;
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

- (void)setDraft:(NSString*)text {
    self.inputTextField.text = text;
}
- (NSString*)getDraft {
    return self.inputTextField.text;
}

- (void)disableSend {
    self.sendButton.enabled = NO;
}

- (void)enableSend {
    self.sendButton.enabled = YES;
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
    }
    
    cell.msg = message;
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
    if (self.isShowUserName && msg.isIncomming) {
        nameHeight = NAME_LABEL_HEIGHT;
    }
    
    switch (msg.type) {
        case MESSAGE_TEXT:
            return [MessageViewCell cellHeightMessage:msg] + nameHeight;
        case MESSAGE_TIME_BASE:
        case MESSAGE_GROUP_NOTIFICATION:
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
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 0;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
}

/*
 * 复用ID区分来去类型
 */
- (NSString*)getMessageViewCellId:(IMessage*)msg{
    if(msg.isOutgoing) {
        return [NSString stringWithFormat:@"MessageCell_%d%d", msg.type, 0];
    } else {
        return [NSString stringWithFormat:@"MessageCell_%d%d", msg.type, 1];
    }
}


-(void) sendTextMessage:(NSString*)text {
    
}

- (void)downloadMessageContent:(IMessage*)message {
    
}

- (void)downloadMessageContent:(NSArray*)messages count:(int)count {
    
}

@end
