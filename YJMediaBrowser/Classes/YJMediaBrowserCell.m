//
//  YJMediaBrowserCell.m
//  timingapp
//
//  Created by YZ X on 2020/12/16.
//  Copyright © 2020 huiian. All rights reserved.
//

#import "YJMediaBrowserCell.h"
#import "YJMediaBrowserBottomControlView.h"
#import "YJMediaBrowserVideoPlayView.h"
#import "YJMediaDownLoadManager.h"
#import "Masonry.h"
#import "UIView+YJSnapshot.h"
#import "UIImageView+WebCache.h"
#import <SDWebImageFLPlugin/SDWebImageFLPlugin.h>
#import "UIImage+YJBundleImage.h"


#define BOTTOM_CONTROL_VIEW_AFTER_DELAY_TIME 2.0  // bottomControlView 延时隐藏时长


@interface YJMediaBrowserCell () <
YJMediaBrowserBottomControlViewDelegate,
YJMediaBrowserVideoPlayViewDelegate,
UIScrollViewDelegate
>

@property (nonatomic, strong) UIScrollView *containerScrollView;  //
@property (nonatomic, strong) YJMediaBrowserVideoPlayView *videoView;  //
@property (nonatomic, strong) UIImageView *imageView;  // 视频 cell 时也充当封面
@property (nonatomic, strong) FLAnimatedImageView *gifView;  // 动图容器

@property (nonatomic, strong) UIButton *playButton;  // 播放按钮（视频 cell 才有）
@property (nonatomic, strong) UIButton *closeButton;  // 关闭按钮（视频 cell 才有）
@property (nonatomic, strong) YJMediaBrowserBottomControlView *bottomControlView;  // 底部控件（视频 cell 才有）

@property (nonatomic, assign) CGPoint panStartMediaViewCenter;  // 放大模式 Pan 手势开始时 view 的中心点

@end


@implementation YJMediaBrowserCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.contentView.backgroundColor = UIColor.clearColor;
        self.contentView.clipsToBounds = YES;
        
        // 添加点击事件
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapEvent:)]];
        
        [self initUI];
    }
    return self;
}

- (void)initUI {
    [self.contentView addSubview:self.containerScrollView];
    [self.contentView addSubview:self.playButton];
    [self.contentView addSubview:self.closeButton];
    [self.contentView addSubview:self.bottomControlView];
    
    [self.playButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.width.height.equalTo(@60);
    }];
    
    [self.closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView.mas_top).offset(41);
        make.leading.equalTo(self.contentView.mas_leading).offset(17);
        make.width.height.equalTo(@32);
    }];
    
    [self.bottomControlView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.bottom.equalTo(self);
        make.height.equalTo(@90);
    }];
}

#pragma mark - Public
- (UIImage *)fetchSaveImage {
//    if (self.mediaModel.isGif) {
//        return self.gifView.image;
//    }
    return self.imageView.image;
}

- (UIImage *)fetchScannedImage {
    // 当图片很长时，扫描整张图会导致内存急增，所以在这里只对当前屏幕进行扫描
    UIImage *image = self.imageView.image;
    if (image.size.width > 4096 || image.size.height > 4096) {
        image = [UIView yj_snapshotWithScreen];
    }
    return image;
}

- (UIView *)fetchDismissView {
    if (self.mediaModel.isGif) {
        return self.gifView;
    }
    self.imageView.hidden = NO;
    return self.imageView;
}

- (CGRect)fetchMediaViewRect {
    UIView *srcView = self.imageView;
    return [srcView.superview convertRect:srcView.frame toView:nil];
}

- (UIView *)fetchMediaView {
    [self.videoView removeFromSuperview];
    [self.imageView removeFromSuperview];
    [self.gifView removeFromSuperview];
    if (self.mediaModel.isGif) {
        return self.gifView;
    }
    if (self.mediaModel.mediaType == YJMediaModelType_Video && self.mediaModel.isPlaying) {
        return self.videoView;
    }
    return self.imageView;
}

- (void)resetMediaView {
    [self.containerScrollView addSubview:self.videoView];
    [self.containerScrollView addSubview:self.imageView];
    [self.containerScrollView addSubview:self.gifView];
    
    if (self.mediaModel.mediaType == YJMediaModelType_Video) {  // 视频
        self.videoView.hidden = NO;
        self.imageView.hidden = self.mediaModel.isPlaying;
        self.gifView.hidden = YES;
        
        self.playButton.hidden = (self.mediaModel.isPlaying && !self.mediaModel.isPausing);
        self.bottomControlView.hidden = NO;
        self.closeButton.hidden = NO;
    } else {  // 图片
        self.videoView.hidden = YES;
        self.imageView.hidden = self.mediaModel.isGif;
        self.gifView.hidden = !self.mediaModel.isGif;
        
        self.playButton.hidden = YES;
        self.bottomControlView.hidden = YES;
        self.closeButton.hidden = YES;
    }
}

- (void)moveMeidaState:(TMediaBrowserViewGestureState)gestureState point:(CGPoint)point {
    switch (gestureState) {
        case TMediaBrowserViewGestureState_Began: {  // 手势开始
            // 如果是视频 cell，则隐藏播放控件
            if (self.mediaModel.mediaType == YJMediaModelType_Video) {
                self.playButton.hidden = YES;
                self.bottomControlView.hidden = YES;
                self.closeButton.hidden = YES;
                // 取消延时隐藏
                [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayHideBottomControlView) object:nil];
            }
            if (self.mediaModel.isEnlargeMode) {
                UIView *currentView = (self.mediaModel.isGif ? self.gifView : self.imageView);
                self.panStartMediaViewCenter = currentView.center;
            }
        }
            break;
        case TMediaBrowserViewGestureState_Changed: {  // 手势改变
            CGRect viewFrame;
            if (self.mediaModel.isEnlargeMode) {
                UIView *currentView = (self.mediaModel.isGif ? self.gifView : self.imageView);
                CGFloat viewWidth = CGRectGetWidth(currentView.frame);
                CGFloat viewHeight = CGRectGetHeight(currentView.frame);
                CGFloat viewCenterX = self.panStartMediaViewCenter.x + point.x;
                CGFloat viewCenterY = self.panStartMediaViewCenter.y + point.y;
                viewFrame = CGRectMake(viewCenterX - viewWidth / 2.0, viewCenterY - viewHeight / 2.0, viewWidth, viewHeight);
            } else {
                CGFloat zoomRatio = (point.y > 0 ? (1 - point.y / CGRectGetHeight(self.contentView.frame)) : 1);
                CGFloat viewWidth = CGRectGetWidth(self.mediaModel.viewRect) * zoomRatio;
                CGFloat viewHeight = CGRectGetHeight(self.mediaModel.viewRect) * zoomRatio;
                CGPoint viewCenter = CGPointMake(self.mediaModel.viewRect.origin.x + self.mediaModel.viewRect.size.width / 2.0, self.mediaModel.viewRect.origin.y + self.mediaModel.viewRect.size.height / 2.0);
                CGFloat viewCenterX = viewCenter.x + point.x;
                CGFloat viewCenterY = viewCenter.y + point.y;
                viewFrame = CGRectMake(viewCenterX - viewWidth / 2.0, viewCenterY - viewHeight / 2.0, viewWidth, viewHeight);
                
                self.videoView.frame = viewFrame;
            }
            self.imageView.frame = viewFrame;
            self.gifView.frame = viewFrame;
        }
            break;
        case TMediaBrowserViewGestureState_Ended: {  // 手势停止
            if (self.mediaModel.isEnlargeMode) {
                // 检查边界
                [self checkMediaViewBoundary];
            } else {
                // 复原view
                [UIView animateWithDuration:0.25 animations:^{
                    self.videoView.frame = self.mediaModel.viewRect;
                    self.imageView.frame = self.mediaModel.viewRect;
                    self.gifView.frame = self.mediaModel.viewRect;
                } completion:^(BOOL finished) {
                    // 如果是视频 cell，则显示播放控件
                    if (self.mediaModel.mediaType == YJMediaModelType_Video) {
                        self.playButton.hidden = (self.mediaModel.isPlaying && !self.mediaModel.isPausing);
                        self.bottomControlView.hidden = NO;
                        self.closeButton.hidden = NO;
                        [self performSelector:@selector(delayHideBottomControlView) withObject:nil afterDelay:BOTTOM_CONTROL_VIEW_AFTER_DELAY_TIME];
                    }
                }];
            }
        }
            break;
        default:
            break;
    }
}

// 缩放状态
- (void)scaleMeidaState:(TMediaBrowserViewGestureState)gestureState scale:(CGFloat)scale pinchPoint:(CGPoint)pinchPoint {
    if (self.mediaModel.mediaType != YJMediaModelType_Image) {
        return;
    }
    
    scale = MIN(scale, self.mediaModel.maxEnlargeMultiple);
    switch (gestureState) {
        case TMediaBrowserViewGestureState_Began: {  // 手势开始
            
        }
            break;
        case TMediaBrowserViewGestureState_Changed: {  // 手势改变
            [self updateImageViewRectScale:scale pinchPoint:pinchPoint];
        }
            break;
        case TMediaBrowserViewGestureState_Ended: {  // 手势停止
            // 如果结束时，view尺寸比原始尺寸小，则复原
            UIView *currentView = (self.mediaModel.isGif ? self.gifView : self.imageView);
            if (CGRectGetWidth(currentView.frame) < CGRectGetWidth(self.mediaModel.viewRect) || CGRectGetHeight(currentView.frame) < CGRectGetHeight(self.mediaModel.viewRect)) {
                self.mediaModel.isEnlargeMode = NO;
                
                // 复原view
                [UIView animateWithDuration:0.25 animations:^{
                    self.imageView.frame = self.mediaModel.viewRect;
                    self.gifView.frame = self.mediaModel.viewRect;
                }];
            } else {
                self.mediaModel.isEnlargeMode = YES;
                
                // 检查边界
                [self checkMediaViewBoundary];
            }
        }
            break;
        default:
            break;
    }
}

- (void)resetMediaViewRect {
    [UIView animateWithDuration:0.25 animations:^{
        self.videoView.frame = self.mediaModel.viewRect;
        self.imageView.frame = self.mediaModel.viewRect;
        self.gifView.frame = self.mediaModel.viewRect;
        
        self.containerScrollView.contentSize = CGSizeMake(MAX(self.containerScrollView.frame.size.width, self.mediaModel.viewRect.size.width), MAX(self.containerScrollView.frame.size.height, self.mediaModel.viewRect.size.height));
        self.containerScrollView.contentOffset = CGPointZero;
    }];
}

// 隐藏视频控制控件
- (void)videoControlViewHidden {
    // 取消延时隐藏
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayHideBottomControlView) object:nil];
    
    self.bottomControlView.hidden = YES;
    self.closeButton.hidden = YES;
}

#pragma mark - Setter
- (void)setMediaModel:(YJMediaModel *)mediaModel {
    // contentView 的大小可能和 self 不一致
    self.contentView.frame = self.bounds;
    self.containerScrollView.frame = self.contentView.bounds;
    self.containerScrollView.contentSize = CGSizeMake(MAX(self.containerScrollView.frame.size.width, mediaModel.viewRect.size.width), MAX(self.containerScrollView.frame.size.height, mediaModel.viewRect.size.height));
    self.containerScrollView.contentOffset = CGPointZero;
    
    _mediaModel = mediaModel;
    self.mediaModel.isEnlargeMode = NO;
    
    self.videoView.mediaModel = mediaModel;
    
    self.videoView.frame = mediaModel.viewRect;
    self.imageView.frame = mediaModel.viewRect;
    self.gifView.frame = mediaModel.viewRect;
    
    if (mediaModel.mediaType == YJMediaModelType_Video) {  // 视频
        self.videoView.hidden = NO;
        self.imageView.hidden = mediaModel.isPlaying;
        self.playButton.hidden = (mediaModel.isPlaying && !mediaModel.isPausing) || mediaModel.isAutoPlay;
        self.bottomControlView.hidden = YES;
        self.closeButton.hidden = YES;
        self.gifView.hidden = YES;
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:mediaModel.coverPath]) {
            self.imageView.image = [UIImage imageWithContentsOfFile:mediaModel.coverPath];
        } else {
            [self.imageView sd_setImageWithURL:[NSURL URLWithString:mediaModel.coverUrl] placeholderImage:nil];
        }
        if ([[NSFileManager defaultManager] fileExistsAtPath:mediaModel.videoPath]) {
            self.videoView.videoUrl = mediaModel.videoPath;
        } else {
            self.videoView.videoUrl = mediaModel.videoUrl;
            
            // 如果视频在本地不存在，则下载
            [YJMediaDownLoadManager.sharedInstance startDownloadWithUrl:mediaModel.videoUrl toPath:mediaModel.videoPath];
        }
        
        self.bottomControlView.progressTime = mediaModel.progress * mediaModel.videoDuration;
        self.bottomControlView.totalTime = mediaModel.videoDuration;
        self.bottomControlView.isHorizontal = mediaModel.isHorizontal;
        self.bottomControlView.isPlaying = (mediaModel.isPlaying && !mediaModel.isPausing);
        
        if (mediaModel.isHorizontal) {
            [self.closeButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.contentView.mas_top).offset(20);
                make.leading.equalTo(self.contentView.mas_leading).offset(20);
                make.width.height.equalTo(@32);
            }];
        } else {
            [self.closeButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.contentView.mas_top).offset(41);
                make.leading.equalTo(self.contentView.mas_leading).offset(17);
                make.width.height.equalTo(@32);
            }];
        }
        
        if (mediaModel.isAutoPlay) {
            [self.videoView videoPlay];
            
            // 重置自动播放状态
            mediaModel.isAutoPlay = NO;
        }
    } else {  // 图片
        self.videoView.hidden = YES;
        self.playButton.hidden = YES;
        self.bottomControlView.hidden = YES;
        self.closeButton.hidden = YES;
        
        if (mediaModel.isGif) {
            self.imageView.hidden = YES;
            self.gifView.hidden = NO;
            
            NSData *imageData;
            if ([[NSFileManager defaultManager] fileExistsAtPath:mediaModel.imagePath]) {
                imageData = [NSData dataWithContentsOfFile:mediaModel.imagePath];
            } else {
                imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:mediaModel.imageUrl]];
            }
            self.gifView.animatedImage = [FLAnimatedImage animatedImageWithGIFData:imageData];
        } else {
            self.imageView.hidden = NO;
            self.gifView.hidden = YES;
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:mediaModel.imagePath]) {
                self.imageView.image = [UIImage imageWithContentsOfFile:mediaModel.imagePath];
            } else {
                UIImage *thumbnailImage = mediaModel.thumbnailImage;
                if (!thumbnailImage) {
                    thumbnailImage = [UIImage imageWithContentsOfFile:mediaModel.thumbnailPath];
                }
                
                CGFloat mediaProportion = mediaModel.mediaWidth / mediaModel.mediaHeight;
                if (mediaProportion < LONG_IMAGE_PROPORTION) {  // 超长图
                    // 因为超长图在原图还没加载出来之前，只显示顶部的一屏图片，如果这时候滑动到下面，图片会显示异常，所以先禁掉滑动效果
                    self.containerScrollView.scrollEnabled = NO;
                    // 超长图显示顶部
                    self.imageView.layer.contentsRect = CGRectMake(0, 0, 1, self.imageView.bounds.size.height / self.imageView.bounds.size.width * thumbnailImage.size.width / thumbnailImage.size.height);
                } else {
                    self.imageView.layer.contentsRect = CGRectMake(0, 0, 1, 1);
                }
                
                __weak __typeof(self) weakSelf = self;
                [self.imageView sd_setImageWithURL:[NSURL URLWithString:mediaModel.imageUrl] placeholderImage:thumbnailImage completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                    __strong __typeof(weakSelf) strongSelf = weakSelf;
                    strongSelf.imageView.layer.contentsRect = CGRectMake(0, 0, 1, 1);
                    self.containerScrollView.scrollEnabled = YES;
                }];
            }
        }
    }
}

#pragma mark - Event
- (void)tapEvent:(UITapGestureRecognizer *)tap {
    if (self.mediaModel.mediaType == YJMediaModelType_Video) {  // 视频时，tap事件不回调
        if (self.bottomControlView.isHidden) {  // 是隐藏状态，则显示
            self.bottomControlView.hidden = NO;
            self.closeButton.hidden = NO;
            
            // 如果当前 不是暂停 状态，则延迟 2s 自动隐藏
            if (!self.mediaModel.isPausing) {
                [self performSelector:@selector(delayHideBottomControlView) withObject:nil afterDelay:BOTTOM_CONTROL_VIEW_AFTER_DELAY_TIME];
            }
        } else {
            self.bottomControlView.hidden = YES;
            self.closeButton.hidden = YES;
            
            // 取消延时隐藏
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayHideBottomControlView) object:nil];
        }
        return;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(mediaBrowserCellDismissed)]) {
        [self.delegate mediaBrowserCellDismissed];
    }
}

- (void)playButtonClicked {
    [self.videoView videoPlay];
    
    if (!self.bottomControlView.isHidden) {  // 是显示状态，则延迟隐藏
        [self performSelector:@selector(delayHideBottomControlView) withObject:nil afterDelay:BOTTOM_CONTROL_VIEW_AFTER_DELAY_TIME];
    }
}

- (void)closeButtonClicked {
    if (self.mediaModel.isPlaying) {
        [self.videoView videoStop];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(mediaBrowserCellDismissed)]) {
        [self.delegate mediaBrowserCellDismissed];
    }
}

- (void)delayHideBottomControlView {
    self.bottomControlView.hidden = YES;
    self.closeButton.hidden = YES;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat colorAlpha = (scrollView.contentOffset.y > 0 ? 1 : (1 - fabs(scrollView.contentOffset.y) / CGRectGetHeight(self.contentView.frame)));
    if (self.delegate && [self.delegate respondsToSelector:@selector(mediaBrowserCellMaskViewColorAlphaChanged:)]) {
        [self.delegate mediaBrowserCellMaskViewColorAlphaChanged:colorAlpha];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (scrollView.contentOffset.y < -(CGRectGetHeight(self.contentView.frame) / 6.0)) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(mediaBrowserCellDismissed)]) {
            [self.delegate mediaBrowserCellDismissed];
        }
    }
}

#pragma mark - YJMediaBrowserBottomControlViewDelegate
// 进度改变
- (void)mediaBrowserBottomControlViewProgressChange:(YJMediaBrowserBottomControlViewGestureState)gestureState progress:(CGFloat)progress {
    switch (gestureState) {
        case YJMediaBrowserBottomControlViewGestureState_Began: {  // 手势开始
            // 取消延时隐藏
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayHideBottomControlView) object:nil];
        }
            break;
        case YJMediaBrowserBottomControlViewGestureState_Changing: {  // 手势改变
            
        }
            break;
        case YJMediaBrowserBottomControlViewGestureState_Ended: {  // 手势结束
            [self.videoView videoSeekToTime:progress * self.mediaModel.videoDuration];
            
            // 一定是显示状态，需要延迟隐藏
            [self performSelector:@selector(delayHideBottomControlView) withObject:nil afterDelay:BOTTOM_CONTROL_VIEW_AFTER_DELAY_TIME];
        }
            break;
        default:
            break;
    }
}

// 播放按钮
- (void)mediaBrowserBottomControlViewPlayButtonClicked {
    if (self.mediaModel.isPlaying) {
        if (self.mediaModel.isPausing) {
            [self.videoView videoResume];
            self.playButton.hidden = YES;
            
            // 一定是显示状态，需要延迟隐藏
            [self performSelector:@selector(delayHideBottomControlView) withObject:nil afterDelay:BOTTOM_CONTROL_VIEW_AFTER_DELAY_TIME];
        } else {
            // 取消延时隐藏
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayHideBottomControlView) object:nil];
            
            [self.videoView videoPause];
            self.playButton.hidden = NO;
        }
    } else {
        [self.videoView videoPlay];
        self.playButton.hidden = YES;
        
        // 一定是显示状态，需要延迟隐藏
        [self performSelector:@selector(delayHideBottomControlView) withObject:nil afterDelay:BOTTOM_CONTROL_VIEW_AFTER_DELAY_TIME];
    }
}

#pragma mark - YJMediaBrowserVideoPlayViewDelegate
// 播放器事件
- (void)mediaBrowserVideoPlayViewPlayState:(YJMediaBrowserVideoPlayState)playState {
    switch (playState) {
        case YJMediaBrowserVideoPlayState_FirstIFrame: {  // 第一帧
            // 隐藏封面
            self.imageView.hidden = YES;
        }
            break;
        case YJMediaBrowserVideoPlayState_Play: {  // 开始播放
            self.playButton.hidden = YES;
            
            self.bottomControlView.isPlaying = YES;
        }
            break;
        case YJMediaBrowserVideoPlayState_Pause: {  // 播放暂停
            self.playButton.hidden = NO;
            
            self.bottomControlView.isPlaying = NO;
        }
            break;
        case YJMediaBrowserVideoPlayState_End: {  // 播放结束
            // 显示封面
            self.imageView.hidden = NO;
            self.playButton.hidden = NO;
            
            self.bottomControlView.isPlaying = NO;
            self.bottomControlView.progressTime = 0;
        }
            break;
        case YJMediaBrowserVideoPlayState_SeekEnd: {  // seek完成
            
        }
            break;
        default:
            break;
    }
}

// 播放进度
- (void)mediaBrowserVideoPlayViewProgress:(CGFloat)progress {
    self.bottomControlView.progressTime = progress * self.mediaModel.videoDuration;
}

#pragma mark - 播放器事件
- (void)videoPlay {
    [self.videoView videoPlay];
}

- (void)videoPause {
    [self.videoView videoPause];
}

- (void)videoResume {
    [self.videoView videoResume];
}

- (void)videoStop {
    if (self.mediaModel.isPlaying) {
        [self.videoView videoStop];
    }
}

#pragma mark - Private
- (void)updateImageViewRectScale:(CGFloat)scale pinchPoint:(CGPoint)pinchPoint {
    UIView *currentView = (self.mediaModel.isGif ? self.gifView : self.imageView);
    
    CGFloat maxViewW = CGRectGetWidth(self.mediaModel.viewRect) * self.mediaModel.maxEnlargeMultiple;
    CGFloat maxViewH = CGRectGetHeight(self.mediaModel.viewRect) * self.mediaModel.maxEnlargeMultiple;
    
    CGFloat viewWidth = MIN(CGRectGetWidth(currentView.frame) * scale, maxViewW);
    CGFloat viewHeight = MIN(CGRectGetHeight(currentView.frame) * scale, maxViewH);
    
    CGFloat scrollViewW = CGRectGetWidth(self.containerScrollView.frame);
    CGFloat scrollViewH = CGRectGetHeight(self.containerScrollView.frame);
    
    CGFloat scrollViewContentSizeW = MAX(viewWidth, scrollViewW);
    CGFloat scrollViewContentSizeH = MAX(viewHeight, scrollViewH);
    
    CGRect viewRect = CGRectMake((scrollViewContentSizeW - viewWidth) / 2.0, (scrollViewContentSizeH - viewHeight) / 2.0, viewWidth, viewHeight);
    
    self.imageView.frame = viewRect;
    self.gifView.frame = viewRect;
    self.containerScrollView.contentSize = CGSizeMake(scrollViewContentSizeW, scrollViewContentSizeH);
    
    CGPoint lastOffset = self.containerScrollView.contentOffset;
    CGFloat contentOffsetX = lastOffset.x;
    CGFloat contentOffsetY = lastOffset.y;
    if (scrollViewContentSizeW > scrollViewW && viewWidth < maxViewW) {
        contentOffsetX = (lastOffset.x + pinchPoint.x) * scale - pinchPoint.x;
    }
    if (scrollViewContentSizeH > scrollViewH && viewHeight < maxViewH) {
        contentOffsetY = (lastOffset.y + pinchPoint.y) * scale - pinchPoint.y;
    }
    self.containerScrollView.contentOffset = CGPointMake(contentOffsetX, contentOffsetY);
}

// 检查 view 的边界
- (void)checkMediaViewBoundary {
    UIView *currentView = (self.mediaModel.isGif ? self.gifView : self.imageView);
    CGFloat viewWidth = CGRectGetWidth(currentView.frame);
    CGFloat viewHeight = CGRectGetHeight(currentView.frame);
    CGFloat viewX = CGRectGetMinX(currentView.frame);
    CGFloat viewY = CGRectGetMinY(currentView.frame);
    if (viewWidth > CGRectGetWidth(self.frame)) {
        viewX = MAX(CGRectGetWidth(self.frame) - viewWidth, MIN(0, viewX));
    } else {
        viewX = (CGRectGetWidth(self.frame) - viewWidth) / 2.0;
    }
    if (viewHeight > CGRectGetHeight(self.frame)) {
        viewY = MAX(CGRectGetHeight(self.frame) - viewHeight, MIN(0, viewY));
    } else {
        viewY = (CGRectGetHeight(self.frame) - viewHeight) / 2.0;
    }
    CGRect viewFrame = CGRectMake(viewX, viewY, viewWidth, viewHeight);
    [UIView animateWithDuration:0.25 animations:^{
        self.imageView.frame = viewFrame;
        self.gifView.frame = viewFrame;
    }];
}

#pragma mark - Lazy
- (UIScrollView *)containerScrollView {
    if (!_containerScrollView) {
        _containerScrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        _containerScrollView.showsHorizontalScrollIndicator = NO;
        _containerScrollView.showsVerticalScrollIndicator = NO;
        _containerScrollView.delegate = self;
        if (@available(iOS 11.0, *)) {
            _containerScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        
        [_containerScrollView addSubview:self.videoView];
        [_containerScrollView addSubview:self.imageView];
        [_containerScrollView addSubview:self.gifView];
    }
    return _containerScrollView;
}

- (YJMediaBrowserVideoPlayView *)videoView {
    if (!_videoView) {
        _videoView = [[YJMediaBrowserVideoPlayView alloc] initWithFrame:self.bounds];
        _videoView.delegate = self;
        
        _videoView.hidden = YES;
    }
    return _videoView;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _imageView.userInteractionEnabled = YES;
        _imageView.clipsToBounds = YES;
        _imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _imageView;
}

- (FLAnimatedImageView *)gifView {
    if (!_gifView) {
        _gifView = [[FLAnimatedImageView alloc] initWithFrame:self.bounds];
        _gifView.userInteractionEnabled = YES;
        _gifView.clipsToBounds = YES;
        _gifView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _gifView.contentMode = UIViewContentModeScaleAspectFill;
        
        _gifView.hidden = YES;
    }
    return _gifView;
}

- (UIButton *)playButton {
    if (!_playButton) {
        _playButton = [UIButton new];
        [_playButton addTarget:self action:@selector(playButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        [_playButton setImage:[UIImage yj_bundleImageNamed:@"media_browser_play_big"] forState:UIControlStateNormal];
        
        _playButton.hidden = YES;
    }
    return _playButton;
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton addTarget:self action:@selector(closeButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        [_closeButton setImage:[UIImage yj_bundleImageNamed:@"media_browser_close"] forState:UIControlStateNormal];
        
        _closeButton.hidden = YES;
    }
    return _closeButton;
}

- (YJMediaBrowserBottomControlView *)bottomControlView {
    if (!_bottomControlView) {
        _bottomControlView = [YJMediaBrowserBottomControlView new];
        _bottomControlView.delegate = self;
        
        _bottomControlView.hidden = YES;
    }
    return _bottomControlView;
}

@end
