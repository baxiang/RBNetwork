//
//  RBViewController.m
//  RBNetwork
//
//  Created by baxiang on 10/25/2016.
//  Copyright (c) 2016 baxiang. All rights reserved.
//

#import "RBViewController.h"
#import "RBNetwork.h"
#import "WeiboSDK.h"
//#import "WXApi.h"
#define kRedirectURI    @"http://www.sina.com"
@interface RBViewController ()

@end

@implementation RBViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    if (![self isLogin]) {
        UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"重要提醒" message:@"需要登录微博" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"登录", nil];
        [alter show];
    }
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (alertView.cancelButtonIndex!= buttonIndex) {
        [self loginFromWeibo];
    }
}
-(BOOL)isLogin{
    NSString *tokenStr  = [[NSUserDefaults standardUserDefaults] objectForKey:@"RBAccessToken"];
    NSString *userStr  = [[NSUserDefaults standardUserDefaults] objectForKey:@"RBuserID"];
    if (tokenStr&&userStr) {
        return YES;
    }else{
        return NO;
    }

}
- (void)loginFromWeibo
{
    WBAuthorizeRequest *request = [WBAuthorizeRequest request];
    request.redirectURI = kRedirectURI;
    request.scope = @"all";
    [WeiboSDK sendRequest:request];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
