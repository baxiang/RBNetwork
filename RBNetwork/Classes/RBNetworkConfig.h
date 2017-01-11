//
//  RBNetworkConfig.h
//  Pudding
//
//  Created by baxiang on 16/8/29.
//  Copyright © 2016年 Zhi Kuiyu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class RBNetworkRequest;
@class RBQueueRequest;
#if DEBUG
#define  RBNetworkAssert(condition,fmt,...) \
if(!(condition)) {\
NSAssert(NO,fmt, ##__VA_ARGS__);\
}
#else
#define  RBNetworkAssert(condition,fmt,...) \
if(!(condition)) {\
NSLog((@"crush in debug :%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);\
}
#endif

#define RB_SAFE_BLOCK(BlockName, ...) \
if(BlockName){\
   BlockName(__VA_ARGS__);\
}
// 默认的请求超时时间
#define RB_REQUEST_TIMEOUT     20.0f
// 每个host最大连接数
#define RB_MAX_HTTP_CONNECTION  5

typedef NS_ENUM(NSUInteger, RBRequestMethod)
{
    RBRequestMethodGet = 0,
    RBRequestMethodPost,
    RBRequestMethodPut,
    RBRequestMethodDelete,
    RBRequestMethodOptions,
    RBRequestMethodHead
};
typedef NS_ENUM(NSUInteger, RBNetworkCachePolicy)
{
    RBNetworkCachePolicyIgnoreCache = 0,
    RBNetworkCachePolicyNeedCache
    
};
typedef NS_ENUM(NSInteger , RBRequestSerializerType) {
    RBRequestSerializerTypeHTTP = 0,
    RBRequestSerializerTypeJSON,
    RBRequestSerializerTypePropertyList
};
typedef NS_ENUM(NSInteger , RBResponseSerializerType) {
    RBResponseSerializerTypeHTTP = 0,
    RBResponseSerializerTypeJSON,
    RBResponseSerializerTypeXML
};
typedef NS_ENUM(NSInteger , RBRequestPriority) {
    RBRequestPriorityLow = -4L,
    RBRequestPriorityDefault = 0,
    RBRequestPriorityHigh = 4,
};
typedef NS_ENUM(NSInteger, RBRequestType) {
    RBMRequestDefault = 0,    // HTTP request type, such as GET, POST, ...
    RBRequestDownload,    // Download request type
    RBRequestUpload,      // Upload request type
   
};

typedef void (^RBRequestBlock)(RBNetworkRequest *_Nullable request);
typedef void (^RBCancelBlock)(RBNetworkRequest * _Nullable request);
typedef void (^RBProgressBlock)(NSProgress *_Nullable progress);
typedef void (^RBSuccessBlock)(id _Nullable responseObject);
typedef void (^RBFailureBlock)(NSError * _Nullable error);
typedef void (^RBFinishedBlock)(id _Nullable responseObject, NSError * _Nullable error);
typedef void (^RBBatchSuccessBlock)(NSArray<id> * _Nullable responseObjects);
typedef void (^RBBatchFailureBlock)(NSArray<id> * _Nullable errors);
typedef void (^RBQueueRequestBlock)( RBQueueRequest *_Nullable queueRequest);
typedef void (^RBQueueNextBlock)(RBNetworkRequest *_Nullable request, id _Nullable responseObject, BOOL *_Nullable sendNext);
@interface RBNetworkConfig : NSObject

+ (nullable RBNetworkConfig *)defaultConfig;
/**
 *   请求的URL
 */
@property (nonatomic, copy,nullable) NSString *defaultURL;
/**
 *   默认的请求头
 */
@property (nonatomic, copy,nullable) NSDictionary<NSString *,NSString *>* defaultHeaders;
/**
 *  默认的请求参数
 */
@property (nonatomic, copy,nullable) NSDictionary<NSString *,NSString *>* defaultParams;

/**
  默认的请求方法
 */
@property (nonatomic, assign) RBRequestMethod defaultRequestMethod;
/**
 *   默认  RBRequestSerializerTypeHTTP
 */
@property (nonatomic, assign) RBRequestSerializerType  defaultRequestSerializer;
/**
 *  默认返回数据类型 RBResponseSerializerTypeHTTP
 */
@property (nonatomic, assign) RBResponseSerializerType defaultResponseSerializer;
/**
 *  网络请求的最大队列数量 5
 */
@property (nonatomic, assign) NSInteger maxConcurrentOperationCount;
/**
 *   默认：[NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html", nil]
 */
@property (nonatomic, copy,nullable) NSSet<NSString *> *acceptableContentTypes;
/**
 *  @brief 请求超时时间，默认20秒
 */
@property (nonatomic, assign,) NSTimeInterval defaultTimeoutInterval;

/**
 *  下载数据的路径
 */
@property (nonatomic,copy,nullable) NSString *downloadFolderPath;

@property (nonatomic, strong,nullable) NSIndexSet *defaultAcceptableStatusCodes;
/**
 *  @brief 是否打开debug日志，默认打开
 */
@property (nonatomic, assign) BOOL enableDebug;

@end
