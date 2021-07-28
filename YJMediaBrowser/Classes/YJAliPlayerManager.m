//
//  YJAliPlayerManager.m
//  MediaBrowserDemo
//
//  Created by YZ X on 2021/3/30.
//

#import "YJAliPlayerManager.h"

@interface YJAliPlayerManager () <AVPDelegate>

@property (nonatomic, strong) AliPlayer *player;  //
@property (nonatomic, assign) BOOL isPlaying;  //
@property (nonatomic, assign) CGFloat needSeekToTime;  // 需要跳转到时间点

@end


@implementation YJAliPlayerManager

+ (instancetype)sharedInstance {
    static YJAliPlayerManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [YJAliPlayerManager new];
    });
    return instance;
}

#pragma mark - Public
// 播放
- (void)videoPlay:(NSString *)url previewView:(UIView *)previewView {
    AVPUrlSource *source = [[AVPUrlSource alloc] init];
    source.playerUrl = [NSURL URLWithString:url];
    [self.player setUrlSource:source];
    self.player.loop = NO;
    self.player.muted = NO;
    self.player.playerView = previewView;
    
    if (self.needSeekToTime > 0) {
        [self.player seekToTime:self.needSeekToTime * 1000 seekMode:AVP_SEEKMODE_ACCURATE];

        self.needSeekToTime = 0;
    }
    [self.player prepare];
    [self.player start];
    
    self.isPlaying = YES;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(aliPlayerManagerPlayState:)]) {
        [self.delegate aliPlayerManagerPlayState:YJMediaBrowserPlayerState_Play];
    }
}

// 停止
- (void)videoStop {
    [self.player stop];
    self.player.playerView = nil;
    
    self.isPlaying = NO;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(aliPlayerManagerPlayState:)]) {
        [self.delegate aliPlayerManagerPlayState:YJMediaBrowserPlayerState_End];
    }
}

// 暂停
- (void)videoPause {
    [self.player pause];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(aliPlayerManagerPlayState:)]) {
        [self.delegate aliPlayerManagerPlayState:YJMediaBrowserPlayerState_Pause];
    }
}

// 恢复
- (void)videoResume {
    [self.player start];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(aliPlayerManagerPlayState:)]) {
        [self.delegate aliPlayerManagerPlayState:YJMediaBrowserPlayerState_Play];
    }
}

// 静音
- (void)videoMute:(BOOL)isMute; {
    self.player.muted = isMute;
}

// 跳到某一帧
- (void)videoSeekToTime:(CGFloat)time {
    if (self.isPlaying) {
        [self.player seekToTime:time * 1000 seekMode:AVP_SEEKMODE_ACCURATE];
    } else {
        self.needSeekToTime = time;
    }
}

#pragma mark - AVPDelegate
// 错误代理回调
- (void)onError:(AliPlayer *)player errorModel:(AVPErrorModel *)errorModel {
    // 提示错误
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(aliPlayerManagerPlayState:)]) {
            [self.delegate aliPlayerManagerPlayState:YJMediaBrowserPlayerState_Failed];
        }
    });
}

// 播放器事件回调
- (void)onPlayerEvent:(AliPlayer *)player eventType:(AVPEventType)eventType {
    switch (eventType) {
        case AVPEventPrepareDone: {  // 准备完成
            if (self.renderMode == YJMediaBrowserPlayerMode_FillEdge) {
                self.player.scalingMode = AVP_SCALINGMODE_SCALEASPECTFIT;
            } else {
                self.player.scalingMode = AVP_SCALINGMODE_SCALEASPECTFILL;
            }
        }
            break;
        case AVPEventFirstRenderedStart: {  // 首帧显示
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.delegate && [self.delegate respondsToSelector:@selector(aliPlayerManagerPlayState:)]) {
                    [self.delegate aliPlayerManagerPlayState:YJMediaBrowserPlayerState_FirstIFrame];
                }
            });
        }
            break;
        case AVPEventCompletion: {  // 播放完成
            // 这里一定要调 stop，不然停止状态下调 seek 就不起作用了
            [self.player stop];
            self.isPlaying = NO;
            self.player.playerView = nil;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.delegate && [self.delegate respondsToSelector:@selector(aliPlayerManagerPlayState:)]) {
                    [self.delegate aliPlayerManagerPlayState:YJMediaBrowserPlayerState_End];
                }
            });
        }
            break;
        case AVPEventLoadingStart: {  // 缓冲开始
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.delegate && [self.delegate respondsToSelector:@selector(aliPlayerManagerPlayState:)]) {
                    [self.delegate aliPlayerManagerPlayState:YJMediaBrowserPlayerState_CacheStart];
                }
            });
        }
            break;
        case AVPEventLoadingEnd: {  // 缓冲完成
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.delegate && [self.delegate respondsToSelector:@selector(aliPlayerManagerPlayState:)]) {
                    [self.delegate aliPlayerManagerPlayState:YJMediaBrowserPlayerState_CacheFinish];
                }
            });
        }
            break;
        case AVPEventSeekEnd: {  // seek完成
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.delegate && [self.delegate respondsToSelector:@selector(aliPlayerManagerPlayState:)]) {
                    [self.delegate aliPlayerManagerPlayState:YJMediaBrowserPlayerState_SeekEnd];
                }
            });
        }
            break;
        default:
            break;
    }
}

// 视频当前播放位置回调
- (void)onCurrentPositionUpdate:(AliPlayer *)player position:(int64_t)position {
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat progress = (CGFloat)position / player.duration;
        if (self.delegate && [self.delegate respondsToSelector:@selector(aliPlayerManagerProgress:)]) {
            [self.delegate aliPlayerManagerProgress:progress];
        }
    });
}

#pragma mark - Setter
- (void)setRenderMode:(YJMediaBrowserPlayerMode)renderMode {
    _renderMode = renderMode;
    if (renderMode == YJMediaBrowserPlayerMode_FillEdge) {
        self.player.scalingMode = AVP_SCALINGMODE_SCALEASPECTFIT;
    } else {
        self.player.scalingMode = AVP_SCALINGMODE_SCALEASPECTFILL;
    }
}

#pragma mark - Lazy
- (AliPlayer *)player {
    if (!_player) {
        _player = [[AliPlayer alloc] init];
        _player.loop = NO;
        
        AVPCacheConfig *cacheConfig = [[AVPCacheConfig alloc] init];
        cacheConfig.enable = NO;
        [_player setCacheConfig:cacheConfig];

        AVPConfig *config = [self.player getConfig];
        config.networkTimeout = 5000;
        config.networkRetryCount = 3;
        config.maxDelayTime = 5000;
        config.maxBufferDuration = 30000;
        config.highBufferDuration = 3000;
        config.startBufferDuration = 200;
        [_player setConfig:config];
        
        _player.delegate = self;
    }
    return _player;
}

@end
