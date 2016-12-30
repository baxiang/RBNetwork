
//  RBNetworkRequest.h
//  Pudding
//
//  Created by baxiang on 16/8/29.
//  Copyright © 2016年 Zhi Kuiyu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RBNetworkConfig.h"
@class RBNetworkRequest;
@class RBNetworkResponse;



@interface RBNetworkRequest : NSObject
/**
 identifier
 */
@property (nonatomic, assign) NSUInteger identifier;
/**
 *  BaseURL
 */
@property (nonatomic, copy,nullable) NSString *requestBaseURL;
/**
 *  requestURL
 */
@property (nonatomic, strong,nullable) NSString *requestURL;
/**
 *  request Method
 */
@property (nonatomic, assign) RBRequestMethod requestMethod;
/**
 *  Timeout
 */
@property (nonatomic, assign) NSTimeInterval requestTimeout;

/**
  parameters 请求参数
 */
@property (nonatomic,strong,nullable)  NSDictionary *requestParameters;
/**
 <#Description#>
 */
@property (nonatomic, assign) RBRequestSerializerType  requestSerializerType;

/**
 <#Description#>
 */
@property (nonatomic, assign) RBResponseSerializerType responseSerializerType;

/**
 请求头
 */
@property (nonatomic, copy,nullable)NSDictionary<NSString *,NSString *>*requestHeaders;

/**
 请求成功的回调
 */
@property (nonatomic, copy, readonly, nullable) RBSuccessBlock successBlock;

/**
 请求失败的回调
 */
@property (nonatomic, copy, readonly, nullable) RBFailureBlock failureBlock;

/**
 请求的进度回调
 */
@property (nonatomic, copy, readonly, nullable) RBProgressBlock progressBlock;

/**
 *  请求的缓存策略
 */
@property (nonatomic, assign) RBNetworkCachePolicy cachePolicy;
/**
 *  是否是缓存数据
 */
@property (nonatomic,  assign) BOOL isCacheData;

/**
 返回的状态码
 */
@property (nonatomic, readwrite, assign) NSInteger statusCode;

/**
 <#Description#>
 */
@property (nonatomic, copy,nullable)   NSIndexSet *acceptableStatusCodes;

/**
 <#Description#>
 */
@property (nonatomic, strong, readwrite, nullable) id responseObject;

/**
 <#Description#>
 */
@property (nonatomic, strong, readwrite, nullable) NSData *responseData;
/**
 *  开始任务
 */
-(void) start;
/**
 *  结束任务
 */
-(void)stop;

- (void)clearRequestBlock;
- (nullable NSString *)httpMethodString;


@end
