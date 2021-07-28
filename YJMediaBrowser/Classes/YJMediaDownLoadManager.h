//
//  YJMediaDownLoadManager.h
//  timingapp
//
//  Created by YZ X on 2020/12/18.
//  Copyright © 2020 huiian. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YJMediaDownLoadManager : NSObject

+ (instancetype)sharedInstance;

- (void)startDownloadWithUrl:(NSString *)url toPath:(NSString *)toPath;

@end

NS_ASSUME_NONNULL_END
