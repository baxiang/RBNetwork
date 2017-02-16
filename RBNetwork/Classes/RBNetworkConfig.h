//
//  RBNetworkConfig.h
//  Pudding
//
//  Created by baxiang on 16/8/29.
//  Copyright © 2016年 baxiang. All rights reserved.
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


NS_ASSUME_NONNULL_BEGIN

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
    RBResponseSerializerTypeXML,
    RBResponseSerializerTypePropertyList
};
typedef NS_ENUM(NSInteger , RBRequestPriority) {
    RBRequestPriorityLow = -4L,
    RBRequestPriorityDefault = 0,
    RBRequestPriorityHigh = 4,
};
typedef NS_ENUM(NSInteger, RBRequestType) {
    RBMRequestDefault = 0,    // HTTP request type 
    RBRequestDownload,    // Download request type
    RBRequestUpload,      // Upload request type
   
};

typedef NS_ENUM(NSUInteger, RBCacheType) {
    RBIgnoreCache = 0,  // 忽略缓存,
    RBOnlyUpdateCache,   //不使用缓存,只使用网络加载,加载成功后更新缓存
    RBLoadAndUpdateCache, // 先加载缓存,再请求网络,并且更新缓存(要更新缓存,这种情况需要设置缓存过期时间)
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

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new  NS_UNAVAILABLE;


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
@property (nonatomic, copy,nullable) NSDictionary<NSString *,NSString *>* defaultParameters;

/**
  默认的请求方法
 */
@property (nonatomic, assign) RBRequestMethod defaultRequestMethod;
/**
 *   默认  RBRequestSerializerTypeHTTP  application/x-www-form-urlencoded
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
 https://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html 默认是200-500
 */
@property (nonatomic, copy, nullable) NSIndexSet *defaultAcceptableStatusCodes;
/**
 *   默认：[NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html", nil]
 */
@property (nonatomic, copy,nullable) NSSet<NSString *> *defaultAcceptableContentTypes;
/**
 *  @brief 请求超时时间，默认20秒
 */
@property (nonatomic, assign,) NSTimeInterval defaultTimeoutInterval;

/**
 *  存储下载数据的文件夹 /Library/Caches/RBNetworkDownload
 */
@property (nonatomic,copy,nullable) NSString *defaultDownloadFolder;

/**
  是否打开debug日志，默认在debug模式下是打开 在release模式下关闭

 @param enableDebug 打开或者关闭
 */
-(void)setupEnableDebug:(BOOL)enableDebug;

NS_ASSUME_NONNULL_END
@end
