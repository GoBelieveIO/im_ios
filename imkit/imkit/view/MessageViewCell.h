
#import <UIKit/UIKit.h>
#import "BubbleView.h"
#import "IMessage.h"


@interface MessageViewCell : UITableViewCell

@property (strong, nonatomic) BubbleView *bubbleView;

-(id)initWithType:(int)type reuseIdentifier:(NSString *)reuseIdentifier;

- (void) setMessage:(IMessage *)message msgType:(BubbleMessageType)msgType;
@end