//
//  RBNetworkEngine.h
//  
//
//  Created by baxiang on 16/8/29.
//  Copyright © 2016年 baxiang. All rights reserved.
//



#import <Foundation/Foundation.h>
#import "RBNetworkRequest.h"
#import "RBQueueRequest.h"
NS_ASSUME_NONNULL_BEGIN
@interface RBNetworkEngine : NSObject

// 不可用
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new  NS_UNAVAILABLE;

+ (nullable RBNetworkEngine *)defaultEngine;

+ (NSUInteger)sendRequest:(nullable RBRequestBlock)requestBlock
                onSuccess:(nullable RBSuccessBlock)successBlock
                onFailure:(nullable RBFailureBlock)failureBlock;

+ (NSUInteger)sendRequest:(nullable RBRequestBlock)requestBlock
               onProgress:(nullable RBProgressBlock)progressBlock
                onSuccess:(nullable RBSuccessBlock)successBlock
                onFailure:(nullable RBSuccessBlock)failureBlock;

+ (nullable RBQueueRequest *)sendChainRequest:(nullable RBQueueRequestBlock)requestBlock
                           onSuccess:(nullable RBBatchSuccessBlock)successBlock
                           onFailure:(nullable RBBatchFailureBlock)failureBlock;



NS_ASSUME_NONNULL_END
@end
