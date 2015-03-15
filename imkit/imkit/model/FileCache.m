
#import "FileCache.h"
#import <CommonCrypto/CommonDigest.h>

@interface FileCache()
@property(nonatomic)NSString *cachePath;
@end

@implementation FileCache
+(FileCache*)instance {
    static FileCache *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!m) {
            m = [[FileCache alloc] init];
        }
    });
    return m;
}

-(id)init {
    self = [super init];
    if (self) {
        self.fileManager = [[NSFileManager alloc] init];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        self.cachePath = [paths[0] stringByAppendingPathComponent:@"file_cache"];
        if (![self.fileManager fileExistsAtPath:self.cachePath]) {
              [self.fileManager createDirectoryAtPath:self.cachePath withIntermediateDirectories:YES attributes:nil error:NULL];
        }
    }
    return self;
}

- (NSString *)cachePathForKey:(NSString *)key inPath:(NSString *)path {
    NSString *filename = [self cachedFileNameForKey:key];
    return [path stringByAppendingPathComponent:filename];
}

- (NSString *)defaultCachePathForKey:(NSString *)key {
    return [self cachePathForKey:key inPath:self.cachePath];
}

-(NSString*)cachePathForKey:(NSString*)key {
    return [self cachePathForKey:key inPath:self.cachePath];
}

- (NSString *)cachedFileNameForKey:(NSString *)key
{
    const char *str = [key UTF8String];
    if (str == NULL)
    {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
    
    return filename;
}

-(void)storeFile:(NSData*)data forKey:(NSString*)key {
    [self.fileManager createFileAtPath:[self defaultCachePathForKey:key] contents:data attributes:nil];
}

-(void)removeFileForKey:(NSString*)key {
    [self.fileManager removeItemAtPath:[self defaultCachePathForKey:key] error:nil];
}

-(NSString*)queryCacheForKey:(NSString*)key {
    if ([self.fileManager fileExistsAtPath:[self defaultCachePathForKey:key]]) {
        return [self defaultCachePathForKey:key];
    } else {
        return nil;
    }
}

@end
