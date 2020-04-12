//
//  FileViewController.h
//  gobelieve
//
//  Created by houxh on 2018/5/27.
//

#import <UIKit/UIKit.h>
@class IMessage;
@protocol FileDownloadViewControllerDelegate<NSObject>
-(void)fileDownloadSuccess:(NSString*)url message:(IMessage*)msg;
@end

@interface FileDownloadViewController : UIViewController
@property(nonatomic) NSString *url;
@property(nonatomic) int size;
@property(nonatomic) IMessage *message;
@property(nonatomic, weak) id<FileDownloadViewControllerDelegate> delegate;
@end
