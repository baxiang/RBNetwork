//
//  RBQueueRequest.h
//  Pods
//
//  Created by baxiang on 2017/1/3.
//
//

#import <Foundation/Foundation.h>
#import "RBNetworkEngine.h"

@interface RBQueueRequest : NSObject

@property (nonatomic, strong, readonly,nullable) RBNetworkRequest *firstRequest;
@property (nonatomic, strong, readonly,nullable) RBNetworkRequest *nextRequest;
- (nullable RBQueueRequest *)onFirst:(nullable RBRequestBlock)firstBlock;
- (nullable RBQueueRequest *)onNext:(nullable RBQueueNextBlock)nextBlock;
- (void)onFinishedOneRequest:(nullable RBNetworkRequest *)request response:(nullable id)responseObject error:(nullable NSError *)error;
- (void)cancelWithBlock:(nullable void (^)())cancelBlock;
@end
