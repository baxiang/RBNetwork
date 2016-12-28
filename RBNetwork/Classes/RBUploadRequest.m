//
//  RBUploadRequest.m
//  Pudding
//
//  Created by baxiang on 16/8/29.
//  Copyright © 2016年 Zhi Kuiyu. All rights reserved.
//

#import "RBUploadRequest.h"
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

@implementation RBUploadRequest
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.requestMethod = RBRequestMethodPost;
    }
    return self;
}
- (NSMutableArray<RBUploadFormData *> *)uploadFormDatas {
    if (!_uploadFormDatas) {
        _uploadFormDatas = [NSMutableArray array];
    }
    return _uploadFormDatas;
}

+(void)uploadWithURL:(nullable NSString*)URL parametes:(nullable NSDictionary*)parametes bodyBlock:(nullable RBConstructingBlock)bodyBlock progress:(nullable RBRequestProgressBlock)progressBlock complete:(nullable RBRequestCompletionBlock) completionBlock{
    RBUploadRequest *uploadRequest = [[RBUploadRequest alloc] initWithURLString:URL method:RBRequestMethodPost params:parametes];
    uploadRequest.constructingBodyBlock = bodyBlock;
    //uploadRequest.progerssBlock = progressBlock;
    //uploadRequest.completionBlock = completionBlock;
    [uploadRequest start];

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

@end
