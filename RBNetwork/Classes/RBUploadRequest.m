//
//  RBUploadRequest.m
//  Pudding
//
//  Created by baxiang on 16/8/29.
//  Copyright © 2016年 Zhi Kuiyu. All rights reserved.
//

#import "RBUploadRequest.h"

@implementation RBUploadRequest
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.requestMethod = RBRequestMethodPost;
    }
    return self;
}
+(void)uploadWithURL:(nullable NSString*)URL parametes:(nullable NSDictionary*)parametes bodyBlock:(nullable RBConstructingBlock)bodyBlock progress:(nullable RBRequestProgressBlock)progressBlock complete:(nullable RBRequestCompletionBlock) completionBlock{
    RBUploadRequest *uploadRequest = [[RBUploadRequest alloc] initWithURLString:URL method:RBRequestMethodPost params:parametes];
    uploadRequest.constructingBodyBlock = bodyBlock;
    uploadRequest.progerssBlock = progressBlock;
    uploadRequest.completionBlock = completionBlock;
    [uploadRequest start];

}
@end
