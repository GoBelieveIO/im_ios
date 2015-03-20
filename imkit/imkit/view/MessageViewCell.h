
#import <UIKit/UIKit.h>
#import "BubbleView.h"
#import "IMessage.h"

#define NAME_LABEL_HEIGHT 20

@interface MessageViewCell : UITableViewCell

@property (strong, nonatomic) BubbleView *bubbleView;
@property (strong, nonatomic) UILabel *nameLabel;
-(id)initWithType:(int)type reuseIdentifier:(NSString *)reuseIdentifier;

- (void) setMessage:(IMessage *)message msgType:(BubbleMessageType)msgType;
- (void) setMessage:(IMessage *)message userName:(NSString*)name msgType:(BubbleMessageType)msgType;
@end