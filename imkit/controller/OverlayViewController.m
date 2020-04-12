//
//  OverlayViewController.m
//  gobelieve
//
//  Created by houxh on 2017/12/5.
//

#import "OverlayViewController.h"
#import "OverlayLabel.h"

@interface OverlayViewController ()

@end

@implementation OverlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.modalPresentationCapturesStatusBarAppearance = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIEdgeInsets myLabelInsets = {0, 10, 0, 10};
    CGRect f = UIEdgeInsetsInsetRect(self.view.bounds, myLabelInsets);
    
    OverlayLabel *label = [[OverlayLabel alloc] initWithFrame:f];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor whiteColor];
    label.numberOfLines = 0;
    label.userInteractionEnabled = YES;
    label.font = [UIFont systemFontOfSize:24.0f];
    
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:self.text attributes:[label attributesFromProperties]];
    NSArray *linkRanges = [label getRangesForURLs:attributedText];
    NSAttributedString *attributedString = [label addLinkAttributesToAttributedString:attributedText linkRanges:linkRanges];
    label.attributedText = attributedString;
    
    UITapGestureRecognizer *tap  = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tap.numberOfTapsRequired = 1;
    [label addGestureRecognizer:tap];
    
    [self.view addSubview:label];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)handleTap:(UIGestureRecognizer*)ges {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}



@end
