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
#import <objc/runtime.h>

const char *hookHostname = "www.baidu.com";
const unsigned char newIP[4] = {14, 215, 177, 39};//www.baidu.com
//const unsigned char newIP[4] = {14, 18, 175, 154};//www.qq.com


@interface AddrInfoReply : NSObject
@property (nonatomic) DNSServiceGetAddrInfoReply callBack;
@end

@implementation AddrInfoReply
@end


static void my_callBack(DNSServiceRef sdRef, DNSServiceFlags flags, uint32_t interfaceIndex, DNSServiceErrorType errorCode, const char *hostname, const struct sockaddr *address, uint32_t ttl, void *context) {
    if (context) {
        id con = (__bridge id)(context);
        AddrInfoReply *reply = objc_getAssociatedObject(con, "AddrInfoReply");
        if (reply.callBack) {
            if (errorCode == kDNSServiceErr_NoError && address->sa_family == AF_INET) {
                if (address->sa_data[2] != 0
                    || address->sa_data[3] != 0
                    || address->sa_data[4] != 0
                    || address->sa_data[5] != 0) {
                    struct sockaddr *newAddress = (struct sockaddr *)address;
                    newAddress->sa_data[2] = newIP[0];
                    newAddress->sa_data[3] = newIP[1];
                    newAddress->sa_data[4] = newIP[2];
                    newAddress->sa_data[5] = newIP[3];
                    printf("my_callBack reset ip\n");
                    ((DNSServiceGetAddrInfoReply)(reply.callBack))(sdRef, flags, interfaceIndex, errorCode, hostname, newAddress, ttl, context);
                    return;
                }
            }
            ((DNSServiceGetAddrInfoReply)(reply.callBack))(sdRef, flags, interfaceIndex, errorCode, hostname, address, ttl, context);
        } else {
            fprintf(stderr, "ERROR: my_callBack no callBack\n");
        }
    } else {
        fprintf(stderr, "ERROR: my_callBack no context\n");
    }
}

DNSServiceErrorType (*origin_DNSServiceGetAddrInfo)(DNSServiceRef *sdRef, DNSServiceFlags flags, uint32_t interfaceIndex, DNSServiceProtocol protocol, const char *hostname, DNSServiceGetAddrInfoReply callBack, void *context);

DNSServiceErrorType (my_DNSServiceGetAddrInfo)(DNSServiceRef *sdRef, DNSServiceFlags flags, uint32_t interfaceIndex, DNSServiceProtocol protocol, const char *hostname, DNSServiceGetAddrInfoReply callBack, void *context) {
    printf("DNSServiceGetAddrInfo hostname: %s\n", hostname);
    if (strcmp(hostname, hookHostname) == 0 && context) {
        id con = (__bridge id)(context);
        AddrInfoReply *reply = [[AddrInfoReply alloc] init];
        reply.callBack =  callBack;
        objc_setAssociatedObject(con, "AddrInfoReply", reply, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return origin_DNSServiceGetAddrInfo(sdRef, flags, interfaceIndex, protocol, hostname, my_callBack, context);
    }
    return origin_DNSServiceGetAddrInfo(sdRef, flags, interfaceIndex, protocol, hostname, callBack, context);
}

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    DobbyHook((void *)DNSServiceGetAddrInfo, (void *)my_DNSServiceGetAddrInfo, (void **)&origin_DNSServiceGetAddrInfo);

    NSString *urlString = [NSString stringWithFormat:@"https://%s/?_t=%.0f", hookHostname, NSDate.timeIntervalSinceReferenceDate * 1000.0];
    [[NSURLSession.sharedSession dataTaskWithURL:[NSURL URLWithString:urlString] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"ERROR:%@", error);
        } else if (data) {
            NSString *body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"BODY:\n%@", body);
        } else {
            NSLog(@"NO DATA");
        }
    }] resume];
    
    return YES;
}

@end
