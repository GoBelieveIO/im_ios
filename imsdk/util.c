/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <netinet/in.h>
#include <sys/uio.h> /* writev */
#include <sys/ioctl.h>
#include <sys/un.h>
#include <errno.h>

int64_t hton64(int64_t val )
{
    int64_t high, low;
    low = (int64_t)(val & 0x00000000FFFFFFFF);
    val >>= 32;
    high = (int64_t)(val & 0x00000000FFFFFFFF);
    low = htonl( low );
    high = htonl( high );
    
    return (int64_t)low << 32 | high;
}

int64_t ntoh64(int64_t val )
{
    int64_t high, low;
    low = (int64_t)(val & 0x00000000FFFFFFFF);
    val>>=32;
    high = (int64_t)(val & 0x00000000FFFFFFFF);
    low = ntohl( low );
    high = ntohl( high );
    
    return (int64_t)low << 32 | high;
}

void writeInt32(int32_t v, void *p) {
    v = htonl(v);
    memcpy(p, &v, 4);
}

int32_t readInt32(const void *p) {
    int32_t v;
    memcpy(&v, p, 4);
    return ntohl(v);
}

void writeInt64(int64_t v, void *p) {
    v = hton64(v);
    memcpy(p, &v, 8);
}

int64_t readInt64(const void *p) {
    int64_t v;
    memcpy(&v, p, 8);
    return ntoh64(v);
}

void writeInt16(int16_t v, void *p) {
    v = htons(v);
    memcpy(p, &v, 2);
}

int16_t readInt16(const void *p) {
    int16_t v;
    memcpy(&v, p, 2);
    return ntohs(v);
}

int lookupAddr(const char *host, int port, struct sockaddr_in *addr) {
    struct addrinfo hints;
    struct addrinfo *result, *rp;
    int s;
    
    char buf[32];
    snprintf(buf, 32, "%d", port);
    
    memset(&hints, 0, sizeof(struct addrinfo));
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = IPPROTO_TCP;
    hints.ai_flags = 0;
    
    s = getaddrinfo(host, buf, &hints, &result);
    if (s != 0) {
        return -1;
    }
    if (result != NULL) {
        rp = result;
        memcpy(addr, rp->ai_addr, rp->ai_addrlen);
    }
    
    freeaddrinfo(result);
    return 0;
}

int sock_nonblock(int fd, int set) {
    int r;
    
    do
        r = ioctl(fd, FIONBIO, &set);
    while (r == -1 && errno == EINTR);
    
    return r;
}

int write_data(int fd, uint8_t *bytes, int len) {
    ssize_t n = 0;
    
    do {
        n = send(fd, bytes, len, 0);
    } while(n == -1 && errno == EINTR);
    if (n < 0) {
        if (errno != EAGAIN && errno != EWOULDBLOCK) {
            return -1;
        }
        return 0;
    } else {
        return (int)n;
    }
}

size_t fwrite$UNIX2003( const void *a, size_t b, size_t c, FILE *d )
{
    return fwrite(a, b, c, d);
}
char* strerror$UNIX2003( int errnum )
{
    return strerror(errnum);
}

