//
//  PDNetworkConfig.m
//  
//
//  Created by baxiang on 16/8/29.
//  Copyright © 2016年 baxiang. All rights reserved.
//

#import "RBNetworkConfig.h"
#import "RBNetworkLogger.h"

@implementation RBNetworkConfig
+ (RBNetworkConfig *)defaultConfig {
    static RBNetworkConfig *_defaultConfig = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultConfig = [[self alloc] init];
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
        
        NSString *docmentPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        NSString *tempDownloadFolder = [docmentPath stringByAppendingPathComponent:@"RBNetworkDownload"];
        NSError *error = nil;
        if (![[NSFileManager defaultManager] fileExistsAtPath:tempDownloadFolder]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:tempDownloadFolder withIntermediateDirectories:YES attributes:nil error:&error];
        }
        _defaultDownloadFolder = tempDownloadFolder;
#ifdef DEBUG
        [[RBNetworkLogger sharedLogger] startLogging:YES];
#endif
    }
    return self;
}
-(void)setupEnableDebug:(BOOL)enableDebug{
    [[RBNetworkLogger sharedLogger] startLogging:enableDebug];
}

@end
