//
//  RBNetworkRequest.m
//  
//
//  Created by baxiang on 16/8/29.
//  Copyright © 2016年 baxiang. All rights reserved.
//

#import "RBNetworkRequest.h"
#import "RBNetworkConfig.h"
#import "RBNetworkEngine.h"
@implementation RBNetworkRequest

-(instancetype)init{
    if (self = [super init]) {
        RBNetworkConfig *defaultConfig = [RBNetworkConfig defaultConfig];
        _method = defaultConfig.defaultRequestMethod;
        _timeout = defaultConfig.defaultTimeoutInterval;
        _requestSerializerType = defaultConfig.defaultRequestSerializer;
        _responseSerializerType = defaultConfig.defaultResponseSerializer;
        _acceptableContentTypes = defaultConfig.defaultAcceptableContentTypes;
        _acceptableStatusCodes = defaultConfig.defaultAcceptableStatusCodes;
        _addDefaultHeaders = YES;
        _addDefaultParameters = YES;
        _allowsCellularAccess = YES;
    }
    return self;
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
   [self clearRequestBlock];
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

