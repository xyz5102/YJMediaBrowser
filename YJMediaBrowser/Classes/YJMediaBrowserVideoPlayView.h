//
//  YJMediaBrowserVideoPlayView.h
//  timingapp
//
//  Created by YZ X on 2020/12/17.
//  Copyright © 2020 huiian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YJMediaModel.h"


typedef NS_ENUM (NSInteger, YJMediaBrowserVideoPlayViewMode) {
    YJMediaBrowserVideoPlayViewMode_FillScreen  = 0,  // 图像铺满屏幕，不留黑边
    YJMediaBrowserVideoPlayViewMode_FillEdge    = 1,  // 图像适应屏幕，保持画面完整，会有黑边的存在
};

typedef NS_ENUM (NSInteger, YJMediaBrowserVideoPlayState) {
    YJMediaBrowserVideoPlayState_FirstIFrame   = 1,  // 第一帧
    YJMediaBrowserVideoPlayState_Play          = 2,  // 开始播放
    YJMediaBrowserVideoPlayState_Pause         = 3,  // 播放暂停
    YJMediaBrowserVideoPlayState_End           = 4,  // 播放结束
    YJMediaBrowserVideoPlayState_SeekEnd       = 5,  // seek完成
    YJMediaBrowserVideoPlayState_Failed        = 6,  // 播放失败
};


NS_ASSUME_NONNULL_BEGIN

@protocol YJMediaBrowserVideoPlayViewDelegate <NSObject>

// 播放器事件
- (void)mediaBrowserVideoPlayViewPlayState:(YJMediaBrowserVideoPlayState)playState;

// 播放进度（progress为百分比）
- (void)mediaBrowserVideoPlayViewProgress:(CGFloat)progress;

@end


@interface YJMediaBrowserVideoPlayView : UIView

@property (nonatomic, weak) id<YJMediaBrowserVideoPlayViewDelegate> delegate;
@property (nonatomic, strong) YJMediaModel *mediaModel;  // 用于更新播放状态

@property (nonatomic, assign) YJMediaBrowserVideoPlayViewMode renderMode;  // 设置画面的裁剪模式
@property (nonatomic, copy) NSString *videoUrl;  //

- (instancetype)initWithFrame:(CGRect)frame;

- (void)videoPlay;  // 播放
- (void)videoStop;  // 停止
- (void)videoPause;  // 暂停
- (void)videoResume;  // 恢复
- (void)videoMute:(BOOL)isMute;  // 静音
- (void)videoSeekToTime:(CGFloat)time;  // 跳到某一帧

@end

NS_ASSUME_NONNULL_END
