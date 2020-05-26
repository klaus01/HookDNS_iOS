//
//  AppDelegate.m
//  TestHookGetAddrInfo
//
//  Created by 柯磊 on 2020/5/26.
//  Copyright © 2020 KELEI. All rights reserved.
//

#import "AppDelegate.h"
#import <Dobby/Dobby.h>
#include <netdb.h>
#include <dns_sd.h>

static void my_callBack(DNSServiceRef sdRef, DNSServiceFlags flags, uint32_t interfaceIndex, DNSServiceErrorType errorCode, const char *hostname, const struct sockaddr *address, uint32_t ttl, void *context) {
    // nslookup www.baidu.com
    if (errorCode == kDNSServiceErr_NoError) {
//        kDNSServiceFlagsMoreComing | kDNSServiceFlagsAdd
    }
    NSLog(@"\nflags=%u interfaceIndex=%u errorCode=%d hostname=%s address=%d.%d.%d.%d ttl=%u", flags, interfaceIndex, errorCode, hostname, (unsigned char)address->sa_data[2], (unsigned char)address->sa_data[3], (unsigned char)address->sa_data[4], (unsigned char)address->sa_data[5], ttl);
}
DNSServiceErrorType (*origin_DNSServiceGetAddrInfo)(
    DNSServiceRef                    *sdRef,
    DNSServiceFlags flags,
    uint32_t interfaceIndex,
    DNSServiceProtocol protocol,
    const char                       *hostname,
    DNSServiceGetAddrInfoReply callBack,
    void                             *context          /* may be NULL */
);
DNSServiceErrorType (my_DNSServiceGetAddrInfo)(
    DNSServiceRef                    *sdRef,
    DNSServiceFlags flags,
    uint32_t interfaceIndex,
    DNSServiceProtocol protocol,
    const char                       *hostname,
    DNSServiceGetAddrInfoReply callBack,
    void                             *context          /* may be NULL */
 ) {
    DNSServiceErrorType result = origin_DNSServiceGetAddrInfo(sdRef, flags, interfaceIndex, protocol, hostname, my_callBack, context);
    printf("hostname: %s\n", hostname);
    
    const char *baidu = "baidu.com";
    if (strcmp(hostname, baidu) == 0) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            struct sockaddr address;
            memset(&address, 0, sizeof(address));
            address.sa_len = 0x10;
            address.sa_family = 0x02;
            address.sa_data[2] = (unsigned char)220;
            address.sa_data[3] = (unsigned char)181;
            address.sa_data[4] = (unsigned char)38;
            address.sa_data[5] = (unsigned char)148;
            callBack(*sdRef, flags, interfaceIndex, kDNSServiceErr_NoError, hostname, &address, 160, context);
        });
    }
    
    return result;
}

//int (*origin_getaddrinfo)(const char * __restrict hostname, const char * __restrict service, const struct addrinfo * __restrict hints, struct addrinfo ** __restrict result);
//
//int (my_getaddrinfo)(const char * __restrict hostname, const char * __restrict service, const struct addrinfo * __restrict hints, struct addrinfo ** __restrict result) {
//    NSLog(@"*****hostname = %s %s", hostname, service);
//    int error = origin_getaddrinfo(hostname, service, hints, result);
//    struct addrinfo* res;
//    if (error == 0 && (res = *result)) {
//        char toHostname[200];
//        error = getnameinfo(res->ai_addr, res->ai_addrlen, toHostname, 200, NULL, 0, 0);
//        if (error != 0) {
//            fprintf(stderr, "error in getnameinfo: %s\n", gai_strerror(error));
//        }
//        if (*toHostname != '\0') {
//            printf("hostname: %s->%s\n", hostname, toHostname);
//        }
//    } else {
//        fprintf(stderr, "error in getaddrinfo: %s\n", gai_strerror(error));
//    }
//    return error;
//}

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
//    DobbyHook((void *)getaddrinfo, (void *)my_getaddrinfo, (void **)&origin_getaddrinfo);
    DobbyHook((void *)DNSServiceGetAddrInfo, (void *)my_DNSServiceGetAddrInfo, (void **)&origin_DNSServiceGetAddrInfo);

    NSString *urlString = [NSString stringWithFormat:@"https://baidu.com/?_t=%.0f", NSDate.timeIntervalSinceReferenceDate * 1000.0];
    [[NSURLSession.sharedSession dataTaskWithURL:[NSURL URLWithString:urlString] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"ERROR:%@", error);
        } else if (data) {
            NSString *body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"body:%@", body);
        } else {
            NSLog(@"NO DATA");
        }
    }] resume];
    
    
    // Override point for customization after application launch.
    return YES;
}

@end
