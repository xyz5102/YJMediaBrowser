//
//  YJMediaBrowserCell.h
//  timingapp
//
//  Created by YZ X on 2020/12/16.
//  Copyright © 2020 huiian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YJMediaModel.h"

@class YJMediaBrowserCell;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, TMediaBrowserViewGestureState) {
    TMediaBrowserViewGestureState_Began,    // 手势开始
    TMediaBrowserViewGestureState_Changed,  // 手势改变
    TMediaBrowserViewGestureState_Ended,    // 手势结束
};


@protocol YJMediaBrowserCellDelegate <NSObject>

@optional
- (void)mediaBrowserCellDismissed;  // 媒体浏览器 dismiss
- (void)mediaBrowserCellMaskViewColorAlphaChanged:(CGFloat)colorAlpha;  // 改变遮罩透明度

@end


@interface YJMediaBrowserCell : UICollectionViewCell

@property (nonatomic, weak) id<YJMediaBrowserCellDelegate> delegate;

@property (nonatomic, strong) YJMediaModel *mediaModel;  //

- (UIImage *)fetchSaveImage;  // 获取需要保存的图片
- (UIImage *)fetchScannedImage;  // 获取扫描二维码的图片

- (UIView *)fetchDismissView;  // 获取 view（用来做缩小动画）
- (CGRect)fetchMediaViewRect;  // 获取 view 坐标（用来做缩小动画）

- (UIView *)fetchMediaView;  // 获取 view（用来做旋转屏幕时的动画）
- (void)resetMediaView;  // 恢复 view（用来做旋转屏幕时的动画）

// 拖动状态，拖动中时，会传 point
- (void)moveMeidaState:(TMediaBrowserViewGestureState)gestureState point:(CGPoint)point;
// 缩放状态
- (void)scaleMeidaState:(TMediaBrowserViewGestureState)gestureState scale:(CGFloat)scale pinchPoint:(CGPoint)pinchPoint;

- (void)resetMediaViewRect;  // 恢复子控件 rect

- (void)videoPlay;  // 视频播放
- (void)videoPause;  // 视频暂停播放
- (void)videoResume;  // 视频恢复播放
- (void)videoStop;  // 视频停止播放

- (void)videoControlViewHidden;  // 隐藏视频控制控件

@end

NS_ASSUME_NONNULL_END
