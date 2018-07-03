/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */


#import "MessageFileView.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <Masonry/Masonry.h>

@interface MessageFileView()
@property(nonatomic) UILabel *titleLabel;
@property(nonatomic) UILabel *contentLabel;
@end

@implementation MessageFileView
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.imageView = [[UIImageView alloc] init];
        [self.imageView setUserInteractionEnabled:YES];
        [self addSubview:self.imageView];
        
        self.downloadIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self addSubview:self.downloadIndicatorView];
        
        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.numberOfLines = 0;
        self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self addSubview:self.titleLabel];
        
        self.contentLabel = [[UILabel alloc] init];
        self.contentLabel.font = [UIFont systemFontOfSize:14];
        [self addSubview:self.contentLabel];
        
        
        [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self);
            make.centerY.equalTo(self);
            make.width.mas_equalTo(48);
            make.height.mas_equalTo(48);
        }];
        
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self);
            make.centerY.equalTo(self).offset(-15);
            make.size.mas_equalTo(CGSizeMake(160, 30));
        }];
        
        [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self);
            make.centerY.equalTo(self).offset(15);
            make.size.mas_equalTo(CGSizeMake(160, 30));
        }];
    }
    return self;
}

- (NSString*)formatSize:(int)size {
    if (size < 1024) {
        return [NSString stringWithFormat:@"%d字节", size];
    } else if (size < 1024*1024) {
        return [NSString stringWithFormat:@"%.1fKB", size*1.0/1024];
    } else {
        return [NSString stringWithFormat:@"%.1fMB", size*1.0/(1024*1024)];
    }
}

- (void)setMsg:(IMessage*)msg {
    [super setMsg:msg];
    
    MessageFileContent *content = msg.fileContent;
    NSString *fileName = content.fileName;
    if ([fileName hasSuffix:@".doc"] || [fileName hasSuffix:@".docx"]) {
        self.imageView.image = [UIImage imageNamed:@"word.png"];
    } else if ([fileName hasSuffix:@".xls"] || [fileName hasSuffix:@".xlsx"]){
        self.imageView.image = [UIImage imageNamed:@"excel.png"];
    } else if ([fileName hasSuffix:@".pdf"]) {
        self.imageView.image = [UIImage imageNamed:@"pdf.png"];
    } else {
        self.imageView.image = [UIImage imageNamed:@"file.png"];
    }

    self.titleLabel.text = content.fileName;
    self.contentLabel.text = [self formatSize:content.fileSize];
    [self setNeedsLayout];
}

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}



-(CGSize)bubbleSize {
    CGSize bubbleSize = CGSizeMake(kFileWidth , kFileHeight);
    return bubbleSize;
}

-(void)layoutSubviews {
    [super layoutSubviews];
}
@end
