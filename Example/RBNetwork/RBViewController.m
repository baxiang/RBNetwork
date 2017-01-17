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
#import "AFURLSessionManager.h"

//#import "WXApi.h"
#define kRedirectURI    @"http://www.sina.com"
@interface RBViewController () <NSURLSessionDelegate>
@property(nonatomic,copy) NSString *weiboToken;
@property (nonatomic, strong)NSURLSessionDownloadTask *downTask;

//网络会话
@property (nonatomic, strong)NSURLSession * downLoadSession;
@end
@implementation RBViewController{
    CFAbsoluteTime startTime;

}
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
    }else if (indexPath.row ==3){
        cell.textLabel.text = @"队列请求";
    }else if (indexPath.row ==4){
        cell.textLabel.text = @"下载请求";
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
    }else if (indexPath.row ==4){
        [self downloadVideo];
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

-(NSString*)fetchVideoFolderPath{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *document = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *folder = [document stringByAppendingPathComponent:@"PDFamilyVideo"];
    if (![fileManager fileExistsAtPath:folder]) {
        BOOL blCreateFolder= [fileManager createDirectoryAtPath:folder withIntermediateDirectories:NO attributes:nil error:NULL];
        if (blCreateFolder) {
            NSLog(@" folder success");
        }else {
            NSLog(@" folder fial");
        }
    }else {
        NSLog(@"沙盒文件已经存在");
    }
    return folder;
}
-(void)downloadVideo{
    
      startTime = CFAbsoluteTimeGetCurrent();
////       NSString *downloadPath = @"http://media.roo.bo/voices/moment/1011000000200B87/2016-12-22/20161222_feb7883c4a9a0df157154ae89efd50e8.mp4";
////       NSString *currFilePath = [[self fetchVideoFolderPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4",downloadPath]];
////       NSURL *currFileURL = [NSURL fileURLWithPath:currFilePath];
////    
////        NSURL *videoURL = [NSURL URLWithString:downloadPath];
////        NSURLRequest *request = [NSURLRequest requestWithURL:videoURL];
////        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
////        AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
////        NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress *downloadProgress){
////        } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
////            return currFileURL;
////        } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
////           // completion(filePath,error);
////            NSLog(@"---------%f",CFAbsoluteTimeGetCurrent() - startTime);
////        }];
////        [downloadTask resume];
//    
    [RBNetworkEngine sendRequest:^(RBNetworkRequest * _Nullable request) {
        request.type = RBRequestDownload;
        request.url = @"http://media.roo.bo/voices/moment/1011000000200B87/2016-12-22/20161222_feb7883c4a9a0df157154ae89efd50e8.mp4";
    }onProgress:^(NSProgress * _Nullable progress) {
         //NSLog(@"%f",progress.fractionCompleted);
    }onSuccess:^(id  _Nullable responseObject) {
         NSLog(@"---------%f",CFAbsoluteTimeGetCurrent() - startTime);
        //NSLog(@"%@",responseObject);
    } onFailure:^(NSError * _Nullable error) {
        //NSLog(@"%@",error);
    }];

   // [self URLSessionDownload];
}
-(void)URLSessionDownload{
    NSURLSessionConfiguration   *sessionConfig =[NSURLSessionConfiguration defaultSessionConfiguration];
    //创建网络会话
    self.downLoadSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:[NSOperationQueue new]];
    NSURLRequest *imgRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://media.roo.bo/voices/moment/1011000000200B87/2016-12-22/20161222_feb7883c4a9a0df157154ae89efd50e8.mp4"] cachePolicy:5 timeoutInterval:60.f];
    //创建下载任务
    self.downTask = [self.downLoadSession downloadTaskWithRequest:imgRequest];
    //启动下载任务
    [self.downTask resume];
}


#pragma mark 下载完成 无论成功失败
    
    -(void)URLSession:(NSURLSession *)session task: (NSURLSessionTask *)task didCompleteWithError:(NSError *)error
    {
        
        NSLog(@" function == %s, line == %d, error ==  %@",__FUNCTION__,__LINE__,error);
        
    }
#pragma mark - 下载成功 获取下载内容
    -(void)URLSession:(NSURLSession *)session   downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location{
        
        //1.获取Documents文件夹路径 （不要将视频、音频等较大资源存储在Caches路径下）
        
        NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) lastObject];
        NSFileManager *manager = [NSFileManager defaultManager];
        NSString *appendPath = [NSString stringWithFormat:@"/new.mp4"];
        NSString *file = [documentsPath stringByAppendingString:appendPath];
        //删除之前相同路径的文件
        [manager removeItemAtPath:file error:nil];
         NSLog(@"----1-----%f",CFAbsoluteTimeGetCurrent() - startTime);
        //将视频资源从原有路径移动到自己指定的路径
        BOOL success = [manager copyItemAtPath:location.path toPath:file error:nil];
        if (success) {
             NSLog(@"----2-----%f",CFAbsoluteTimeGetCurrent() - startTime);
        }
    }
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (alertView.cancelButtonIndex!= buttonIndex) {
        [self loginFromWeibo];
    }
}
-(BOOL)isLogin{
   NSUserDefaults *user  = [NSUserDefaults standardUserDefaults];
    NSString *tokenStr  = [user stringForKey:@"RBAccessToken"];
    NSString *userStr  = [user stringForKey:@"RBuserID"];
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
