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
/**
 *  数据上传upload.
 */
@interface RBUploadRequest : RBNetworkRequest
@property (nonatomic, copy, nullable) RBConstructingBlock constructingBodyBlock;
+(void)uploadWithURL:(nullable NSString*)URL parametes:(nullable NSDictionary*)parametes bodyBlock:(nullable RBConstructingBlock)bodyBlock progress:(nullable RBRequestProgressBlock)progressBlock complete:(nullable RBRequestCompletionBlock) completionBlock;
@end
