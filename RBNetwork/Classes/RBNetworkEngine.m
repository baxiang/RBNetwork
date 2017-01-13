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
//#import  <objc/runtime.h>
#import "RBNetworkUtilities.h"
#import <pthread/pthread.h>
#import "AFNetworkActivityIndicatorManager.h"

typedef void (^RBConstructingFormDataBlock)(id<AFMultipartFormData> formData);

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
@end
@implementation RBNetworkEngine{
  
    OSSpinLock _lock;
    AFJSONResponseSerializer *_jsonResponseSerializer;
    AFXMLParserResponseSerializer *_xmlResponseSerialzier;
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
        _lock = OS_SPINLOCK_INIT;
        
    }
    return self;
}

- (AFJSONResponseSerializer *)jsonResponseSerializer {
    if (!_jsonResponseSerializer) {
        _jsonResponseSerializer = [AFJSONResponseSerializer serializer];
        _jsonResponseSerializer.removesKeysWithNullValues = YES;
        
    }
    return _jsonResponseSerializer;
}
- (AFXMLParserResponseSerializer *)xmlParserResponseSerialzier {
    if (!_xmlResponseSerialzier) {
        _xmlResponseSerialzier = [AFXMLParserResponseSerializer serializer];
    }
    return _xmlResponseSerialzier;
}

- (NSInteger)networkReachability {
    return [AFNetworkReachabilityManager sharedManager].networkReachabilityStatus;
}

#pragma mark network config 请求配置

- (NSString *)httpMethodStringByRequest:(__kindof RBNetworkRequest  *)request
{
    NSString *method = nil;
    switch (request.method)
    {
        case RBRequestMethodGet:
            method = @"GET";
            break;
        case RBRequestMethodPost:
            method = @"POST";
            break;
        case RBRequestMethodPut:
            method = @"PUT";
            break;
        case RBRequestMethodDelete:
            method = @"DELETE";
            break;
        case RBRequestMethodOptions:
            method = @"OPTIONS";
            break;
        case RBRequestMethodHead:
            method = @"HEAD";
            break;
        default:
            method = @"GET";
            break;
    }
    return method;
}


-(NSMutableURLRequest *)_constructRequestConfigByRequest:(__kindof RBNetworkRequest *)requestTask bodyWithBlock:(void(^)(id<AFMultipartFormData> _Nonnull formData))formDataBlock{
    if (requestTask.url.length == 0) {
        if (requestTask.server.length == 0) {
            requestTask.server =  [RBNetworkConfig defaultConfig].defaultURL;
        }
        if (requestTask.api.length > 0) {
            NSURL *baseURL = [NSURL URLWithString:requestTask.server];
            // ensure terminal slash for baseURL path, so that NSURL +URLWithString:relativeToURL: works as expected.
            if ([[baseURL path] length] > 0 && ![[baseURL absoluteString] hasSuffix:@"/"]) {
                baseURL = [baseURL URLByAppendingPathComponent:@""];
            }
            requestTask.url = [[NSURL URLWithString:requestTask.api relativeToURL:baseURL] absoluteString];
        } else {
            requestTask.url = requestTask.server;
        }
    }
    NSAssert(requestTask.url.length > 0, @"The request url can't be null.");
    
    if (requestTask.addDefaultParameters) {
        NSDictionary *defaultParameter  = [RBNetworkConfig defaultConfig].defaultParameters;
        if (defaultParameter.count>0) {
            NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
            [parameters addEntriesFromDictionary:defaultParameter];
            if (requestTask.parameters.count) {
                [parameters addEntriesFromDictionary:requestTask.parameters];
            }
            requestTask.parameters = parameters;
        }
    }
    
    if (requestTask.addDefaultHeaders) {
        NSDictionary *defaultHeaders  = [RBNetworkConfig defaultConfig].defaultHeaders;
        if (defaultHeaders.count>0) {
            NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
            [parameters addEntriesFromDictionary:defaultHeaders];
            if (requestTask.headers.count) {
                [parameters addEntriesFromDictionary:requestTask.headers];
            }
            requestTask.headers = parameters;
        }
    }
    AFHTTPRequestSerializer *requestSerializer = self.sessionManager;
    switch (requestTask.requestSerializerType) {
        case RBRequestSerializerTypeHTTP:
            requestSerializer= [AFHTTPRequestSerializer serializer];
            break;
        case RBRequestSerializerTypeJSON:
            if (![requestSerializer isKindOfClass:[AFJSONRequestSerializer class]]) {
                requestSerializer = [AFJSONRequestSerializer serializer];
            }
            break;
        case RBRequestSerializerTypePropertyList:
            if (![requestSerializer isKindOfClass:[AFPropertyListRequestSerializer class]]) {
                requestSerializer = [AFPropertyListRequestSerializer serializer];
            }
            break;
        default:
            break;
    }
    NSString *methodString = [self httpMethodStringByRequest:requestTask];
    NSError *serializationError = nil;
    NSMutableURLRequest *request = nil;
    if (formDataBlock) {
       request = [requestSerializer multipartFormRequestWithMethod:methodString URLString:requestTask.url parameters:requestTask.parameters constructingBodyWithBlock:formDataBlock error:&serializationError];
    }else{
       request = [requestSerializer requestWithMethod:methodString URLString:requestTask.url parameters:requestTask.parameters error:&serializationError];
    }
    if (serializationError) {
        if (requestTask.failureBlock) {
            requestTask.failureBlock(serializationError);
        }
        return  request;
    }
    if (requestTask.headers.count > 0) {
        [requestTask.headers enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL * __unused stop) {
            [request setValue:value forHTTPHeaderField:field];
        }];
    }
    request.timeoutInterval = requestTask.timeout;
    return  request;
}

- (void)_responseSerializerByRequest:(__kindof RBNetworkRequest *)request {
    switch (request.responseSerializerType) {
        case RBResponseSerializerTypeHTTP:
            self.sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
            break;
        case RBResponseSerializerTypeJSON:
            if (![self.sessionManager.responseSerializer isKindOfClass:[AFJSONResponseSerializer class]]) {
                self.sessionManager.responseSerializer = _jsonResponseSerializer;
            }
            break;
        case RBResponseSerializerTypeXML:
            if (![self.sessionManager.responseSerializer isKindOfClass:[AFXMLParserResponseSerializer class]]) {
                self.sessionManager.responseSerializer = _xmlResponseSerialzier;
            }
            break;
        case RBResponseSerializerTypePropertyList:
            if (![self.sessionManager.responseSerializer isKindOfClass:[AFPropertyListResponseSerializer class]]) {
                self.sessionManager.responseSerializer = [AFPropertyListResponseSerializer serializer];
            }
            break;
        default:
            break;
    }
    self.sessionManager.responseSerializer.acceptableStatusCodes = request.acceptableStatusCodes;
    self.sessionManager.responseSerializer.acceptableContentTypes = request.acceptableContentTypes;
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
    switch (request.type) {
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

-(void)_startDefaultTask:(RBNetworkRequest *)requestTask{
    NSMutableURLRequest *request =  [self _constructRequestConfigByRequest:requestTask bodyWithBlock:nil];
    __block NSURLSessionDataTask *dataTask = nil;
    __weak __typeof(self)weakSelf = self;
    dataTask = [self.sessionManager dataTaskWithRequest:request
                                      completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
                                          __strong __typeof(weakSelf)strongSelf = weakSelf;
                                          [self handleResponseResult:dataTask responseObject:responseObject error:error];
                                      }];
    requestTask.requestTask = dataTask;
    [dataTask resume];
    [self _addRequestTask:requestTask];
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
    }
    RB_SAFE_BLOCK(request.finishBlock,request.responseObject,requestError);
    if (succeed) {
        [self requestDidSucceedWithRequest:request];
    } else {
        [self requestDidFailWithRequest:request error:error];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [request clearRequestBlock];
    });
}
- (void)requestDidSucceedWithRequest:(RBNetworkRequest *)request {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (request.successBlock) {
            request.successBlock(request.responseObject);
        }
    });
}

- (void)requestDidFailWithRequest:(RBNetworkRequest *)request error:(NSError *)error {
    if (request.resumableDownloadPath) {
        NSData *incompleteDownloadData = error.userInfo[NSURLSessionDownloadTaskResumeData];
        if (incompleteDownloadData) {
            [incompleteDownloadData writeToURL:[self incompleteDownloadTempPathForDownloadPath:request.resumableDownloadPath] atomically:YES];
        }
    }
    if ([request.responseObject isKindOfClass:[NSURL class]]) {
        NSURL *url = request.responseObject;
        if (url.isFileURL && [[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
            request.responseData = [NSData dataWithContentsOfURL:url];
            [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
        }
        request.responseObject = nil;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (request.failureBlock) {
            request.failureBlock(error);
        }

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


#pragma mark upload

- (void)_startUploadTask:(RBNetworkRequest *)uploadTask{
    RBConstructingFormDataBlock formDataBlock =  ^( id <AFMultipartFormData> formData) {
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
                    *stop = YES;
                }
            }
        }];
    
      };
      NSMutableURLRequest  *request =[self _constructRequestConfigByRequest:uploadTask bodyWithBlock:formDataBlock];
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
    uploadTask.requestTask = uploadDataTask;
    [uploadDataTask resume];
    [self _addRequestTask:uploadTask];
}


#pragma mark download
-(void)_startDownloadTask:(RBNetworkRequest*)downloadRequest{
    NSMutableURLRequest *urlRequest = [self _constructRequestConfigByRequest:downloadRequest bodyWithBlock:nil];
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
    downloadRequest.requestTask = downloadTask;
    [downloadTask resume];
    [self _addRequestTask:downloadRequest];
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


- (void)_addRequestTask:(__kindof RBNetworkRequest*)request {
    if (request == nil)    return;
    Lock();
    _requestRecordDict[@(request.requestTask.taskIdentifier)] = request;;
    Unlock();
}

- (void)_removeRequestTask:(__kindof RBNetworkRequest*)request {
    if(request == nil)  return;
    Lock();
    [_requestRecordDict removeObjectForKey:@(request.requestTask.taskIdentifier)];
    Unlock();
}


- (void)cancelRequest:(RBNetworkRequest *)request {
    NSParameterAssert(request != nil);
    [request.requestTask cancel];
    [self _removeRequestTask:request];
    [request clearRequestBlock];
}

- (void)cancelAllRequests {
    Lock();
    NSArray *allKeys = [_requestRecordDict allKeys];
    Unlock();
    if (allKeys && allKeys.count > 0) {
        NSArray *copiedKeys = [allKeys copy];
        for (NSNumber *key in copiedKeys) {
            Lock();
            RBNetworkRequest *request = _requestRecordDict[key];
            Unlock();
            [self cancelRequest:request];
        }
    }
}

@end
