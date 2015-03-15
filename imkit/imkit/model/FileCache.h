
#import <Foundation/Foundation.h>

@interface FileCache: NSObject
+(FileCache*)instance;

@property(nonatomic)NSFileManager *fileManager;

-(void)storeFile:(NSData*)data forKey:(NSString*)key;

-(void)removeFileForKey:(NSString*)key;

-(NSString*)queryCacheForKey:(NSString*)key;

-(NSString*)cachePathForKey:(NSString*)key;
@end
