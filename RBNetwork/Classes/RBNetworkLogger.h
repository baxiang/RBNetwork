//
//  PDNetworkLogger.h
//  Pudding
//
//  Created by baxiang on 16/8/29.
//  Copyright © 2016年 Zhi Kuiyu. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface RBNetworkLogger: NSObject

@property (nonatomic, strong) NSPredicate *filterPredicate;

+ (instancetype)sharedLogger;


/**
 开始log打印
 */
- (void)startLogging;

/**
 关闭log打印
 */
- (void)stopLogging;
@end
