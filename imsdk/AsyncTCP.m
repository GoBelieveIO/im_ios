/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "AsyncTCP.h"
#include <netinet/in.h>
#include <netdb.h>
#include <arpa/inet.h>

@implementation AsyncTCP

- (BOOL)synthesizeIPv6:(NSString*)host port:(int)port addr:(struct sockaddr*)addr addrinfo:(struct addrinfo*)info {
    int error;
    struct addrinfo hints, *res0, *res;
    const char *ipv4_str = [host UTF8String];
    
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = PF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_DEFAULT;
    error = getaddrinfo(ipv4_str, "", &hints, &res0);
    if (error) {
        NSLog(@"%s", gai_strerror(error));
        return FALSE;
    }
    
    for (res = res0; res; res = res->ai_next) {
        NSLog(@"family:%d socktype;%d protocol:%d", res->ai_family, res->ai_socktype, res->ai_protocol);
    }
    
    BOOL r = YES;
    //use first
    if (res0) {
        if (res0->ai_family == AF_INET6) {
            struct sockaddr_in6 *addr6 = ((struct sockaddr_in6*)res0->ai_addr);
            addr6->sin6_port = htons(port);
            
            memcpy(addr, res0->ai_addr, res0->ai_addrlen);
            *info = *res0;
        } else if (res0->ai_family == AF_INET) {
            struct sockaddr_in *addr4 = ((struct sockaddr_in*)res0->ai_addr);
            addr4->sin_port = htons(port);
            
            memcpy(addr, res0->ai_addr, res0->ai_addrlen);
            *info = *res0;
        } else {
            r = NO;
        }
    }
    
    freeaddrinfo(res0);
    return r;
}

@end
