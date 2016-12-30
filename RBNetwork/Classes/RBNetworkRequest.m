//
//  RBNetworkRequest.m
//  Pudding
//
//  Created by baxiang on 16/8/29.
//  Copyright © 2016年 Zhi Kuiyu. All rights reserved.
//

#import "RBNetworkRequest.h"
#import "RBNetworkConfig.h"
#import "RBNetworkEngine.h"
@implementation RBNetworkRequest

-(instancetype)init{
    if (self = [super init]) {
        _requestMethod = RBRequestMethodPost;
        self.requestTimeout = [RBNetworkConfig defaultConfig].defaultTimeoutInterval;
        self.requestSerializerType = [RBNetworkConfig defaultConfig].defaultRequestSerializer;
        self.responseSerializerType = [RBNetworkConfig defaultConfig].defaultResponseSerializer;
    }
    return self;
}

- (void)start {
    [[RBNetworkEngine defaultEngine] executeRequestTask:self];
}

- (void)stop {
    [[RBNetworkEngine defaultEngine] cancelTask:self];
}


- (NSString *)httpMethodString
{
    NSString *method = nil;
    switch (self.requestMethod)
    {
        case RBRequestMethodGet:
            method = @"GET";
            break;
        case RBRequestMethodPost:
            method = @"POST";
            break;
        case RBRequestMethodPut:
            method = @"PUT";
            break;
        case RBRequestMethodDelete:
            method = @"DELETE";
            break;
        case RBRequestMethodOptions:
            method = @"OPTIONS";
            break;
        case RBRequestMethodHead:
            method = @"HEAD";
            break;
        default:
            method = @"GET";
            break;
    }
    return method;
}


- (void)clearRequestBlock {
    //self.completionBlock = nil;
    //self.progerssBlock = nil;
}
-(void)dealloc{
    NSLog(@"请求销毁%@",self.class);
   [self clearRequestBlock];
    //_delegate = nil;
}
@end
