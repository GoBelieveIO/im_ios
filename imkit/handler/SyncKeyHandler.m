#import "SyncKeyHandler.h"


@interface SyncKeyHandler()
@property(nonatomic, strong) NSMutableDictionary *dict;
@end

@implementation SyncKeyHandler


-(id)initWithFileName:(NSString*)fileName {
    self = [super init];
    if (self) {
        self.fileName = fileName;
        [self load];
    }
    return self;
}
-(void)load {
    NSAssert(self.fileName.length > 0, @"");
    NSDictionary *dict = [self loadDictionary];
    NSMutableDictionary *groups = [NSMutableDictionary dictionaryWithDictionary:[dict objectForKey:@"groups"]];
    self.dict = [NSMutableDictionary dictionaryWithDictionary:dict];
    [self.dict setObject:groups forKey:@"groups"];
}

-(BOOL)saveSyncKey:(int64_t)syncKey {
    NSAssert(self.fileName.length > 0, @"");
    [self.dict setObject:[NSNumber numberWithLongLong:syncKey] forKey:@"sync_key"];
    [self storeDictionary:self.dict];
    return YES;
}

//大量群组时效率不佳
-(BOOL)saveGroupSyncKey:(int64_t)syncKey gid:(int64_t)gid {
    NSAssert(self.fileName.length > 0, @"");
    NSMutableDictionary *groups = [self.dict objectForKey:@"groups"];
    [groups setObject:[NSNumber numberWithLongLong:syncKey] forKey:[NSNumber numberWithLongLong:gid]];
    [self storeDictionary:self.dict];
    return YES;
}

-(int64_t)syncKey {
    return [[self.dict objectForKey:@"sync_key"] longLongValue];
}

-(NSDictionary*)superGroupSyncKeys {
    return [self.dict objectForKey:@"groups"];
}

-(void)storeDictionary:(NSDictionary*) dictionaryToStore {
    if (dictionaryToStore != nil) {
        [dictionaryToStore writeToFile:self.fileName atomically:YES];
    }
}

-(NSDictionary*)loadDictionary {
    NSDictionary* panelLibraryContent = [NSDictionary dictionaryWithContentsOfFile:self.fileName];
    return panelLibraryContent;
}

@end
