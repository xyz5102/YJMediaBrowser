//
//  YJAliPlayerManager.h
//  MediaBrowserDemo
//
//  Created by YZ X on 2021/3/30.
//

#import <Foundation/Foundation.h>
#import <AliyunPlayer/AliyunPlayer.h>


typedef NS_ENUM (NSInteger, YJMediaBrowserPlayerMode) {
    YJMediaBrowserPlayerMode_FillScreen  = 0,  // 图像铺满屏幕，不留黑边
    YJMediaBrowserPlayerMode_FillEdge    = 1,  // 图像适应屏幕，保持画面完整，会有黑边的存在
};

typedef NS_ENUM (NSInteger, YJMediaBrowserPlayerState) {
    YJMediaBrowserPlayerState_FirstIFrame   = 1,  // 第一帧
    YJMediaBrowserPlayerState_Play          = 2,  // 开始播放
    YJMediaBrowserPlayerState_Pause         = 3,  // 播放暂停
    YJMediaBrowserPlayerState_End           = 4,  // 播放结束
    YJMediaBrowserPlayerState_CacheStart    = 5,  // 缓冲开始
    YJMediaBrowserPlayerState_CacheFinish   = 6,  // 缓冲完成
    YJMediaBrowserPlayerState_SeekEnd       = 7,  // seek完成
    YJMediaBrowserPlayerState_Failed        = 8,  // 播放失败
};


NS_ASSUME_NONNULL_BEGIN

@protocol YJAliPlayerManagerDelegate <NSObject>

@optional
// 播放器事件
- (void)aliPlayerManagerPlayState:(YJMediaBrowserPlayerState)playState;

// 播放进度（progress为百分比）
- (void)aliPlayerManagerProgress:(CGFloat)progress;

@end


@interface YJAliPlayerManager : NSObject

@property (nonatomic, weak) id<YJAliPlayerManagerDelegate> delegate;  //
@property (nonatomic, assign) YJMediaBrowserPlayerMode renderMode;  // 设置画面的裁剪模式
@property (nonatomic, assign, readonly) BOOL isPlaying;  //

+ (instancetype)sharedInstance;

// 开始
- (void)videoPlay:(NSString *)url previewView:(UIView *)previewView;
// 停止
- (void)videoStop;
// 暂停
- (void)videoPause;
// 恢复
- (void)videoResume;
// 静音
- (void)videoMute:(BOOL)isMute;
// 跳到某一帧
- (void)videoSeekToTime:(CGFloat)time;

@end

NS_ASSUME_NONNULL_END
