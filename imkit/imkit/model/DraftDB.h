/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import <Foundation/Foundation.h>

@interface DraftDB : NSObject
+(DraftDB*)instance;
-(NSString*)getDraft:(int64_t)uid;
-(void)setDraft:(int64_t)uid draft:(NSString*)draft;

-(NSString*)getGroupDraft:(int64_t)gid;
-(void)setGroupDraft:(int64_t)gid draft:(NSString*)draft;
@end
