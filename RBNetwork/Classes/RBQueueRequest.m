//
//  RBQueueRequest.m
//  
//
//  Created by baxiang on 2017/1/3.
//
//

#import "RBQueueRequest.h"

@interface RBQueueRequest () {
    NSUInteger _chainIndex;
}

@property (nonatomic, strong, readwrite) RBNetworkRequest *firstRequest;
@property (nonatomic, strong, readwrite) RBNetworkRequest *nextRequest;
@property (nonatomic, strong) NSMutableArray<RBQueueNextBlock> *nextBlockArray;
@property (nonatomic, strong) NSMutableArray<id> *responseArray;
@property (nonatomic, copy) RBBatchSuccessBlock queueSuccessBlock;
@property (nonatomic, copy) RBBatchFailureBlock queueFailureBlock;

@end

@implementation RBQueueRequest : NSObject

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    _chainIndex = 0;
    _responseArray = [NSMutableArray array];
    _nextBlockArray = [NSMutableArray array];
    return self;
}

- (RBQueueRequest *)onFirst:(RBRequestBlock)firstBlock {
    NSAssert(firstBlock != nil, @"The first block for chain requests can't be nil.");
    NSAssert(_nextBlockArray.count == 0, @"The `onFirst:` method must called befault `onNext:` method");
    _firstRequest = [RBNetworkRequest new];
    firstBlock(_firstRequest);
    [_responseArray addObject:[NSNull null]];
    return self;
}

- (RBQueueRequest *)onNext:(RBQueueNextBlock)nextBlock {
    NSAssert(nextBlock != nil, @"The next block for chain requests can't be nil.");
    [_nextBlockArray addObject:nextBlock];
    [_responseArray addObject:[NSNull null]];
    return self;
}

- (void)onFinishedOneRequest:(RBNetworkRequest *)request response:(id)responseObject error:(NSError *)error {
    if (responseObject) {
        [_responseArray replaceObjectAtIndex:_chainIndex withObject:responseObject];
        if (_chainIndex < _nextBlockArray.count) {
            _nextRequest = [RBNetworkRequest new];
            RBQueueNextBlock nextBlock = _nextBlockArray[_chainIndex];
            BOOL startNext = YES;
            nextBlock(_nextRequest, responseObject, &startNext);
            if (!startNext) {
                RB_SAFE_BLOCK(_queueFailureBlock, _responseArray);

                [self cleanCallbackBlocks];
            }
        } else {
            RB_SAFE_BLOCK(_queueSuccessBlock, _responseArray);
            [self cleanCallbackBlocks];
        }
    } else {
        if (error) {
            [_responseArray replaceObjectAtIndex:_chainIndex withObject:error];
        }
        RB_SAFE_BLOCK(_queueFailureBlock, _responseArray);
        [self cleanCallbackBlocks];
    }
    _chainIndex++;
}

- (void)cleanCallbackBlocks {
    _firstRequest = nil;
    _nextRequest = nil;
    _queueSuccessBlock = nil;
    _queueFailureBlock = nil;
    [_nextBlockArray removeAllObjects];
}

- (void)cancelWithBlock:(void (^)())cancelBlock {
    if (_firstRequest && !_nextRequest) {
       // [RBNetworkEngine cancelRequest:_firstRequest.identifier];
    } else if (_nextRequest) {
       // [RBNetworkEngine cancelRequest:_nextRequest.identifier];
    }
    RB_SAFE_BLOCK(cancelBlock);
}

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
}

@end
