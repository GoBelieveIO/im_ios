/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "BaseMessageViewController.h"
#import <AudioToolbox/AudioServices.h>
#import "IMessage.h"

#import "NSDate+Format.h"

@interface BaseMessageViewController ()

@end

@implementation BaseMessageViewController

- (id)init {
    self = [super init];
    if (self) {
        self.messages = [NSMutableArray array];
        self.attachments = [NSMutableDictionary dictionary];
    }
    return self;
}


-(void)saveMessageAttachment:(IMessage*)msg address:(NSString*)address {
    [self.messageDB saveMessageAttachment:msg address:address];
}


-(BOOL)saveMessage:(IMessage*)msg {
    return [self.messageDB saveMessage:msg];
}

-(BOOL)removeMessage:(IMessage*)msg {
    return [self.messageDB removeMessage:msg];
}

-(BOOL)markMessageFailure:(IMessage*)msg {
    return [self.messageDB markMessageFailure:msg];
    
}

-(BOOL)markMesageListened:(IMessage*)msg {
    return [self.messageDB markMesageListened:msg];
    
}

-(BOOL)eraseMessageFailure:(IMessage*)msg {
    return [self.messageDB eraseMessageFailure:msg];
}


- (void)viewDidLoad {
    [super viewDidLoad];
}


-(void)initTableViewData {
    NSMutableArray *newMessages = [NSMutableArray array];
    NSDate *lastDate = nil;
    
    NSInteger count = [self.messages count];
    if (count == 0) {
        return;
    }
    
    for (NSInteger i = 0; i < count; i++) {
        IMessage *msg = [self.messages objectAtIndex:i];
        if (msg.type == MESSAGE_TIME_BASE) {
            continue;
        }
        
        if (lastDate == nil || msg.timestamp - lastDate.timeIntervalSince1970 > 1*60) {
            MessageTimeBaseContent *tb = [[MessageTimeBaseContent alloc] initWithTimestamp:msg.timestamp];
            tb.notificationDesc = [[NSDate dateWithTimeIntervalSince1970:tb.timestamp] formatSectionTime];
            IMessage *m = [[IMessage alloc] init];
            m.content = tb;
            [newMessages addObject:m];
            lastDate = [NSDate dateWithTimeIntervalSince1970:msg.timestamp];
        }
        
        [newMessages addObject:msg];
    }
    
    self.messages = newMessages;
}

-(void)insertMessages:(NSArray*)messages {
    NSTimeInterval lastDate = 0;
    NSInteger count = [self.messages count];
    
    for (NSInteger i = count; i > 0; i--) {
        IMessage *m = [self.messages objectAtIndex:i-1];
        if (m.type == MESSAGE_TIME_BASE) {
            lastDate = m.timeBaseContent.timestamp;
            break;
        }
    }
    
    for (IMessage *msg in messages) {
        if (msg.timestamp - lastDate > 1*60) {
            MessageTimeBaseContent *tb = [[MessageTimeBaseContent alloc] initWithTimestamp:msg.timestamp];
            tb.notificationDesc = [[NSDate dateWithTimeIntervalSince1970:tb.timestamp] formatSectionTime];
            IMessage *m = [[IMessage alloc] init];
            m.content = tb;
            [self.messages addObject:m];
            
            lastDate = msg.timestamp;
        }
        [self.messages addObject:msg];
    }
    
    if (messages.count > 0) {
        [self.tableView reloadData];
    }
}

- (void)insertMessage:(IMessage*)msg {
    NSDate *lastDate = nil;
    NSInteger count = [self.messages count];
    
    for (NSInteger i = count; i > 0; i--) {
        IMessage *m = [self.messages objectAtIndex:i-1];
        if (m.type == MESSAGE_TIME_BASE) {
            lastDate = [NSDate dateWithTimeIntervalSince1970:m.timeBaseContent.timestamp];
            break;
        }
    }
    
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    if (lastDate == nil || msg.timestamp - lastDate.timeIntervalSince1970 > 1*60) {
        MessageTimeBaseContent *tb = [[MessageTimeBaseContent alloc] initWithTimestamp:msg.timestamp];
        tb.notificationDesc = [[NSDate dateWithTimeIntervalSince1970:tb.timestamp] formatSectionTime];
        IMessage *m = [[IMessage alloc] init];
        m.content = tb;
        [self.messages addObject:m];
        NSIndexPath *indexPath = nil;
        indexPath = [NSIndexPath indexPathForRow:self.messages.count - 1 inSection:0];
        [indexPaths addObject:indexPath];
    }
    [self.messages addObject:msg];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.messages.count - 1 inSection:0];
    [indexPaths addObject:indexPath];

    [UIView beginAnimations:nil context:NULL];
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    [self scrollToBottomAnimated:NO];
    [UIView commitAnimations];

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

- (IMessage*)messageForRowAtIndexPath:(NSIndexPath *)indexPath {
    IMessage *msg = [self.messages objectAtIndex: indexPath.row];
    return msg;
}

- (IMessage*)getMessageWithID:(int)msgLocalID {
    for (IMessage *msg in self.messages) {
        if (msg.msgLocalID == msgLocalID) {
            return msg;
        }
    }
    return nil;
}

- (IMessage*)getMessageWithUUID:(NSString*)uuid {
    for (IMessage *msg in self.messages) {
        if ([msg.uuid isEqualToString:uuid]) {
            return msg;
        }
    }
    return nil;
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
