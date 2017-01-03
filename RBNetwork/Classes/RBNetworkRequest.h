
//  RBNetworkRequest.h
//  Pudding
//
//  Created by baxiang on 16/8/29.
//  Copyright © 2016年 Zhi Kuiyu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RBNetworkConfig.h"
@class RBUploadFormData;


@interface RBNetworkRequest : NSObject
/**
 requestTask
 */
@property (nonatomic, strong) NSURLSessionTask *requestTask;

/**
 请求的类型
 */
@property (nonatomic, assign) RBRequestType requestType;
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
 返回的状态码
 */
@property (nonatomic, readwrite, assign) NSInteger responseStatusCode;

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
 json data
 */
@property (nonatomic, strong, readwrite, nullable) id responseJSONObject;

@property(nonatomic,strong,nullable) NSMutableArray<RBUploadFormData *>*uploadFormDatas;
- (void)addFormDataWithName:(nonnull NSString *)name fileData:(nonnull NSData *)fileData;
- (void)addFormDataWithName:(nonnull NSString *)name fileName:(nullable NSString *)fileName mimeType:(nullable NSString *)mimeType fileData:(nonnull NSData *)fileData;
- (void)addFormDataWithName:(nonnull NSString *)name fileURL:(nonnull NSURL *)fileURL;
- (void)addFormDataWithName:(nonnull NSString *)name fileName:(nullable NSString *)fileName mimeType:(nullable NSString *)mimeType fileURL:(nonnull NSURL *)fileURL;
- (void)clearRequestBlock;
- (nullable NSString *)httpMethodString;
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
