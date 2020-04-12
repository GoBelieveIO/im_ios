/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#ifndef IM_UTIL_H
#define IM_UTIL_H

void writeInt32(int32_t v, void *p);
int32_t readInt32(const void *p);

void writeInt64(int64_t v, void *p);
int64_t readInt64(const void *p);

void writeInt16(int16_t v, void *p);
int16_t readInt16(const void *p);

int lookupAddr(const char *host, int port, struct sockaddr_in *addr);


int sock_nonblock(int fd, int set);
int write_data(int fd, uint8_t *bytes, int len);

#endif
