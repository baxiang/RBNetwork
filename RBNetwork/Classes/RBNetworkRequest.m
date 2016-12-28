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
    return [self initWithURLString:@"" method:RBRequestMethodGet params:nil];
}
- (instancetype)initWithURLString:(NSString *)URLString
                           method:(RBRequestMethod)method
                           params:(NSDictionary *)paramters{
    if (self = [super init]) {
        _requestURL = URLString;
        _requestMethod = method;
        _requestParameters = paramters;
        self.requestTimeout = [RBNetworkConfig defaultConfig].defaultTimeoutInterval;
        self.requestSerializer = [RBNetworkConfig defaultConfig].defaultRequestSerializer;
        self.responseSerializer = [RBNetworkConfig defaultConfig].defaultResponseSerializer;
        self.requestState = RBRequestStateWaiting;
    }
    return self;
 
}

- (void)requestWillStartTag {
    if ([self.delegate respondsToSelector:@selector(requestWillStart:)]) {
        [self.delegate requestWillStart:self];
    }
}
- (void)start {
    [self requestWillStartTag];
    [[RBNetworkEngine defaultEngine] executeRequestTask:self];
}
- (void)stop {
    [[RBNetworkEngine defaultEngine] cancelTask:self];
}
- (void)startWithCompletionBlock:(RBRequestCompletionBlock)completionBlock{
    self.completionBlock = completionBlock;
    [self start];
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
-(RBRequestState)requestState{
    if (!self.sessionTask) {
        return RBRequestStateWaiting;
    }
    NSURLSessionTaskState currState = self.sessionTask.state;
    switch (currState) {
        case NSURLSessionTaskStateRunning:
            return RBRequestStateRunning;
            break;
        case NSURLSessionTaskStateSuspended:
            return RBRequestStateSuspended;
            break;
        case NSURLSessionTaskStateCanceling:
            return RBRequestStateCanceling;
            break;
        case NSURLSessionTaskStateCompleted:
            return RBRequestStateCompleted;
            break;
        default:
            break;
    }
}
- (void)clearRequestBlock {
    self.completionBlock = nil;
    self.progerssBlock = nil;
}
-(void)dealloc{
    NSLog(@"请求销毁%@",self.class);
   [self clearRequestBlock];
    _delegate = nil;
}
@end
