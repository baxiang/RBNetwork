//
//  RBNetworkEngine.h
//  Pudding
//
//  Created by baxiang on 16/8/29.
//  Copyright © 2016年 Zhi Kuiyu. All rights reserved.
//



#import <Foundation/Foundation.h>
#import "RBNetworkRequest.h"
#import "RBQueueRequest.h"
NS_ASSUME_NONNULL_BEGIN
@interface RBNetworkEngine : NSObject
+ (nullable RBNetworkEngine *)defaultEngine;

+ (NSUInteger)sendRequest:(nullable RBRequestBlock)requestBlock
                onSuccess:(nullable RBSuccessBlock)successBlock
                onFailure:(nullable RBFailureBlock)failureBlock;

+ (nullable RBQueueRequest *)sendChainRequest:(nullable RBQueueRequestBlock)requestBlock
                           onSuccess:(nullable RBBatchSuccessBlock)successBlock
                           onFailure:(nullable RBBatchFailureBlock)failureBlock;



NS_ASSUME_NONNULL_END
@end
