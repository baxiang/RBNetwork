
//  RBNetworkRequest.h
//  Pudding
//
//  Created by baxiang on 16/8/29.
//  Copyright © 2016年 Zhi Kuiyu. All rights reserved.
//

#import <Foundation/Foundation.h>
@class RBNetworkRequest;
@class RBNetworkResponse;
#import "RBNetworkConfig.h"

typedef NS_ENUM(NSUInteger, RBRequestState)
{
    RBRequestStateWaiting = 0,
    RBRequestStateRunning ,
    RBRequestStateSuspended ,
    RBRequestStateCanceling ,
    RBRequestStateCompleted
};

typedef void(^RBRequestCompletionBlock)(__kindof RBNetworkRequest *requestTask,id response,NSError *error);
typedef void(^RBRequestProgressBlock)(__kindof RBNetworkRequest *task,NSProgress *progress);
//typedef void(^RBRequestCacheCompletion)(__kindof RBNetworkRequest *task, id cacheData);

@protocol RBRequestDelegate <NSObject>

@optional

- (void)requestWillStart:(RBNetworkRequest *)request;
- (void)requestDidSuccess:(RBNetworkRequest *)request;
- (void)requestDidFailure:(RBNetworkRequest *)request;
@end

@interface RBNetworkRequest : NSObject
/**
 *  BaseURL
 */
@property (nonatomic, copy) NSString *requestBaseURL;
/**
 *  requestURL
 */
@property (nonatomic, strong) NSString *requestURL;
/**
 *  request Method
 */
@property (nonatomic, assign) RBRequestMethod requestMethod;
/**
 *  Timeout
 */
@property (nonatomic, assign) NSTimeInterval requestTimeout;
@property (nonatomic,strong)  NSDictionary *requestParameters;
@property (nonatomic, strong) NSURLSessionTask *sessionTask;
@property (nonatomic, assign) RBRequestSerializerType  requestSerializer;
@property (nonatomic, assign) RBResponseSerializerType responseSerializer;
@property (nonatomic, copy)   NSDictionary<NSString *,NSString *>*  requestHeaders;
//任务类型
@property (nonatomic, assign) RBNetworkTaskType taskType;
/**
 *  请求的缓存策略
 */
@property (nonatomic, assign) RBNetworkCachePolicy cachePolicy;
/**
 *  是否是缓存数据
 */
@property (nonatomic,  assign) BOOL isCacheData;
#pragma mark - block
/**
 *  成功的的block
 */
@property (nonatomic,  copy) RBRequestCompletionBlock completionBlock;

// 上传或者下载进度
@property (nonatomic,  copy) RBRequestProgressBlock progerssBlock;
// delegate
@property (nonatomic, weak) id <RBRequestDelegate> delegate;
/**
 *  网络请求的结果
 */
@property (nonatomic,assign) RBRequestState requestState;
//@property (nonatomic, strong) Class responseModelClass;
@property (nonatomic, strong) NSString *responseCodeKey;
@property (nonatomic, strong) NSString *responseMessageKey;
@property (nonatomic, strong) NSString *responseContentDataKey;
@property (nonatomic, readwrite, assign) NSInteger statusCode;
@property (nonatomic, copy) NSIndexSet *acceptableStatusCodes;
@property (nonatomic, assign) NSUInteger identifier;
@property (nonatomic, strong, readwrite, nullable) id responseObject;
@property (nonatomic, strong, readwrite, nullable) NSData *responseData;
/**
 *  开始任务
 */
-(void) start;
/**
 *  结束任务
 */
-(void)stop;
-(void)startWithCompletionBlock:(RBRequestCompletionBlock)completionBlock;

-(instancetype)initWithURLString:(NSString *)URLString method:(RBRequestMethod)method params:(NSDictionary *)paramters;
- (void)clearRequestBlock;
- (NSString *)httpMethodString;


@end
