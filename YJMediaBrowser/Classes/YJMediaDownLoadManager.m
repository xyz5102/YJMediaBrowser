//
//  YJMediaDownLoadManager.m
//  timingapp
//
//  Created by YZ X on 2020/12/18.
//  Copyright © 2020 huiian. All rights reserved.
//

#import "YJMediaDownLoadManager.h"

@implementation YJMediaDownLoadManager

+ (instancetype)sharedInstance {
    static YJMediaDownLoadManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [YJMediaDownLoadManager new];
    });
    return instance;
}

- (void)startDownloadWithUrl:(NSString *)url toPath:(NSString *)toPath {
    if (!(url.length > 0 && toPath.length > 0)) {
        return;
    }
    
    [[[NSURLSession sharedSession] downloadTaskWithURL:[NSURL URLWithString:url] completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error && location) {
            // 把文件从下载路径移到 toPath
            [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:toPath] error:nil];
        }
    }] resume];
}

@end
