//
//  PDNetworkConfig.m
//  Pudding
//
//  Created by baxiang on 16/8/29.
//  Copyright © 2016年 Zhi Kuiyu. All rights reserved.
//

#import "RBNetworkConfig.h"
#import "RBNetworkLogger.h"
#define  PDNetworkDownloadName @"PDNetworkDownloadName"
@implementation RBNetworkConfig
+ (RBNetworkConfig *)defaultConfig {
    static RBNetworkConfig *_defaultConfig = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultConfig = [[RBNetworkConfig alloc] init];
    });
    return _defaultConfig;
}
- (instancetype)init {
    self = [super init];
    if (self) {
        _defaultRequestMethod = RBRequestMethodGet;
        _defaultAcceptableStatusCodes =  [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(100, 500)];
        _defaultAcceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html",@"text/plain", nil];
        _defaultRequestSerializer = RBRequestSerializerTypeHTTP;
        _defaultResponseSerializer = RBResponseSerializerTypeHTTP;
        _defaultTimeoutInterval = RB_REQUEST_TIMEOUT;
        _defaultAcceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 500)];
        _maxConcurrentOperationCount = RB_MAX_HTTP_CONNECTION;
#ifdef DEBUG
         _enableDebug = YES;
        [[RBNetworkLogger sharedLogger] startLogging:YES];
#else
        _enableDebug = NO;
#endif
        
    }
    return self;
}
-(void)setEnableDebug:(BOOL)enableDebug{
    if (_enableDebug == enableDebug) {
        return;
    }
     _enableDebug = enableDebug;
    [[RBNetworkLogger sharedLogger] startLogging:enableDebug];
   
}
-(NSString *)downloadFolderPath{
    if (!_downloadFolderPath) {
        NSString *docmentPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        NSString *tempDownloadFolder = [docmentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_Download",[[NSBundle mainBundle] bundleIdentifier]]];
        NSError *error = nil;
        if (![[NSFileManager defaultManager] fileExistsAtPath:tempDownloadFolder]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:tempDownloadFolder withIntermediateDirectories:YES attributes:nil error:&error];
        }
        _downloadFolderPath = tempDownloadFolder;
    }
    return _downloadFolderPath;
}


@end
