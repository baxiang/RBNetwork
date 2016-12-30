//
//  RBNetworkEngine.m
//  Pudding
//
//  Created by baxiang on 16/8/29.
//  Copyright © 2016年 Zhi Kuiyu. All rights reserved.
//

#import "RBNetworkEngine.h"
#import "AFNetworking.h"
#import "RBUploadRequest.h"
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
        //_jsonResponseSerializer.acceptableContentTypes = [RBNetworkConfig defaultConfig].acceptableContentTypes;
    }
    return _jsonResponseSerializer;
}

- (void)executeRequestTask:(RBNetworkRequest *)request{
    if (![self networkReachability]) {
        NSError *error =[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNotConnectedToInternet description:@"网络连接失败"];
        if (request.failureBlock) {
             request.failureBlock(error);
        }
        return;
    }
    NSIndexSet *acceptableStatusCodes = request.acceptableStatusCodes ?: [RBNetworkConfig defaultConfig].defaultAcceptableStatusCodes;
    if (acceptableStatusCodes) {
        self.sessionManager.responseSerializer.acceptableStatusCodes = acceptableStatusCodes;
    }
    if ([request isKindOfClass:[RBDownloadRequest class]]) {
        //[self _startDownloadTask:(RBDownloadRequest*)request];
    }else if ([request isKindOfClass:[RBUploadRequest class]]){
        [self _startUploadTask:(RBUploadRequest*)request];
    }else{
        [self _startDefaultTask:request];
    }
}
+ (void)constructRequest:(RBNetworkRequest *)request
               onProgress:(RBProgressBlock)progressBlock
                onSuccess:(RBSuccessBlock)successBlock
                onFailure:(RBFailureBlock)failureBlock{
    
    // set callback blocks for the request object.
    if (successBlock) {
        [request setValue:successBlock forKey:@"_successBlock"];
    }
    if (failureBlock) {
        [request setValue:failureBlock forKey:@"_failureBlock"];
    }
    if (progressBlock) {
        [request setValue:progressBlock forKey:@"_progressBlock"];
    }
//    if (progressBlock && request.requestType != kXMRequestNormal) {
//        [request setValue:progressBlock forKey:@"_progressBlock"];
//    }
}
+ (NSUInteger)sendRequest:(RBRequestBlock)requestBlock
                onSuccess:(nullable RBSuccessBlock)successBlock
                onFailure:(nullable RBFailureBlock)failureBlock{
    RBNetworkRequest *request = [RBNetworkRequest new];
    if (requestBlock) {
        requestBlock(request);
    }
    [RBNetworkEngine constructRequest:request onProgress:nil onSuccess:successBlock onFailure:failureBlock];
    [[RBNetworkEngine defaultEngine] _startDefaultTask:request];

}
+(NSUInteger)uploadRequest:(RBUploadBlock)uploadBlock onProgress:(RBProgressBlock)progressBlock onSuccess:(RBSuccessBlock)successBlock onFailure:(RBFailureBlock)failureBlock{
    RBUploadRequest *request = [RBUploadRequest new];
    if (uploadBlock) {
        uploadBlock(request);
    }
    [RBNetworkEngine constructRequest:request onProgress:nil onSuccess:successBlock onFailure:failureBlock];
    [[RBNetworkEngine defaultEngine] _startUploadTask:request];
}

- (NSUInteger)sendRequest:(RBRequestBlock)requestBlock
               onProgress:(nullable RBProgressBlock)progressBlock
                onSuccess:(nullable RBSuccessBlock)successBlock
                onFailure:(nullable RBFailureBlock)failureBlock{
    
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
    request.responseObject = responseObject;
    BOOL succeed = YES;
    if ([request.responseObject isKindOfClass:[NSData class]]) {
        request.responseData = responseObject;
//        request.responseString = [[NSString alloc] initWithData:responseObject encoding:[YTKNetworkUtils stringEncodingWithRequest:request]];
       
        switch (request.responseSerializerType) {
            case RBResponseSerializerTypeHTTP:
                // Default serializer. Do nothing.
                break;
            case RBResponseSerializerTypeJSON:
                request.responseObject = [self.jsonResponseSerializer responseObjectForResponse:task.response data:request.responseData error:&serializationError];
                //request.responseJSONObject = request.responseObject;
                break;
//            case YTKResponseSerializerTypeXMLParser:
//                request.responseObject = [self.xmlParserResponseSerialzier responseObjectForResponse:task.response data:request.responseData error:&serializationError];
//                break;
        }
    }
    if (error) {
        succeed = NO;
        //requestError = error;
    } else if (serializationError) {
        succeed = NO;
        //requestError = serializationError;
    } else {
        //succeed = [self validateResult:request error:&validationError];
        //requestError = validationError;
    }
    
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
//    request.error = error;
//    YTKLog(@"Request %@ failed, status code = %ld, error = %@",
//           NSStringFromClass([request class]), (long)request.responseStatusCode, error.localizedDescription);
    if ([request isKindOfClass:[RBDownloadRequest class]]) {
        RBDownloadRequest *downLoadRequest = request;
        NSData *incompleteDownloadData = error.userInfo[NSURLSessionDownloadTaskResumeData];
        if (incompleteDownloadData) {
            [incompleteDownloadData writeToURL:[self incompleteDownloadTempPathForDownloadPath:downLoadRequest.resumableDownloadPath] atomically:YES];
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

- (NSInteger)_startUploadTask:(RBUploadRequest *)uploadTask{
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
- (void)handleRequestSuccess:(NSURLSessionTask *)sessionTask responseObject:(id)response {
    RBNetworkRequest  *request = _requestRecordDict[@(sessionTask.taskIdentifier)];
    request.statusCode = [(NSHTTPURLResponse *)sessionTask.response statusCode];
    [self removeRequestObject:request];
    if(request.successBlock) {
        request.isCacheData = NO;
        //id  jsonData =[response valueForKeyPath:request.responseContentDataKey];
        request.successBlock(response);
    }
}
- (void)handleRequestFailure:(NSURLSessionTask *)sessionTask responseObject:responseObject error:(NSError *)error {
    RBNetworkRequest  *request = _requestRecordDict[@(sessionTask.taskIdentifier)];
    request.statusCode = [(NSHTTPURLResponse *)sessionTask.response statusCode];
    [self removeRequestObject:request];
    if (request.failureBlock) {
        request.failureBlock(error);
    }
    
}

#pragma mark download
-(NSInteger)_startDownloadTask:(RBDownloadRequest*)downloadRequest{
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

//-(void)_startDownloadTask:(RBDownloadRequest *)downloadRequest{
//    if ([[NSFileManager defaultManager] fileExistsAtPath:downloadRequest.filePath]) {
//        if (downloadRequest.completionBlock) {
//             downloadRequest.completionBlock(downloadRequest,[NSURL fileURLWithPath:downloadRequest.filePath],nil);
//        }
//        return ;
//    }
//    //NSString*urlStr = [self urlStringByRequest:downloadRequest];
//    NSDictionary*paramsDict = [self requestParamByRequest:downloadRequest];
//    downloadRequest.resumeData = [NSData dataWithContentsOfFile:downloadRequest.resumeFilePath];
//    if (downloadRequest.resumeData.length == 0) {
//        NSMutableURLRequest *request = [self.sessionManager.requestSerializer requestWithMethod:downloadRequest.httpMethodString URLString:urlStr parameters:paramsDict error:nil];
//        downloadRequest.downloadTask = [self.sessionManager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
//            [self setValuesForDownloadModel:downloadRequest withProgress:downloadProgress.fractionCompleted];
//            if (downloadRequest.progerssBlock) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    downloadRequest.progerssBlock(downloadRequest,downloadProgress);
//                });
//                
//            }
//        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
//            return [NSURL fileURLWithPath:downloadRequest.filePath];
//        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
//            if (error) {
//                [self _cancelDownloadTaskWithDownloadModel:downloadRequest];
//                if (downloadRequest.completionBlock) {
//                     NSError *downError = [NSError errorWithDomain:RBNetworkRequestErrorDomain code:RBErrorCodeDownloadFailure description:@"下载失败"];
//                     downloadRequest.completionBlock(downloadRequest,nil,downError);
//                }
//               
//            }else{
//                [self.downloadModelsDict removeObjectForKey:urlStr];
//                if (downloadRequest.completionBlock) {
//                    downloadRequest.completionBlock(downloadRequest,[NSURL fileURLWithPath:downloadRequest.filePath],nil);
//                }
//                [self deletePlistFileWithDownloadModel:downloadRequest];
//            }
//        }];
//        
//    }else{
//        
//        downloadRequest.totalBytesWritten = [self getResumeByteWithDownloadModel:downloadRequest];
//        downloadRequest.downloadTask = [self.sessionManager downloadTaskWithResumeData:downloadRequest.resumeData progress:^(NSProgress * _Nonnull downloadProgress) {
//            [self setValuesForDownloadModel:downloadRequest withProgress:[self.sessionManager downloadProgressForTask:downloadRequest.downloadTask].fractionCompleted];if (downloadRequest.progerssBlock) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    downloadRequest.progerssBlock(downloadRequest,downloadProgress);
//                });
//            } downloadRequest.progerssBlock(downloadRequest,downloadProgress);
//            
//        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
//            return [NSURL fileURLWithPath:downloadRequest.filePath];
//        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
//            if (error) {
//                [self _cancelDownloadTaskWithDownloadModel:downloadRequest];
//                if (downloadRequest.completionBlock) {
//                   downloadRequest.completionBlock(downloadRequest,nil,error);
//                }
//            }else{
//                [self.downloadModelsDict removeObjectForKey:urlStr];
//                if (downloadRequest.completionBlock) {
//                    downloadRequest.completionBlock(downloadRequest,[NSURL fileURLWithPath:downloadRequest.filePath],nil);
//                }
//                
//                [self deletePlistFileWithDownloadModel:downloadRequest];
//            }
//        }];
//    }
//    [self _resumeDownloadWithDownloadModel:downloadRequest];
//}
//
//-(void)_resumeDownloadWithDownloadModel:(RBDownloadRequest *)downloadModel{
//    if (downloadModel.downloadTask) {
//        downloadModel.downloadDate = [NSDate date];
//        [downloadModel.downloadTask resume];
//        self.downloadModelsDict[downloadModel.RB_URLString] = downloadModel;
//        [self.downloadingModels addObject:downloadModel];
//    }
//}
//
//-(void)_cancelDownloadTaskWithDownloadModel:(RBDownloadRequest *)downloadModel{
//    if (!downloadModel) return;
//    NSURLSessionTaskState state = downloadModel.downloadTask.state;
//    if (state == NSURLSessionTaskStateRunning) {
//        [downloadModel.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
//            downloadModel.resumeData = resumeData;
//            @synchronized (self) {
//                BOOL isSuc = [downloadModel.resumeData writeToFile:downloadModel.resumeFilePath atomically:YES];
//                [self saveTotalBytesExpectedToWriteWithDownloadModel:downloadModel];
//                if (isSuc) {
//                    downloadModel.resumeData = nil;
//                    [self.downloadModelsDict removeObjectForKey:downloadModel.RB_URLString];
//                    [self.downloadingModels removeObject:downloadModel];
//                }
//            }
//        }];
//    }
//}
//
//
//-(RBDownloadRequest *)_getDownloadingModelWithURLString:(NSString *)URLString{
//    return self.downloadModelsDict[URLString];
//}
//
//#pragma mark - private methods
//
//-(void)setValuesForDownloadModel:(RBDownloadRequest *)downloadModel withProgress:(double)progress{
//    NSTimeInterval interval = -1 * [downloadModel.downloadDate timeIntervalSinceNow];
//    downloadModel.totalBytesWritten = downloadModel.downloadTask.countOfBytesReceived;
//    downloadModel.totalBytesExpectedToWrite = downloadModel.downloadTask.countOfBytesExpectedToReceive;
//    downloadModel.downloadProgress = progress;
//    downloadModel.downloadSpeed = (int64_t)((downloadModel.totalBytesWritten - [self getResumeByteWithDownloadModel:downloadModel]) / interval);
//    if (downloadModel.downloadSpeed != 0) {
//        int64_t remainingContentLength = downloadModel.totalBytesExpectedToWrite  - downloadModel.totalBytesWritten;
//        int currentLeftTime = (int)(remainingContentLength / downloadModel.downloadSpeed);
//        downloadModel.downloadLeft = currentLeftTime;
//    }
//}
//
//-(int64_t)getResumeByteWithDownloadModel:(RBDownloadRequest *)downloadModel{
//    int64_t resumeBytes = 0;
//    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:downloadModel.resumeFilePath];
//    if (dict) {
//        resumeBytes = [dict[@"NSURLSessionResumeBytesReceived"] longLongValue];
//    }
//    return resumeBytes;
//}
//
//-(NSString *)getTmpFileNameWithDownloadModel:(RBDownloadRequest *)downloadModel{
//    NSString *fileName = nil;
//    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:downloadModel.resumeFilePath];
//    if (dict) {
//        fileName = dict[@"NSURLSessionResumeInfoTempFileName"];
//    }
//    return fileName;
//}
//
//-(void)createFolderAtPath:(NSString *)path{
//    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) return;
//    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
//}
//
//-(void)deletePlistFileWithDownloadModel:(RBDownloadRequest *)downloadModel{
//    if (downloadModel.downloadTask.countOfBytesReceived == downloadModel.downloadTask.countOfBytesExpectedToReceive) {
//        [[NSFileManager defaultManager] removeItemAtPath:downloadModel.resumeFilePath error:nil];
//        [self removeTotalBytesExpectedToWriteWhenDownloadFinishedWithDownloadModel:downloadModel];
//    }
//}
//
//-(NSString *)managerPlistFilePath{
//    NSString *downloadPath =[RBNetworkConfig defaultConfig].downloadFolderPath;
//    if (![[NSFileManager defaultManager] fileExistsAtPath:downloadPath]) {
//        [[NSFileManager defaultManager] createDirectoryAtPath:downloadPath withIntermediateDirectories:YES attributes:nil error:nil];
//    }
//    return [downloadPath stringByAppendingPathComponent:@"RBDownloadManager.plist"];
//}
//
//-(nullable NSMutableDictionary <NSString *, NSString *> *)managerPlistDict{
//    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:[self managerPlistFilePath]];
//    return dict;
//}
//
//-(void)saveTotalBytesExpectedToWriteWithDownloadModel:(RBDownloadRequest *)downloadModel{
//    NSMutableDictionary <NSString *, NSString *> *dict = [self managerPlistDict];
//    [dict setValue:[NSString stringWithFormat:@"%lld", downloadModel.downloadTask.countOfBytesExpectedToReceive] forKey:downloadModel.RB_URLString];
//    [dict writeToFile:[self managerPlistFilePath] atomically:YES];
//}
//
//-(void)removeTotalBytesExpectedToWriteWhenDownloadFinishedWithDownloadModel:(RBDownloadRequest *)downloadModel{
//    NSMutableDictionary <NSString *, NSString *> *dict = [self managerPlistDict];
//    [dict removeObjectForKey:downloadModel.RB_URLString];
//    [dict writeToFile:[self managerPlistFilePath] atomically:YES];
//}

@end
