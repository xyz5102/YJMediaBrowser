//
//  YJMediaBrowserVC.h
//  timingapp
//
//  Created by YZ X on 2020/12/16.
//  Copyright © 2020 huiian. All rights reserved.
//

/**
 * @功能描述：媒体资源浏览器（图片+视频）
 * @创建人：夏永杰
 * 功能备注：媒体资源浏览器（图片+视频）
 */

#import <UIKit/UIKit.h>
#import "YJMediaModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface YJMediaBrowserVC : UIViewController

@property (nonatomic, copy) void(^mediaBrowserDismissed)(NSInteger currentIdx);  // 媒体浏览器 dismiss 回调
@property (nonatomic, copy) void(^mediaBrowserCellClicked)(NSIndexPath *indexPath);  // cell 点击回调
@property (nonatomic, copy) void(^mediaBrowserQRCodeScanned)(BOOL success, NSString * _Nullable errorMsg, NSString * _Nullable qrCodeUrl, NSInteger currentIdx);  // 二维码扫描回调
@property (nonatomic, copy) void(^mediaBrowserSavePhotoLibrary)(BOOL success, NSString * _Nullable errorMsg);  // 保存到相册回调

// 资源数组
@property (nonatomic, strong) NSArray <YJMediaModel *> *mediaList;
// 初始显示的索引
@property (nonatomic, assign) NSInteger startIdx;
// 出现&消失时视图的圆角
@property (nonatomic, assign) CGFloat viewCornerRadius;

// 当前显示的索引
@property (nonatomic, assign, readonly) NSInteger currentIdx;

- (void)showWithPresentingVC:(UIViewController *)presentingVC;

@end

NS_ASSUME_NONNULL_END
