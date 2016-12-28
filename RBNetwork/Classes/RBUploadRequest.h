//
//  RBUploadRequest.h
//  Pudding
//
//  Created by baxiang on 16/8/29.
//  Copyright © 2016年 Zhi Kuiyu. All rights reserved.
//

#import "RBNetworkRequest.h"
#import <AFNetworking/AFURLRequestSerialization.h>
typedef void (^RBConstructingBlock)(id<AFMultipartFormData> _Nullable formData);


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

/**
 *  数据上传upload.
 */
@interface RBUploadRequest : RBNetworkRequest
@property(nonatomic,strong,nullable) NSMutableArray<RBUploadFormData *>*uploadFormDatas;
@property (nonatomic, copy, nullable) RBConstructingBlock constructingBodyBlock;
+(void)uploadWithURL:(nullable NSString*)URL parametes:(nullable NSDictionary*)parametes bodyBlock:(nullable RBConstructingBlock)bodyBlock progress:(nullable RBRequestProgressBlock)progressBlock complete:(nullable RBRequestCompletionBlock) completionBlock;

- (void)addFormDataWithName:(nonnull NSString *)name fileData:(nonnull NSData *)fileData;
- (void)addFormDataWithName:(nonnull NSString *)name fileName:(nullable NSString *)fileName mimeType:(nullable NSString *)mimeType fileData:(nonnull NSData *)fileData;
- (void)addFormDataWithName:(nonnull NSString *)name fileURL:(nonnull NSURL *)fileURL;
- (void)addFormDataWithName:(nonnull NSString *)name fileName:(nullable NSString *)fileName mimeType:(nullable NSString *)mimeType fileURL:(nonnull NSURL *)fileURL;
@end
