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
@property(nonatomic,copy) NSString *weiboToken;
@end
@implementation RBViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"RBNetwork演示Demo";
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:NSStringFromClass([UITableViewCell class])];
    if (![self isLogin]) {
        UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"重要提醒" message:@"需要登录微博" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"登录", nil];
        [alter show];
    }else{
       
     _weiboToken  = [[NSUserDefaults standardUserDefaults] objectForKey:@"RBAccessToken"];
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 10;
}
-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell =  [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([UITableViewCell class])];
    if (indexPath.row==0) {
       cell.textLabel.text = @"GET请求";
    }else if (indexPath.row ==1){
       cell.textLabel.text = @"POST请求";
    }else if (indexPath.row ==2){
        cell.textLabel.text = @"upload请求";
    }else if (indexPath.row ==2){
        cell.textLabel.text = @"队列请求";
    }
    return cell;
}
-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.row == 0) {
        [self fetchPublicTimeline];
    }if (indexPath.row == 1) {
        [self postWeiboTimeLine];
    }if (indexPath.row == 2) {
        [self uploadWeiboPhoto];
    }
}
-(void)fetchPublicTimeline{
    [RBNetworkEngine sendRequest:^(RBNetworkRequest *request) {
        request.api = @"/statuses/public_timeline.json";
        request.method = RBRequestMethodGet;
        request.parameters = @{@"access_token":[NSString stringWithFormat:@"%@",_weiboToken]};
    } onSuccess:^(id responseObject) {
        //NSLog(@"%@",responseObject);
    } onFailure:^(NSError * _Nullable error) {
       // NSLog(@"%@",error);
    }];
    
}
-(void)postWeiboTimeLine{
    [RBNetworkEngine sendRequest:^(RBNetworkRequest *request) {
        request.api = @"/statuses/public_timeline.json";
        request.method = RBRequestMethodGet;
        request.parameters = @{@"access_token":[NSString stringWithFormat:@"%@",_weiboToken]};
    } onSuccess:^(id responseObject) {
        NSLog(@"%@",responseObject);
    } onFailure:^(NSError * _Nullable error) {
        NSLog(@"%@",error);
    }];
    

}
-(void)uploadWeiboPhoto{
   [RBNetworkEngine sendRequest:^(RBNetworkRequest * _Nullable request) {
       request.api = @"/statuses/upload.json";
       request.parameters = @{@"access_token":[NSString stringWithFormat:@"%@",_weiboToken],@"status":@"测试图片微博"};
       NSString *photoPath  = [[NSBundle mainBundle] pathForResource:@"180" ofType:@"png"];
       [request addFormDataWithName:@"pic" fileURL:[NSURL fileURLWithPath:photoPath]];
       request.type = RBRequestUpload;
       request.method = RBRequestMethodPost;
   } onSuccess:^(id  _Nullable responseObject) {
        NSLog(@"%@",responseObject);
   } onFailure:^(NSError * _Nullable error) {
        NSLog(@"%@",error);
   }];
    
}
-(void)refeshWeiboToken{
//   [RBNetworkEngine sendChainRequest:^(RBQueueRequest *queueRequest) {
//       [[queueRequest onFirst:^(RBNetworkRequest *queueRequest) {
//           queueRequest.requestURL = @"";
//       }] onNext:^(RBNetworkRequest *request, id  _Nullable responseObject, BOOL *sendNext) {
//           
//       }];
//   } onSuccess:^(NSArray<id> *responseObjects) {
//       
//   } onFailure:^(NSArray<id> *errors) {
//       
//   }];
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
        NSDate *expirationDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"RBExpirationDate"];
        if ([[NSDate date] compare:expirationDate]==NSOrderedAscending) {
            return YES;
        }
        return NO;
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
