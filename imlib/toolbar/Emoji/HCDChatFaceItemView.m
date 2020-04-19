//
//  HCDChatFaceItemView.m
//  WeChatInputBar
//
//  Created by hcd on 2018/11/5.
//  Copyright © 2018 hcd. All rights reserved.
//

#import "HCDChatFaceItemView.h"
#import "HCDChatFace.h"
#import "HCDChatInputBarDefine.h"
#import "UIView+HCD_Extension.h"

@interface HCDChatFaceItemView ()
@property (nonatomic, strong) UIButton *delButton;
@property (nonatomic, strong) NSMutableArray *faceViewArray;
@end

@implementation HCDChatFaceItemView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self addSubview:self.delButton];
    }
    return self;
}

#pragma mark - Public Methods
- (void)showFaceGroup:(HCDChatFaceGroup *)group formIndex:(int)fromIndex count:(int)count {
    int index = 0;
    float spaceX = 12;
    float spaceY = 10;
    int row = (group.faceType == HCDFaceTypeEmoji ? 3 : 2);
    int col = (group.faceType == HCDFaceTypeEmoji ? 8 : 4);
    float w = (SCREEN_WIDTH - spaceX * 2) / col;
    float h = (self.height - spaceY * (row - 1)) / row;
    float x = spaceX;
    float y = spaceY;
    for (int i = fromIndex; i < fromIndex + count; i ++) {
        UIButton *button;
        if (index < self.faceViewArray.count) {
            button = [self.faceViewArray objectAtIndex:index];
        } else {
            button = [[UIButton alloc] init];
            [button addTarget:_target action:_action forControlEvents:_controlEvents];
            [self addSubview:button];
            [self.faceViewArray addObject:button];
        }
        
        index ++;
        if (i >= group.facesArray.count || i < 0) {
            [button setHidden:YES];
        } else {
            HCDChatFace  *face = [group.facesArray objectAtIndex:i];
            button.tag = i;
            
            if (face.emoji.length > 0) {
                [button setTitle:face.emoji forState:UIControlStateNormal];
            } else {
                [button setImage:[UIImage imageNamed:face.faceName] forState:UIControlStateNormal];
            }
            [button setFrame:CGRectMake(x, y, w, h)];
            [button setHidden:NO];
            x = (index % col == 0 ? spaceX: x + w);
            y = (index % col == 0 ? y + h : y);
            
        }
    }
    [_delButton setHidden:fromIndex >= group.facesArray.count];
    [_delButton setFrame:CGRectMake(x, y, w, h)];
}

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents {
    _target = target;
    _action = action;
    _controlEvents = controlEvents;
    [self.delButton addTarget:_target action:_action forControlEvents:_controlEvents];
    for (UIButton *button in self.faceViewArray) {
        [button addTarget:target action:action forControlEvents:controlEvents];
    }
}

#pragma mark - Getter
- (NSMutableArray *)faceViewArray {
    if (_faceViewArray == nil) {
        _faceViewArray = [[NSMutableArray alloc] init];
    }
    return _faceViewArray;
}

- (UIButton *)delButton {
    if (_delButton == nil) {
        _delButton = [[UIButton alloc] init];
        _delButton.tag = -1;
        [_delButton setImage:[UIImage imageNamed:@"DeleteEmoticonBtn"] forState:UIControlStateNormal];
    }
    return _delButton;
}

@end
