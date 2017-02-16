//
//  PDNetworkLogger.h
//  
//
//  Created by baxiang on 16/8/29.
//  Copyright © 2016年 baxiang. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface RBNetworkLogger: NSObject

+ (instancetype)sharedLogger;

/**
 开始log打印
 */
- (void)startLogging:(BOOL)enableDebug;


@end
