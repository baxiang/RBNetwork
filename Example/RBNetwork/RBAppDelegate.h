//
//  RBAppDelegate.h
//  RBNetwork
//
//  Created by baxiang on 10/25/2016.
//  Copyright (c) 2016 baxiang. All rights reserved.
//

@import UIKit;
#import "WeiboSDK.h"
@interface RBAppDelegate : UIResponder <UIApplicationDelegate,WeiboSDKDelegate>
@property (strong, nonatomic) UIWindow *window;

@end
