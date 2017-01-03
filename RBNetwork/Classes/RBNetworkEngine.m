//
//  RBNetworkEngine.m
//  Pudding
//
//  Created by baxiang on 16/8/29.
//  Copyright © 2016年 Zhi Kuiyu. All rights reserved.
//

#import "RBNetworkEngine.h"
#import "AFNetworking.h"
#import "NSError+RBNetwork.h"
#import "RBNetworkLogger.h"
#import <CommonCrypto/CommonDigest.h>
#import <libkern/OSAtomic.h>
#import  <objc/runtime.h>
#import "RBNetworkUtilities.h"
#import "RBNetworkUtilities.h"
#import <pthread/pthread.h>
#import "AFNetworkActivityIndicatorManager.h"
@interface NSDictionary (RBNetworkEngine)
- (NSMutableDictionary *)merge:(NSDictionary *)dict;
@end
@implementation NSDictionary (RBNetworkEngine)
- (NSMutableDictionary *)merge:(NSDictionary *)dict {
    @try {
        NSMutableDictionary *result = nil;
        if ([self isKindOfClass:[NSMutableDictionary class]]) {
            result = (NSMutableDictionary *)self;
        } else {
            result = [NSMutableDictionary dictionaryWithDictionary:self];
        }
        for (id key in dict) {
            if (result[key] == nil) {
                result[key] = dict[key];
            } else {
                if ([result[key] isKindOfClass:[NSDictionary class]] &&
                    [dict[key] isKindOfClass:[NSDictionary class]]) {
                    result[key] = [result[key] merge:dict[key]];
                } else {
                    result[key] = dict[key];
                }
            }
        }
        return result;
    }
    @catch (NSException *exception) {
        return [self mutableCopy];
    }
}
@end


#define Lock() pthread_mutex_lock(&_lock)
#define Unlock() pthread_mutex_unlock(&_lock)
@interface RBNetworkEngine()
@property (nonatomic, strong) NSMutableDictionary <NSString*, __kindof RBNetworkRequest*>*requestRecordDict;
@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
@property (nonatomic, strong) NSMutableArray <__kindof RBDownloadRequest *> *downloadingModels;
@property (nonatomic, strong) NSMutableDictionary <NSString *, __kindof RBDownloadRequest *> *downloadModelsDict;
@end
@implementation RBNetworkEngine{
  
    OSSpinLock _lock;
    AFJSONResponseSerializer *_jsonResponseSerializer;
    AFXMLParserResponseSerializer *_xmlResponseSerialzier;
    NSIndexSet *_allStatusCodes;
}

+ (RBNetworkEngine *)defaultEngine
{
    static id _defaultEngine = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultEngine = [[[self class] alloc] init];
    });
    return _defaultEngine;
}

+(void)load{
      [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}

- (instancetype)init
{
    self = [super init];
    if(self){
        _requestRecordDict = [NSMutableDictionary dictionary];
        _sessionManager = [AFHTTPSessionManager manager];
        _sessionManager.operationQueue.maxConcurrentOperationCount = [RBNetworkConfig defaultConfig].maxConcurrentOperationCount;
        
        _lock = dispatch_semaphore_create(1);
        _lock = OS_SPINLOCK_INIT;
        _downloadingModels = [[NSMutableArray alloc] initWithCapacity:1];
        _downloadModelsDict = [[NSMutableDictionary alloc] initWithCapacity:1];
        [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
         _allStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(100, 500)];
    }
    return self;
}

- (NSInteger)networkReachability {
    return [AFNetworkReachabilityManager sharedManager].networkReachabilityStatus;
}

#pragma mark network config 请求配置

- (AFHTTPRequestSerializer *)requestSerializerByRequestTask:(__kindof RBNetworkRequest *)requestTask{
    if (requestTask.requestSerializerType == RBRequestSerializerTypeHTTP) {
        return  [AFHTTPRequestSerializer serializer];
    } else if(requestTask.requestSerializerType == RBRequestSerializerTypeJSON) {
        return  [AFJSONRequestSerializer serializer];
    }
}
- (AFHTTPResponseSerializer *)responseSerializerByRequestTask:(__kindof RBNetworkRequest *)requestTask {
    if (requestTask.responseSerializerType == RBResponseSerializerTypeHTTP) {
        return self.sessionManager.responseSerializer;
    } else if (requestTask.responseSerializerType == RBResponseSerializerTypeJSON) {
        return [AFJSONResponseSerializer serializer];
    }
}
- (NSString *)urlStringByRequest:(__kindof RBNetworkRequest *)request {
    NSString *detailUrl = request.requestURL;
    if ([detailUrl hasPrefix:@"http"]) {
        return detailUrl;
    }
    NSString *baseUrlString;
    if ([request.requestBaseURL length] > 0) {
        baseUrlString = request.requestBaseURL;
    } else {
        baseUrlString = [RBNetworkConfig defaultConfig].baseUrlString;;
    }
    return [NSString stringWithFormat:@"%@%@",baseUrlString,detailUrl];
}
- (NSDictionary *)requestParamByRequest:(__kindof RBNetworkRequest  *)request {
    NSMutableDictionary *temRBict = [[NSMutableDictionary alloc] init];
    if (request.requestParameters&&[request.requestParameters isKindOfClass:[NSDictionary class]]) {
        [temRBict addEntriesFromDictionary:request.requestParameters];
        
    }
    NSDictionary *baseRequestParamSource = [RBNetworkConfig defaultConfig].baseRequestParams;
    if (baseRequestParamSource != nil) {
        NSDictionary *mergeDict =[baseRequestParamSource merge:temRBict];
        [temRBict addEntriesFromDictionary:mergeDict];
    }
    return temRBict;
}
-(void)constructionURLRequest:(NSMutableURLRequest *)urlRequest ByRequestTask:(__kindof RBNetworkRequest  *)request{
    NSDictionary *baseRequestHeaders = [RBNetworkConfig defaultConfig].baseRequestHeaders;
    [baseRequestHeaders enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [urlRequest setValue:obj forHTTPHeaderField:key];
    }];
    [request.requestHeaders enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [urlRequest setValue:obj forHTTPHeaderField:key];
    }];
}

- (AFJSONResponseSerializer *)jsonResponseSerializer {
    if (!_jsonResponseSerializer) {
        _jsonResponseSerializer = [AFJSONResponseSerializer serializer];
        _jsonResponseSerializer.acceptableStatusCodes = _allStatusCodes;
    }
    return _jsonResponseSerializer;
}
- (AFXMLParserResponseSerializer *)xmlParserResponseSerialzier {
    if (!_xmlResponseSerialzier) {
        _xmlResponseSerialzier = [AFXMLParserResponseSerializer serializer];
        _xmlResponseSerialzier.acceptableStatusCodes = _allStatusCodes;
    }
    return _xmlResponseSerialzier;
}

- (void)_constructRequest:(RBNetworkRequest *)request
               onProgress:(RBProgressBlock)progressBlock
                onSuccess:(RBSuccessBlock)successBlock
                onFailure:(RBFailureBlock)failureBlock{
    
    if (successBlock) {
        [request setValue:successBlock forKey:@"_successBlock"];
    }
    if (failureBlock) {
        [request setValue:failureBlock forKey:@"_failureBlock"];
    }
    if (progressBlock) {
        [request setValue:progressBlock forKey:@"_progressBlock"];
    }
    switch (request.requestType) {
        case RBRequestDownload:
            [self _startDownloadTask:request];
            break;
        case RBRequestUpload:
            [self _startUploadTask:request];
        default:
            [self _startDefaultTask:request];
            break;
    }
}
+ (NSUInteger)sendRequest:(RBRequestBlock)requestBlock
                onSuccess:(nullable RBSuccessBlock)successBlock
                onFailure:(nullable RBFailureBlock)failureBlock{
    RBNetworkRequest *request = [RBNetworkRequest new];
    if (requestBlock) {
        requestBlock(request);
    }
    [[RBNetworkEngine defaultEngine] _constructRequest:request onProgress:nil onSuccess:successBlock onFailure:failureBlock];

}


- (NSUInteger)sendRequest:(RBRequestBlock)requestBlock
               onProgress:(nullable RBProgressBlock)progressBlock
                onSuccess:(nullable RBSuccessBlock)successBlock
                onFailure:(nullable RBFailureBlock)failureBlock{
    
}


+ (RBQueueRequest *)sendChainRequest:(RBQueueRequestBlock)queueBlock
                           onSuccess:(nullable RBBatchSuccessBlock)successBlock
                           onFailure:(nullable RBBatchFailureBlock)failureBlock{
    RBQueueRequest *queueRequest = [[RBQueueRequest alloc] init];
    RB_SAFE_BLOCK(queueBlock, queueRequest);
    if (queueRequest.firstRequest) {
        if (successBlock) {
            [queueRequest setValue:successBlock forKey:@"_queueSuccessBlock"];
        }
        if (failureBlock) {
            [queueRequest setValue:failureBlock forKey:@"_queueFailureBlock"];
        }
        [[RBNetworkEngine defaultEngine] _sendQueueRequest:queueRequest withRequest:queueRequest.firstRequest];
        return queueRequest;
    } else {
        return nil;
    }
}


- (void)_sendQueueRequest:(RBQueueRequest *)queueRequest withRequest:(RBNetworkRequest *)request {
    __weak __typeof(self)weakSelf = self;
    request.finishBlock = ^(id _Nullable responseObject, NSError * _Nullable error){
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [queueRequest onFinishedOneRequest:request response:responseObject error:error];
        if (queueRequest.nextRequest) {
            [strongSelf _sendQueueRequest:queueRequest withRequest:queueRequest.nextRequest];
        }
    };
    [self _startDefaultTask:request];
    
}

-(NSUInteger)_startDefaultTask:(RBNetworkRequest *)requestTask{
    AFHTTPRequestSerializer *requestSerializer = [self requestSerializerByRequestTask:requestTask];
    NSString*urlStr = [self urlStringByRequest:requestTask];
    NSDictionary*paramsDict = [self requestParamByRequest:requestTask];
    NSError *serializationError = nil;
    NSMutableURLRequest *request = [requestSerializer requestWithMethod:requestTask.httpMethodString URLString:urlStr parameters:paramsDict error:&serializationError];
    if (serializationError) {
            if (requestTask.failureBlock) {
                requestTask.failureBlock(serializationError);
            }
            return 0;
        }
    [self constructionURLRequest:request ByRequestTask:requestTask];
    if ([RBNetworkConfig defaultConfig].enableDebug) {
        [RBNetworkLogger logDebugRequestInfoWithURL:urlStr  methodName:requestTask.httpMethodString params:paramsDict reachabilityStatus:[[AFNetworkReachabilityManager sharedManager] networkReachabilityStatus]];
    }
    __block NSURLSessionDataTask *dataTask = nil;
    __weak __typeof(self)weakSelf = self;
    dataTask = [self.sessionManager dataTaskWithRequest:request
                                      completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
                                          __strong __typeof(weakSelf)strongSelf = weakSelf;
                                          [self handleResponseResult:dataTask responseObject:responseObject error:error];
                                      }];
    [requestTask setIdentifier:dataTask.taskIdentifier];
    [dataTask resume];
    [self addRequestObject:requestTask];
    return requestTask.identifier;
    
}
- (void)handleResponseResult:(NSURLSessionTask *)task responseObject:(id)responseObject error:(NSError *)error {
    Lock();
    RBNetworkRequest *request = _requestRecordDict[@(task.taskIdentifier)];
    Unlock();
    NSError * __autoreleasing serializationError = nil;
    NSError * __autoreleasing validationError = nil;
    NSError *requestError = nil;
    request.responseObject = responseObject;
    request.responseStatusCode = [(NSHTTPURLResponse *)task.response statusCode];
    BOOL succeed = NO;
    if ([request.responseObject isKindOfClass:[NSData class]]) {
        request.responseData = responseObject;
        switch (request.responseSerializerType) {
            case RBResponseSerializerTypeHTTP:
                // Default serializer. Do nothing.
                break;
            case RBResponseSerializerTypeJSON:
                request.responseObject = [self.jsonResponseSerializer responseObjectForResponse:task.response data:request.responseData error:&serializationError];
                request.responseJSONObject = request.responseObject;
                break;
            case RBResponseSerializerTypeXML:
                request.responseObject = [self.xmlParserResponseSerialzier responseObjectForResponse:task.response data:request.responseData error:&serializationError];
                break;
        }
    }
    if (error) {
        succeed = NO;
        requestError = error;
    } else if (serializationError) {
        succeed = NO;
        requestError = serializationError;
    } else {
        succeed = YES;
//        succeed = [self validateResult:request error:&validationError];
//        requestError = validationError;
    }
    RB_SAFE_BLOCK(request.finishBlock,request.responseObject,requestError);
    if (succeed) {
        [self requestDidSucceedWithRequest:request];
    } else {
        [self requestDidFailWithRequest:request error:error];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
//        [self removeRequestFromRecord:request];
//        [request clearCompletionBlock];
    });
}
- (void)requestDidSucceedWithRequest:(RBNetworkRequest *)request {
    @autoreleasepool {
       // [request requestCompletePreprocessor];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
       // [request toggleAccessoriesWillStopCallBack];
       // [request requestCompleteFilter];
        
//        if (request.delegate != nil) {
//            [request.delegate requestFinished:request];
//        }
        if (request.successBlock) {
            request.successBlock(request.responseObject);
        }
        //[request toggleAccessoriesDidStopCallBack];
    });
}

- (void)requestDidFailWithRequest:(RBNetworkRequest *)request error:(NSError *)error {
    if (request.resumableDownloadPath) {
        NSData *incompleteDownloadData = error.userInfo[NSURLSessionDownloadTaskResumeData];
        if (incompleteDownloadData) {
            [incompleteDownloadData writeToURL:[self incompleteDownloadTempPathForDownloadPath:request.resumableDownloadPath] atomically:YES];
        }
    }
    // Load response from file and clean up if download task failed.
    if ([request.responseObject isKindOfClass:[NSURL class]]) {
        NSURL *url = request.responseObject;
        if (url.isFileURL && [[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
            request.responseData = [NSData dataWithContentsOfURL:url];
//            request.responseString = [[NSString alloc] initWithData:request.responseData encoding:[YTKNetworkUtils stringEncodingWithRequest:request]];
            
            [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
        }
        request.responseObject = nil;
    }
    
    @autoreleasepool {
       // [request requestFailedPreprocessor];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
//        [request toggleAccessoriesWillStopCallBack];
//        [request requestFailedFilter];
//        
//        if (request.delegate != nil) {
//            [request.delegate requestFailed:request];
//        }
        if (request.failureBlock) {
            request.failureBlock(error);
        }
//        [request toggleAccessoriesDidStopCallBack];
    });
}
- (BOOL)validateResult:(RBNetworkRequest *)request error:(NSError * _Nullable __autoreleasing *)error {
    BOOL result = [request statusCodeValidator];
    if (!result) {
        if (error) {
            *error = [NSError errorWithDomain:RBNetworkRequestErrorDomain code:RBErrorCodeRequestParseFailure userInfo:@{NSLocalizedDescriptionKey:@"Invalid status code"}];
        }
        return result;
    }
    return YES;
}


- (void)cancelTask:(RBNetworkRequest *)requestTask{
    //[requestTask.sessionTask cancel];
    [self removeRequestObject:requestTask];
    [requestTask clearRequestBlock];
}
-(void)cancelAllTask{
    NSDictionary *copyRecorddDict = [_requestRecordDict  copy];
   [copyRecorddDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, __kindof RBNetworkRequest * _Nonnull requestTask, BOOL * _Nonnull stop) {
       [self cancelTask:requestTask];
   }];
}
#pragma mark upload

- (NSInteger)_startUploadTask:(RBNetworkRequest *)uploadTask{
       AFHTTPRequestSerializer *requestSerializer = [self requestSerializerByRequestTask:uploadTask];
       NSString*urlStr = [self urlStringByRequest:uploadTask];
       NSDictionary*paramsDict = [self requestParamByRequest:uploadTask];
      __block NSError *serializationError = nil;
      NSMutableURLRequest *request = [requestSerializer multipartFormRequestWithMethod:uploadTask.httpMethodString URLString:urlStr parameters:paramsDict constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
       [uploadTask.uploadFormDatas enumerateObjectsUsingBlock:^(RBUploadFormData *obj, NSUInteger idx, BOOL *stop) {
           if (obj.fileData) {
               if (obj.fileName && obj.mimeType) {
                   [formData appendPartWithFileData:obj.fileData name:obj.name fileName:obj.fileName mimeType:obj.mimeType];
               } else {
                   [formData appendPartWithFormData:obj.fileData name:obj.name];
               }
           } else if (obj.fileURL) {
               NSError *fileError = nil;
               if (obj.fileName && obj.mimeType) {
                   [formData appendPartWithFileURL:obj.fileURL name:obj.name fileName:obj.fileName mimeType:obj.mimeType error:&fileError];
               } else {
                   [formData appendPartWithFileURL:obj.fileURL name:obj.name error:&fileError];
               }
               if (fileError) {
                   serializationError = fileError;
                   *stop = YES;
               }
           }
       }];
    } error:&serializationError];
      if (serializationError) {
        NSError *error =[NSError errorWithDomain:RBNetworkRequestErrorDomain code:RBErrorCodeRequestSendFailure description:@"上传文件失败"];
        if (uploadTask.failureBlock) {
            uploadTask.failureBlock(error);
        }
          return 0;
       }
        request.timeoutInterval = uploadTask.requestTimeout;
        __block  NSURLSessionUploadTask *uploadDataTask = nil;
          uploadDataTask = [self.sessionManager uploadTaskWithStreamedRequest:request  progress:^(NSProgress *progress){
                if (uploadTask.progressBlock) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        uploadTask.progressBlock(progress);
                    });
                }
            }completionHandler:^(NSURLResponse * _Nonnull response, id  _Nonnull responseObject, NSError * _Nonnull error){
                 [self handleResponseResult:uploadDataTask responseObject:responseObject error:error];
            }];
    [uploadTask setIdentifier:uploadDataTask.taskIdentifier];
    [uploadDataTask resume];
    [self addRequestObject:uploadTask];
    return uploadTask.identifier;
    
}

- (void)addRequestObject:(__kindof RBNetworkRequest*)request {
    if (request == nil)    return;
    Lock();
    _requestRecordDict[@(request.identifier)] = request;;
    Unlock();
}

- (void)removeRequestObject:(__kindof RBNetworkRequest*)request {
    if(request == nil)  return;
    Lock();
     [_requestRecordDict removeObjectForKey:@(request.identifier)];
    Unlock();
}

#pragma mark download
-(NSInteger)_startDownloadTask:(RBNetworkRequest*)downloadRequest{
    NSString*downloadURL = [self urlStringByRequest:downloadRequest];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:downloadURL]];
    if (downloadRequest.requestHeaders.count > 0) {
        [downloadRequest.requestHeaders enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL * __unused stop) {
            //if (![urlRequest valueForHTTPHeaderField:field]) {
            [urlRequest setValue:value forHTTPHeaderField:field];
            //}
        }];
    }
    urlRequest.timeoutInterval = downloadRequest.requestTimeout;
    
    NSURL *downloadFileSavePath;
    BOOL isDirectory;
    if(![[NSFileManager defaultManager] fileExistsAtPath:downloadRequest.downloadSavePath isDirectory:&isDirectory]) {
        isDirectory = NO;
    }
    if (isDirectory) {
        NSString *fileName = [urlRequest.URL lastPathComponent];
        downloadFileSavePath = [NSURL fileURLWithPath:[NSString pathWithComponents:@[downloadRequest.downloadSavePath, fileName]] isDirectory:NO];
    } else {
        downloadFileSavePath = [NSURL fileURLWithPath:downloadRequest.downloadSavePath isDirectory:NO];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:downloadFileSavePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:downloadFileSavePath error:nil];
    }
    BOOL resumeDataFileExists = [[NSFileManager defaultManager] fileExistsAtPath:[self incompleteDownloadTempPathForDownloadPath:downloadRequest.downloadSavePath].path];
    NSData *data = [NSData dataWithContentsOfURL:[self incompleteDownloadTempPathForDownloadPath:downloadRequest.downloadSavePath]];
    BOOL resumeDataIsValid = [RBNetworkUtilities validateResumeData:data];
    BOOL canBeResumed = resumeDataFileExists && resumeDataIsValid;
    BOOL resumeSucceeded = NO;
    __block NSURLSessionDownloadTask *downloadTask = nil;
    // Try to resume with resumeData.
    // Even though we try to validate the resumeData, this may still fail and raise excecption.
    if (canBeResumed) {
        @try {
            downloadTask = [self.sessionManager downloadTaskWithResumeData:data progress:downloadRequest.progressBlock destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                return [NSURL fileURLWithPath:downloadFileSavePath isDirectory:NO];
            } completionHandler:
                            ^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                                [self handleResponseResult:downloadTask responseObject:filePath error:error];
                            }];
            resumeSucceeded = YES;
        } @catch (NSException *exception) {
            //YTKLog(@"Resume download failed, reason = %@", exception.reason);
            resumeSucceeded = NO;
        }
    }
    if (!resumeSucceeded) {
        downloadTask = [self.sessionManager downloadTaskWithRequest:urlRequest progress:downloadRequest.progressBlock destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            return [NSURL fileURLWithPath:downloadFileSavePath isDirectory:NO];
        } completionHandler:
                        ^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                            [self handleResponseResult:downloadTask responseObject:filePath error:error];
                        }];
    }
    [downloadRequest setIdentifier:downloadTask.taskIdentifier];
    [downloadTask resume];
    
    return downloadRequest.identifier;

}
- (NSURL *)incompleteDownloadTempPathForDownloadPath:(NSString *)downloadPath {
    NSString *tempPath = nil;
    NSString *md5URLString = [RBNetworkUtilities md5String:downloadPath];
    tempPath = [[self downloadTempCacheFolder] stringByAppendingPathComponent:md5URLString];
    return [NSURL fileURLWithPath:tempPath];
}
- (NSString *)downloadTempCacheFolder {
    NSFileManager *fileManager = [NSFileManager new];
    static NSString *tempFolder;
    if (!tempFolder) {
        NSString *tempDir = NSTemporaryDirectory();
        tempFolder = [tempDir stringByAppendingPathComponent:@"RBDownloadTemp"];
    }
    
    NSError *error = nil;
    if(![fileManager createDirectoryAtPath:tempFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
        tempFolder = nil;
    }
    return tempFolder;
}


+ (void)cancelRequest:(NSUInteger)identifier {
    [self cancelRequest:identifier onCancel:nil];
}

+ (void)cancelRequest:(NSUInteger)identifier
             onCancel:(nullable RBCancelBlock)cancelBlock {
    RBNetworkRequest *request = [[RBNetworkEngine defaultEngine] cancelRequestByIdentifier:identifier];
    RB_SAFE_BLOCK(cancelBlock, request);
}
- (nullable RBNetworkRequest *)cancelRequestByIdentifier:(NSUInteger)identifier {
    if (identifier == 0) return nil;
    __block RBNetworkRequest *request = nil;
    Lock();
    [self.sessionManager.tasks enumerateObjectsUsingBlock:^(NSURLSessionTask *task, NSUInteger idx, BOOL *stop) {
        if (task.taskIdentifier == identifier) {
            [task cancel];
            *stop = YES;
        }
    }];
    Unlock();
    return request;
}

@end
