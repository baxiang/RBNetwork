//
//  RBNetworkRequest.m
//  Pudding
//
//  Created by baxiang on 16/8/29.
//  Copyright © 2016年 Zhi Kuiyu. All rights reserved.
//

#import "RBNetworkRequest.h"
#import "RBNetworkConfig.h"
#import "RBNetworkEngine.h"
@implementation RBNetworkRequest

-(instancetype)init{
    if (self = [super init]) {
        RBNetworkConfig *defaultConfig = [RBNetworkConfig defaultConfig];
        _requestMethod = defaultConfig.defaultRequestMethod;
        _requestTimeout = defaultConfig.defaultTimeoutInterval;
        _requestSerializerType = defaultConfig.defaultRequestSerializer;
        _responseSerializerType = defaultConfig.defaultResponseSerializer;
    }
    return self;
}




- (NSString *)httpMethodString
{
    NSString *method = nil;
    switch (self.requestMethod)
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
- (NSMutableArray<RBUploadFormData *> *)uploadFormDatas {
    if (!_uploadFormDatas) {
        _uploadFormDatas = [NSMutableArray array];
    }
    return _uploadFormDatas;
}

- (void)addFormDataWithName:(NSString *)name fileData:(NSData *)fileData {
    RBUploadFormData *formData = [RBUploadFormData formDataWithName:name fileData:fileData];
    [self.uploadFormDatas addObject:formData];
}

- (void)addFormDataWithName:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType fileData:(NSData *)fileData {
    RBUploadFormData *formData = [RBUploadFormData formDataWithName:name fileName:fileName mimeType:mimeType fileData:fileData];
    [self.uploadFormDatas addObject:formData];
}

- (void)addFormDataWithName:(NSString *)name fileURL:(NSURL *)fileURL {
    RBUploadFormData *formData = [RBUploadFormData formDataWithName:name fileURL:fileURL];
    [self.uploadFormDatas addObject:formData];
}

- (void)addFormDataWithName:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType fileURL:(NSURL *)fileURL {
    RBUploadFormData *formData = [RBUploadFormData formDataWithName:name fileName:fileName mimeType:mimeType fileURL:fileURL];
    [self.uploadFormDatas addObject:formData];
}


- (void)clearRequestBlock {
    _successBlock = nil;
    _failureBlock = nil;
    _progressBlock = nil;
}
-(void)dealloc{
    NSLog(@"请求销毁%@",self.class);
   [self clearRequestBlock];
    //_delegate = nil;
}
@end

@implementation RBUploadFormData

+ (instancetype)formDataWithName:(NSString *)name fileData:(NSData *)fileData {
    RBUploadFormData *formData = [[RBUploadFormData alloc] init];
    formData.name = name;
    formData.fileData = fileData;
    return formData;
}

+ (instancetype)formDataWithName:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType fileData:(NSData *)fileData {
    RBUploadFormData *formData = [[RBUploadFormData alloc] init];
    formData.name = name;
    formData.fileName = fileName;
    formData.mimeType = mimeType;
    formData.fileData = fileData;
    return formData;
}

+ (instancetype)formDataWithName:(NSString *)name fileURL:(NSURL *)fileURL {
    RBUploadFormData *formData = [[RBUploadFormData alloc] init];
    formData.name = name;
    formData.fileURL = fileURL;
    return formData;
}

+ (instancetype)formDataWithName:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType fileURL:(NSURL *)fileURL {
    RBUploadFormData *formData = [[RBUploadFormData alloc] init];
    formData.name = name;
    formData.fileName = fileName;
    formData.mimeType = mimeType;
    formData.fileURL = fileURL;
    return formData;
}
@end

