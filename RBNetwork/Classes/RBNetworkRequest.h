
//  RBNetworkRequest.h
//  
//
//  Created by baxiang on 16/8/29.
//  Copyright © 2016年 baxiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RBNetworkConfig.h"
@class RBUploadFormData;

NS_ASSUME_NONNULL_BEGIN

@interface RBNetworkRequest : NSObject
/**
 requestTask
 */
@property (nonatomic, strong,nullable) NSURLSessionTask *requestTask;

/**
 请求的类型 默认 HTTP request type, such as GET, POST
 */
@property (nonatomic, assign) RBRequestType type;
/**
 *  服务器地址 eg htttps://www.foo.com
 */
@property (nonatomic, copy,nullable) NSString *server;

/**
 *  服务器的接口 eg /foo/bar/
 */
@property (nonatomic, strong,nullable) NSString *api;

/**
  请求的完整地址 eg htttps://www.foo.com/foo/bar/
 */
@property (nonatomic, strong,nullable) NSString *url;
/**
 *  request Method
 */
@property (nonatomic, assign) RBRequestMethod method;

/**
 *  Timeout 超时时间
 */
@property (nonatomic, assign) NSTimeInterval timeout;

/**
 是否允许使用蜂窝数据 默认允许
 */
@property (nonatomic, assign) BOOL allowsCellularAccess;

/**
 请求header
 */
@property (nonatomic, copy,nullable)NSDictionary<NSString *,NSString *>*headers;

/**
 是否使用RBNetworkConfig 中defaultHeaders  默认是YES
 */
@property (nonatomic, assign) BOOL addDefaultHeaders;

/**
   请求参数
 */
@property (nonatomic,strong,nullable)  NSDictionary *parameters;

/**
 是否使用RBNetworkConfig 中defaultParams 默认是YES
 */
@property (nonatomic, assign) BOOL addDefaultParameters;
/**
  Request 序列化类型
 */
@property (nonatomic, assign) RBRequestSerializerType  requestSerializerType;

/**
 Response 序列化类型
 */
@property (nonatomic, assign) RBResponseSerializerType responseSerializerType;


/**
 下载的存储路径
 */
@property (nonatomic, copy,nullable) NSString *downloadSavePath;

/**
 断点下载的存储路径
 */
@property (nonatomic, copy,nullable) NSString *resumableDownloadPath;
/**
 请求成功的回调
 */
@property (nonatomic, copy, nullable) RBSuccessBlock successBlock;

/**
 请求失败的回调
 */
@property (nonatomic, copy, nullable) RBFailureBlock failureBlock;

/**
 请求的进度回调
 */
@property (nonatomic, copy, nullable) RBProgressBlock progressBlock;

/**
 请求的数据回调
 */
@property(nonatomic,copy,nullable) RBFinishedBlock finishBlock;

/**
 *  请求的缓存策略
 */
@property (nonatomic, assign) RBNetworkCachePolicy cachePolicy;


/**
 [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html", nil]
 */
@property (nonatomic, copy,nullable) NSSet<NSString *> *acceptableContentTypes;


/**
 默认是200-500；
 */
@property (nonatomic, copy, nullable) NSIndexSet *acceptableStatusCodes;

/**
 返回的状态码
 */
@property (nonatomic, readwrite, assign) NSInteger responseStatusCode;


/**
 <#Description#>
 */
@property (nonatomic, strong, readwrite, nullable) id responseObject;

/**
 <#Description#>
 */
@property (nonatomic, strong, readwrite, nullable) NSData *responseData;

/**
 json data
 */
@property (nonatomic, strong, readwrite, nullable) id responseJSONObject;

@property(nonatomic,strong,nullable) NSMutableArray<RBUploadFormData *>*uploadFormDatas;
- (void)addFormDataWithName:(nonnull NSString *)name fileData:(nonnull NSData *)fileData;
- (void)addFormDataWithName:(nonnull NSString *)name fileName:(nullable NSString *)fileName mimeType:(nullable NSString *)mimeType fileData:(nonnull NSData *)fileData;
- (void)addFormDataWithName:(nonnull NSString *)name fileURL:(nonnull NSURL *)fileURL;
- (void)addFormDataWithName:(nonnull NSString *)name fileName:(nullable NSString *)fileName mimeType:(nullable NSString *)mimeType fileURL:(nonnull NSURL *)fileURL;
- (void)clearRequestBlock;

- (BOOL)statusCodeValidator;

@end

@interface RBUploadFormData : NSObject
@property (nonatomic, copy,nonnull) NSString *name;
@property (nonatomic, copy, nullable) NSString *fileName;
@property (nonatomic, copy, nullable) NSString *mimeType;
@property (nonatomic, strong, nonnull) NSData *fileData;
@property (nonatomic, strong, nonnull) NSURL *fileURL;

+ (nonnull instancetype)formDataWithName:(nonnull NSString *)name fileData:(nonnull NSData *)fileData;
+ (nonnull instancetype)formDataWithName:(nonnull NSString *)name fileName:(nullable NSString *)fileName mimeType:(nullable NSString *)mimeType fileData:(nonnull NSData *)fileData;
+ (nonnull instancetype)formDataWithName:(nonnull NSString *)name fileURL:(nonnull NSURL *)fileURL;
+ (nonnull instancetype)formDataWithName:(nonnull NSString *)name fileName:(nullable NSString *)fileName mimeType:(nullable NSString *)mimeType fileURL:(nonnull NSURL *)fileURL;

@end
NS_ASSUME_NONNULL_END
