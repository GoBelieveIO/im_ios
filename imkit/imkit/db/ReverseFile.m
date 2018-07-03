/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "ReverseFile.h"

@implementation ReverseFile
-(id)initWithFD:(int)fd {
    self = [super init];
    if (self) {
        self.fd = fd;
    }
    return self;
}

-(void)dealloc {
    close(self.fd);
}

-(int)read:(char*)p length:(int)len {
    ssize_t n = pread(self.fd, p, len, self.pos - len);
    self.pos = self.pos - len;
    return (int)n;
}
@end
