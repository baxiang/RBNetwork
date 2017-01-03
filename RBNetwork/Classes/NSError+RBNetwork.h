//
//  NSError+RBNetwork.h
//  Pudding
//
//  Created by baxiang on 16/9/1.
//  Copyright © 2016年 Zhi Kuiyu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
/**
 *  客户端网络错误
 */
UIKIT_EXTERN  NSString * const RBNetworkRequestErrorDomain;
typedef NS_ENUM(NSInteger, RBErrorCode) {
    
    RBErrorCodeNotConnectedToInternet   = NSURLErrorNotConnectedToInternet,/*网络连接失败*/
    RBErrorCodeTimeout                  = NSURLErrorTimedOut,/*请求超时*/
    RBErrorCodeNetworkConnectionLost    = NSURLErrorNetworkConnectionLost,/*网络连接丢失*/
    RBErrorCodeCannotConnectToHost      = NSURLErrorCannotConnectToHost,/*不能连接到服务器*/
    RBErrorCodeRequestSendFailure = 1003, /*网络请求失败*/
    RBErrorCodeRequestParseFailure = 1004,/*数据解析失败*/
};

@interface NSError (RBNetwork)
-(NSString*)errorDescription;
+(instancetype)errorWithDomain:(NSString *)domain code:(NSInteger)code description:(NSString *)description;
- (BOOL)isNetworkConnectionError;

@end
