/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import <Foundation/Foundation.h>

@interface FileCache: NSObject
+(FileCache*)instance;

@property(nonatomic)NSFileManager *fileManager;

-(void)storeFile:(NSData*)data forKey:(NSString*)key;

-(void)removeFileForKey:(NSString*)key;

-(NSString*)queryCacheForKey:(NSString*)key;

-(NSString*)cachePathForKey:(NSString*)key;

-(BOOL)isCached:(NSString*)key;
@end
