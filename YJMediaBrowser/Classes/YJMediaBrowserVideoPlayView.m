//
//  YJMediaBrowserVideoPlayView.m
//  timingapp
//
//  Created by YZ X on 2020/12/17.
//  Copyright © 2020 huiian. All rights reserved.
//

#import "YJMediaBrowserVideoPlayView.h"
#import "YJVideoPlayLoadingView.h"
#import "YJAliPlayerManager.h"
#import "Masonry.h"
#import <AVFoundation/AVFoundation.h>


@interface YJMediaBrowserVideoPlayView () <YJAliPlayerManagerDelegate>

@property (nonatomic, strong) UIView *playerView;  //

@property (nonatomic, strong) YJVideoPlayLoadingView *loadingView;  //

@property (nonatomic, assign) CGFloat needSeekToTime;  // 需要跳转到时间点

@end


@implementation YJMediaBrowserVideoPlayView

- (void)dealloc {
    
}

- (instancetype)initWithFrame:(CGRect)frame {
    if ([super initWithFrame:frame]) {
        [self addSubview:self.playerView];
        [self.playerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
        
        [self addSubview:self.loadingView];
        [self.loadingView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
            make.height.width.equalTo(@60);
        }];
    }
    return self;
}

#pragma mark - Public
// 播放
- (void)videoPlay {
    if (self.videoUrl.length == 0) {
        return;
    }

    if (self.mediaModel.isPlaying && self.mediaModel.isPausing) {
        [self videoResume];
        return;
    }

    [self showLoading];
    
    [YJAliPlayerManager sharedInstance].delegate = self;
    [[YJAliPlayerManager sharedInstance] videoPlay:self.videoUrl previewView:self.playerView];
}

// 停止
- (void)videoStop {
    [[YJAliPlayerManager sharedInstance] videoStop];
}

// 暂停
- (void)videoPause {
    [[YJAliPlayerManager sharedInstance] videoPause];
}

// 恢复
- (void)videoResume {
    [[YJAliPlayerManager sharedInstance] videoResume];
}

// 静音
- (void)videoMute:(BOOL)isMute {
    [[YJAliPlayerManager sharedInstance] videoMute:isMute];
}

// 跳到某一帧
- (void)videoSeekToTime:(CGFloat)time {
    if (self.mediaModel.isPlaying) {
        [self showLoading];
    }
    [[YJAliPlayerManager sharedInstance] videoSeekToTime:time];
}

#pragma mark - Setter
- (void)setRenderMode:(YJMediaBrowserVideoPlayViewMode)renderMode {
    _renderMode = renderMode;
    if (renderMode == YJMediaBrowserVideoPlayViewMode_FillEdge) {
        [YJAliPlayerManager sharedInstance].renderMode = YJMediaBrowserPlayerMode_FillEdge;
    } else {
        [YJAliPlayerManager sharedInstance].renderMode = YJMediaBrowserPlayerMode_FillScreen;
    }
}

- (void)seYJMediaModel:(YJMediaModel *)mediaModel {
    _mediaModel = mediaModel;
    
    // 重置，防止 cell 复用导致异常
    self.needSeekToTime = 0;
}

#pragma mark - Private
- (void)showLoading {
    [self performSelector:@selector(loadingShow) withObject:nil afterDelay:1.0];
}

- (void)dismissLoading {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loadingShow) object:nil];
    
    [self.loadingView stopAnimation];
    self.loadingView.hidden = YES;
}

- (void)loadingShow {
    self.loadingView.hidden = NO;
    [self.loadingView startAnimation];
    
    [self bringSubviewToFront:self.loadingView];
}

#pragma mark - YJAliPlayerManagerDelegate
// 播放器事件
- (void)aliPlayerManagerPlayState:(YJMediaBrowserPlayerState)playState {
    switch (playState) {
        case YJMediaBrowserPlayerState_FirstIFrame: {  // 第一帧
            [self dismissLoading];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(mediaBrowserVideoPlayViewPlayState:)]) {
                [self.delegate mediaBrowserVideoPlayViewPlayState:YJMediaBrowserVideoPlayState_FirstIFrame];
            }
        }
            break;
        case YJMediaBrowserPlayerState_Play: {  // 开始播放
            self.mediaModel.isPlaying = YES;
            self.mediaModel.isPausing = NO;
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(mediaBrowserVideoPlayViewPlayState:)]) {
                [self.delegate mediaBrowserVideoPlayViewPlayState:YJMediaBrowserVideoPlayState_Play];
            }
        }
            break;
        case YJMediaBrowserPlayerState_Pause: {  // 播放暂停
            self.mediaModel.isPausing = YES;
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(mediaBrowserVideoPlayViewPlayState:)]) {
                [self.delegate mediaBrowserVideoPlayViewPlayState:YJMediaBrowserVideoPlayState_Pause];
            }
        }
            break;
        case YJMediaBrowserPlayerState_End: {  // 播放结束
            self.mediaModel.isPlaying = NO;
            self.mediaModel.isPausing = NO;
            self.mediaModel.progress = 0;

            if (self.delegate && [self.delegate respondsToSelector:@selector(mediaBrowserVideoPlayViewPlayState:)]) {
                [self.delegate mediaBrowserVideoPlayViewPlayState:YJMediaBrowserVideoPlayState_End];
            }
        }
            break;
        case YJMediaBrowserPlayerState_CacheStart: {  // 缓冲开始
            [self showLoading];
        }
            break;
        case YJMediaBrowserPlayerState_CacheFinish: {  // 缓冲完成
            [self dismissLoading];
        }
            break;
        case YJMediaBrowserPlayerState_SeekEnd: {  // seek完成
            [self dismissLoading];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(mediaBrowserVideoPlayViewPlayState:)]) {
                [self.delegate mediaBrowserVideoPlayViewPlayState:YJMediaBrowserVideoPlayState_SeekEnd];
            }
        }
            break;
        case YJMediaBrowserPlayerState_Failed: {  // 播放失败
            if (self.delegate && [self.delegate respondsToSelector:@selector(mediaBrowserVideoPlayViewPlayState:)]) {
                [self.delegate mediaBrowserVideoPlayViewPlayState:YJMediaBrowserVideoPlayState_Failed];
            }
        }
            break;
        default:
            break;
    }
}

// 播放进度
- (void)aliPlayerManagerProgress:(CGFloat)progress {
    self.mediaModel.progress = progress;
    if (self.delegate && [self.delegate respondsToSelector:@selector(mediaBrowserVideoPlayViewProgress:)]) {
        [self.delegate mediaBrowserVideoPlayViewProgress:progress];
    }
}

#pragma mark - Lazy
- (UIView *)playerView {
    if (!_playerView) {
        _playerView = [[UIView alloc] init];
    }
    return _playerView;
}

- (YJVideoPlayLoadingView *)loadingView {
    if (!_loadingView) {
        _loadingView = [[YJVideoPlayLoadingView alloc] init];
        
        _loadingView.hidden = YES;
    }
    return _loadingView;
}

@end
