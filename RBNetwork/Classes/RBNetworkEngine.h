//
//  RBNetworkEngine.h
//  Pudding
//
//  Created by baxiang on 16/8/29.
//  Copyright © 2016年 Zhi Kuiyu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RBNetworkRequest.h"
#import "RBDownloadRequest.h"

@interface RBNetworkEngine : NSObject
+ (RBNetworkEngine *)defaultEngine;
- (void)executeRequestTask:(RBNetworkRequest *)request;
- (void)cancelTask:(RBNetworkRequest *)httpTask;
- (void)cancelAllTask;
+ (NSUInteger)sendRequest:(RBConstructBlock)configBlock
                onSuccess:(nullable RBSuccessBlock)successBlock
                onFailure:(nullable RBFailureBlock)failureBlock;
@end
