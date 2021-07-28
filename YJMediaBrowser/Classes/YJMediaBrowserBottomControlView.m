//
//  YJMediaBrowserBottomControlView.m
//  timingapp
//
//  Created by YZ X on 2020/12/17.
//  Copyright © 2020 huiian. All rights reserved.
//

#import "YJMediaBrowserBottomControlView.h"
#import "Masonry.h"
#import "UIImage+YJBundleImage.h"

#define UIColorWithRGBA(r, g, b, a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]

@interface YJMediaBrowserBottomControlView ()

@property (nonatomic, strong) UIImageView *maskImageView;  // 遮罩
@property (nonatomic, strong) UIButton *playButton;  //
@property (nonatomic, strong) UILabel *leftTimeLabel;  //
@property (nonatomic, strong) UISlider *progressSlider;  //
@property (nonatomic, strong) UILabel *rightTimeLabel;  //

@property (nonatomic, assign) BOOL sliderChanging;  //

@end


@implementation YJMediaBrowserBottomControlView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // 添加平移手势（用来拦截父控件的 Pan 手势）
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panEvent:)];
        [self addGestureRecognizer:panGesture];
        
        [self initUI];
    }
    return self;
}

- (void)initUI {
    [self addSubview:self.maskImageView];
    [self addSubview:self.playButton];
    [self addSubview:self.leftTimeLabel];
    [self addSubview:self.rightTimeLabel];
    [self addSubview:self.progressSlider];
    
    [self.maskImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    [self.playButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.mas_leading).offset(14);
        make.top.equalTo(self.mas_top).offset(10);
        make.width.height.equalTo(@24);
    }];
    
    [self.leftTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.playButton.mas_trailing).offset(13);
        make.centerY.equalTo(self.playButton.mas_centerY);
    }];
    
    [self.rightTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.mas_trailing).offset(-14);
        make.centerY.equalTo(self.playButton.mas_centerY);
    }];
    
    [self.progressSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.leftTimeLabel.mas_trailing).offset(8);
        make.trailing.equalTo(self.rightTimeLabel.mas_leading).offset(-8);
        make.centerY.equalTo(self.playButton.mas_centerY);
    }];
}

#pragma mark - Setter
- (void)setTotalTime:(CGFloat)totalTime {
    _totalTime = totalTime;
    
    self.rightTimeLabel.text = [self fetchTimeStr:totalTime];
    if (!self.sliderChanging) {
        self.progressSlider.value = self.progressTime / totalTime;
    }
}

- (void)setProgressTime:(CGFloat)progressTime {
    _progressTime = progressTime;
    
    self.leftTimeLabel.text = [self fetchTimeStr:progressTime];
    if (self.totalTime > 0 && !self.sliderChanging) {
        self.progressSlider.value = self.progressTime / self.totalTime;
    }
}

- (void)setIsPlaying:(BOOL)isPlaying {
    _isPlaying = isPlaying;
    
    self.playButton.selected = isPlaying;
}

- (void)setIsHorizontal:(BOOL)isHorizontal {
    _isHorizontal = isHorizontal;
    
    if (isHorizontal) {
        [self.playButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.mas_leading).offset(25);
            make.top.equalTo(self.mas_top).offset(47);
            make.width.height.equalTo(@24);
        }];
        
        [self.leftTimeLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.playButton.mas_trailing).offset(16);
            make.centerY.equalTo(self.playButton.mas_centerY);
        }];
        
        [self.rightTimeLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(self.mas_trailing).offset(-25);
            make.centerY.equalTo(self.playButton.mas_centerY);
        }];
        
        [self.progressSlider mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.leftTimeLabel.mas_trailing).offset(17);
            make.trailing.equalTo(self.rightTimeLabel.mas_leading).offset(-17);
            make.centerY.equalTo(self.playButton.mas_centerY);
        }];
    } else {
        [self.playButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.mas_leading).offset(14);
            make.top.equalTo(self.mas_top).offset(10);
            make.width.height.equalTo(@24);
        }];
        
        [self.leftTimeLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.playButton.mas_trailing).offset(13);
            make.centerY.equalTo(self.playButton.mas_centerY);
        }];
        
        [self.rightTimeLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(self.mas_trailing).offset(-14);
            make.centerY.equalTo(self.playButton.mas_centerY);
        }];
        
        [self.progressSlider mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.leftTimeLabel.mas_trailing).offset(8);
            make.trailing.equalTo(self.rightTimeLabel.mas_leading).offset(-8);
            make.centerY.equalTo(self.playButton.mas_centerY);
        }];
    }
}

#pragma mark - Event
- (void)panEvent:(UIPanGestureRecognizer *)pan {
    
}

- (void)playButtonClicked {
    if (self.delegate && [self.delegate respondsToSelector:@selector(mediaBrowserBottomControlViewPlayButtonClicked)]) {
        [self.delegate mediaBrowserBottomControlViewPlayButtonClicked];
    }
}

- (void)progressSliderValurChanged:(UISlider *)slider forEvent:(UIEvent *)event {
    CGFloat currentTime = slider.value * self.totalTime;
    self.leftTimeLabel.text = [self fetchTimeStr:currentTime];
    
    UITouch *touchEvent = [[event allTouches] anyObject];
    switch(touchEvent.phase) {
        case UITouchPhaseBegan: {
            self.sliderChanging = YES;
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(mediaBrowserBottomControlViewProgressChange:progress:)]) {
                [self.delegate mediaBrowserBottomControlViewProgressChange:YJMediaBrowserBottomControlViewGestureState_Began progress:slider.value];
            }
        }
            break;
        case UITouchPhaseMoved: {
            if (self.delegate && [self.delegate respondsToSelector:@selector(mediaBrowserBottomControlViewProgressChange:progress:)]) {
                [self.delegate mediaBrowserBottomControlViewProgressChange:YJMediaBrowserBottomControlViewGestureState_Changing progress:slider.value];
            }
        }
            break;
        case UITouchPhaseEnded: {
            self.sliderChanging = NO;
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(mediaBrowserBottomControlViewProgressChange:progress:)]) {
                [self.delegate mediaBrowserBottomControlViewProgressChange:YJMediaBrowserBottomControlViewGestureState_Ended progress:slider.value];
            }
        }
            break;
        default:
            break;
    }
}

#pragma mark - Private
- (NSString *)fetchTimeStr:(CGFloat)time {
    int intTime = (int)time;
    NSString *mStr = [NSString stringWithFormat:@"%02d", (intTime % 3600) / 60];
    NSString *sStr = [NSString stringWithFormat:@"%02d", intTime % 60];
    if (intTime >= 3600) {
        NSString *hStr = [NSString stringWithFormat:@"%d", intTime / 3600];
        return [NSString stringWithFormat:@"%@:%@:%@", hStr, mStr, sStr];
    }
    return [NSString stringWithFormat:@"%@:%@", mStr, sStr];
}

#pragma mark - Lazy
- (UIImageView *)maskImageView {
    if (!_maskImageView) {
        _maskImageView = [UIImageView new];
        _maskImageView.contentMode = UIViewContentModeScaleToFill;
        _maskImageView.image = [UIImage yj_bundleImageNamed:@"media_browser_video_control_mask"];
    }
    return _maskImageView;
}

- (UIButton *)playButton {
    if (!_playButton) {
        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playButton addTarget:self action:@selector(playButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        [_playButton setImage:[UIImage yj_bundleImageNamed:@"media_browser_play_small"] forState:UIControlStateNormal];
        [_playButton setImage:[UIImage yj_bundleImageNamed:@"media_browser_pause_small"] forState:UIControlStateSelected];
    }
    return _playButton;
}

- (UILabel *)leftTimeLabel {
    if (!_leftTimeLabel) {
        _leftTimeLabel = [[UILabel alloc] init];
        _leftTimeLabel.textColor = UIColorWithRGBA(249, 249, 249, 1);
        _leftTimeLabel.font = [UIFont systemFontOfSize:12];
        _leftTimeLabel.textAlignment = NSTextAlignmentLeft;
        _leftTimeLabel.text = @"00:00";
    }
    return _leftTimeLabel;
}

- (UISlider *)progressSlider {
    if (!_progressSlider) {
        _progressSlider = [[UISlider alloc] init];
        _progressSlider.value = 0.0;
        _progressSlider.minimumValue = 0;
        _progressSlider.maximumValue = 1;
        _progressSlider.minimumTrackTintColor = UIColorWithRGBA(80, 148, 243, 1);
        _progressSlider.maximumTrackTintColor = [UIColor.whiteColor colorWithAlphaComponent:0.4];
        [_progressSlider setThumbImage:[UIImage yj_bundleImageNamed:@"media_browser_video_progress_slider"] forState:UIControlStateNormal];
        _progressSlider.continuous = YES;  // 值改变就触发change方法，设置为NO只有停止移动才会触发change方法
        [_progressSlider addTarget:self action:@selector(progressSliderValurChanged:forEvent:) forControlEvents:UIControlEventValueChanged];
    }
    return _progressSlider;
}

- (UILabel *)rightTimeLabel {
    if (!_rightTimeLabel) {
        _rightTimeLabel = [[UILabel alloc] init];
        _rightTimeLabel.textColor = UIColorWithRGBA(249, 249, 249, 1);
        _rightTimeLabel.font = [UIFont systemFontOfSize:12];
        _rightTimeLabel.textAlignment = NSTextAlignmentRight;
        _rightTimeLabel.text = @"00:00";
    }
    return _rightTimeLabel;
}

@end
