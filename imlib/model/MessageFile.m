//
//  MessageFile.m
//  gobelieve
//
//  Created by houxh on 2018/5/26.
//

#import "MessageFile.h"

@implementation MessageFile

- (id)initWithFileURL:(NSString *)fileURL name:(NSString*)name size:(int)size uuid:(NSString*)uuid {
    NSDictionary *file = @{@"url":fileURL,
                           @"filename":name,
                           @"size":@(size)};
    
    NSDictionary *dic = @{@"file":file,
                          @"uuid":uuid};
    self = [super initWithDictionary:dic];
    if (self) {

    }
    return self;
}

- (id)initWithFileURL:(NSString *)fileURL name:(NSString*)name size:(int)size {
    NSString *uuid = [[NSUUID UUID] UUIDString];
    NSDictionary *file = @{@"url":fileURL,
                            @"filename":name,
                            @"size":@(size)};
    
    NSDictionary *dic = @{@"file":file,
                          @"uuid":uuid};
    self = [super initWithDictionary:dic];
    if (self) {

    }
    return self;
}

-(NSString*)fileName {
    NSDictionary *file = [self.dict objectForKey:@"file"];
    return [file objectForKey:@"filename"];
}

-(int)fileSize {
    NSDictionary *file = [self.dict objectForKey:@"file"];
    return [[file objectForKey:@"size"] intValue];
}

-(NSString*)fileURL {
    NSDictionary *file = [self.dict objectForKey:@"file"];
    return [file objectForKey:@"url"];
}

-(MessageFile*)cloneWithURL:(NSString*)url {
    return [[MessageFile alloc] initWithFileURL:url name:self.fileName size:self.fileSize uuid:self.uuid];
}

-(int)type {
    return MESSAGE_FILE;
}
@end
