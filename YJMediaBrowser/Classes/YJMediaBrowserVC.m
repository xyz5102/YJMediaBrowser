//
//  YJMediaBrowserVC.m
//  timingapp
//
//  Created by YZ X on 2020/12/16.
//  Copyright © 2020 huiian. All rights reserved.
//

#import "YJMediaBrowserVC.h"
#import "YJMediaBrowserCell.h"
#import "YJBrowserAnimateDelegate.h"
#import <Photos/Photos.h>

#define MARGIN_LEFT_RIGHT 5.0  // 左、右间距
#define DEFAULT_MAX_ENLARGE_MULTIPLE 3.0  // 默认最大放大倍数

@interface YJMediaBrowserVC () <
UICollectionViewDataSource,
UICollectionViewDelegate,
UICollectionViewDelegateFlowLayout,
UIScrollViewDelegate,
YJMediaBrowserCellDelegate,
YJBrowserAnimateDelegateProtocol
>

@property (nonatomic, strong) UIView *contentView;  //
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) YJBrowserAnimateDelegate *browserAnimateDelegate;

// 当前显示的索引
@property (nonatomic, assign) NSInteger currentIndex;

@property (nonatomic, strong) YJMediaBrowserCell *currentCell;  // 当前显示的cell

@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;  // Pan 手势
@property (nonatomic, assign) CGPoint startPanPoint;  // Pan 手势开始时的坐标
@property (nonatomic, assign) BOOL isPanEventBegin;  //

@property (nonatomic, assign) CGPoint pinchPoint;  // Pinch 手势中心点

@property (nonatomic, assign) UIDeviceOrientation currentDeviceOrientation;  // 当前设备方向
@property (nonatomic, assign) BOOL deviceOrientationChanging;  // 是否正在改变方向（改变方向时不响应 scrollViewDidScroll）

@property (nonatomic, assign) CGFloat originalViewWidth;  //
@property (nonatomic, assign) CGFloat originalViewHeight;  //

@property (nonatomic, assign) BOOL needAutoResume;  // 是否需要自动恢复播放

@end


@implementation YJMediaBrowserVC

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // 如果当前cell是视频，则停止播放视频
    YJMediaModel *mediaModel = [self.mediaList objectAtIndex:self.currentIndex];
    if (mediaModel.mediaType == YJMediaModelType_Video && mediaModel.isPlaying) {
        YJMediaBrowserCell *cell = (YJMediaBrowserCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:MAX(self.currentIndex, 0) inSection:0]];
        [cell videoStop];
    }
    
    NSLog(@"资源释放 - YJMediaBrowserVC");
}

- (instancetype)init {
    if (self = [super init]) {
        // 设置转场代理
        self.transitioningDelegate = self.browserAnimateDelegate;
        // 设置转场样式
        self.modalPresentationStyle = UIModalPresentationCustom;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.view.backgroundColor = UIColor.clearColor;
    self.currentDeviceOrientation = UIDeviceOrientationPortrait;
    self.originalViewWidth = CGRectGetWidth(self.view.frame);
    self.originalViewHeight = CGRectGetHeight(self.view.frame);
    
    [self.view addSubview:self.contentView];
    [self.contentView addSubview:self.collectionView];
    
    self.view.userInteractionEnabled = NO;
    
    // 添加长按手势
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressEvent:)];
    [self.contentView addGestureRecognizer:longPressGesture];
    
    // 添加平移手势
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panEvent:)];
    [self.contentView addGestureRecognizer:panGesture];
    panGesture.enabled = NO;
    self.panGesture = panGesture;
    
    // 添加捏合手势
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchEvent:)];
    [self.contentView addGestureRecognizer:pinchGesture];
    
    // 如果是点击视频进来的，则自动播放视频
    YJMediaModel *mediaModel = [self.mediaList objectAtIndex:self.startIdx];
    if (mediaModel.mediaType == YJMediaModelType_Video) {
        mediaModel.isAutoPlay = YES;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterBackground) name: UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    // 添加设备方向监听
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    // 解决第一个是视频cell时，页面刚显示出来就下滑消失，动画从屏幕左上角出来的问题
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.view.userInteractionEnabled = YES;
    });
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:MAX(self.currentIndex, 0) inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.currentCell = (YJMediaBrowserCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:MAX(self.currentIndex, 0) inSection:0]];
    });
}

// APP进入后台
- (void)applicationEnterBackground {
    // 如果当前cell是视频，且正在播放，且不是暂停状态，则暂停
    YJMediaModel *mediaModel = [self.mediaList objectAtIndex:self.currentIndex];
    if (mediaModel.mediaType == YJMediaModelType_Video && mediaModel.isPlaying && !mediaModel.isPausing) {
        YJMediaBrowserCell *cell = (YJMediaBrowserCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:MAX(self.currentIndex, 0) inSection:0]];
        [cell videoPause];
        self.needAutoResume = YES;
    }
}

// APP进入前台
- (void)applicationEnterForeground {
    if (!self.needAutoResume) {
        return;
    }
    
    // 如果当前cell是视频，且是暂停状态，并且需要自动恢复播放，则播放
    YJMediaModel *mediaModel = [self.mediaList objectAtIndex:self.currentIndex];
    if (mediaModel.mediaType == YJMediaModelType_Video && mediaModel.isPausing) {
        YJMediaBrowserCell *cell = (YJMediaBrowserCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:MAX(self.currentIndex, 0) inSection:0]];
        // 不加延迟可能会播放失败
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [cell videoResume];
        });
    }
    
    self.needAutoResume = NO;
}

#pragma mark - Public
- (void)showWithPresentingVC:(UIViewController *)presentingVC {
    [presentingVC presentViewController:self animated:YES completion:nil];
}

#pragma mark - Getter
- (NSInteger)currentIdx {
    return self.currentIndex;
}

#pragma mark - Setter
- (void)setMediaList:(NSArray<YJMediaModel *> *)mediaList {
    _mediaList = mediaList;
    
    [self updateMediaListWithWidth:self.view.bounds.size.width height:self.view.bounds.size.height isHorizontal:NO];
    
    [self.collectionView reloadData];
    
    self.panGesture.enabled = YES;
}

- (void)setStartIdx:(NSInteger)startIdx {
    _startIdx = startIdx;
    self.currentIndex = startIdx;
}

#pragma mark - Event
- (void)deviceOrientationDidChange:(NSObject *)sender {
    UIDevice *device = [sender valueForKey:@"object"];
    if (device.orientation == UIDeviceOrientationUnknown || device.orientation == UIDeviceOrientationPortraitUpsideDown || device.orientation == UIDeviceOrientationFaceUp || device.orientation == UIDeviceOrientationFaceDown) {
        return;
    }
    
    if (self.currentDeviceOrientation != device.orientation) {
        self.currentDeviceOrientation = device.orientation;
        
        [self changeDeviceOrientation:device.orientation];
    }
}

- (void)longPressEvent:(UILongPressGestureRecognizer *)longPress {
    if (self.currentCell.mediaModel.mediaType != YJMediaModelType_Video && self.currentCell.mediaModel.mediaType != YJMediaModelType_Image) {
        return;
    }
    
    UIAlertController *sheetAlert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    if (self.currentCell.mediaModel.mediaType == YJMediaModelType_Video) {
        __weak __typeof(self) weakSelf = self;
        UIAlertAction *saveAction = [UIAlertAction actionWithTitle:@"保存到相册" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf requestPhotoLibraryHander:^(BOOL authorized, NSString * _Nullable message) {
                if (authorized) {  // 已授权
                    NSString *videoPath = weakSelf.currentCell.mediaModel.videoPath;
                    if ([[NSFileManager defaultManager] fileExistsAtPath:videoPath]) {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoPath)) {
                                UISaveVideoAtPathToSavedPhotosAlbum(videoPath, weakSelf, @selector(video:didFinishSavingWithError:contextInfo:), nil);
                            }
                        });
                    } else {
                        if (weakSelf.mediaBrowserSavePhotoLibrary) {
                            weakSelf.mediaBrowserSavePhotoLibrary(NO, @"本地不存在此视频");
                        }
                    }
                } else {
                    if (weakSelf.mediaBrowserSavePhotoLibrary) {
                        weakSelf.mediaBrowserSavePhotoLibrary(NO, message);
                    }
                }
            }];
        }];
        [sheetAlert addAction:saveAction];
    } else if (self.currentCell.mediaModel.mediaType == YJMediaModelType_Image) {
        UIImage *saveImage = [self.currentCell fetchSaveImage];
        
        __weak __typeof(self) weakSelf = self;
        UIAlertAction *saveAction = [UIAlertAction actionWithTitle:@"保存到相册" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf requestPhotoLibraryHander:^(BOOL authorized, NSString * _Nullable message) {
                if (authorized) {  // 已授权
                    UIImageWriteToSavedPhotosAlbum(saveImage, weakSelf, @selector(image:didFinishSavingWithError:contextInfo:), nil);
                } else {
                    if (weakSelf.mediaBrowserSavePhotoLibrary) {
                        weakSelf.mediaBrowserSavePhotoLibrary(NO, message);
                    }
                }
            }];
        }];
        [sheetAlert addAction:saveAction];
        
        if (!self.currentCell.mediaModel.isGif) {
            UIImage *scannedImage = [self.currentCell fetchScannedImage];
            
            // 初始化扫描仪，设置设别类型和识别质量
            CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy : CIDetectorAccuracyHigh}];
            // 扫描获取的特征组
            NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:scannedImage.CGImage]];
            if (features.count > 0) {
                // 获取扫描结果
                CIQRCodeFeature *feature = [features objectAtIndex:0];
                NSString *scannedResult = feature.messageString;
                if (scannedResult.length > 0) {
                    // 添加识别图中二维码方法
                    __weak __typeof(self) weakSelf = self;
                    UIAlertAction *qrCodeAction = [UIAlertAction actionWithTitle:@"识别图中二维码" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            __strong __typeof(weakSelf) strongSelf = weakSelf;
                            NSURLComponents *components = [[NSURLComponents alloc] initWithString:scannedResult];
                            if (components) {
                                if (strongSelf.mediaBrowserQRCodeScanned) {
                                    strongSelf.mediaBrowserQRCodeScanned(YES, @"二维码识别成功", scannedResult, strongSelf.currentIdx);
                                }
                            } else {
                                if (strongSelf.mediaBrowserQRCodeScanned) {
                                    strongSelf.mediaBrowserQRCodeScanned(NO, @"不是有效的链接", nil, strongSelf.currentIdx);
                                }
                            }
                        }
                    ];
                    [sheetAlert addAction:qrCodeAction];
                } else {
                    if (self.mediaBrowserQRCodeScanned) {
                        self.mediaBrowserQRCodeScanned(NO, @"二维码识别失败", nil, self.currentIdx);
                    }
                }
            }
        }
    }
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    [sheetAlert addAction:cancelAction];
    
    [self presentViewController:sheetAlert animated:YES completion:nil];
}

- (void)panEvent:(UIPanGestureRecognizer *)pan {
    CGPoint point = [pan locationInView:self.contentView];
    switch (pan.state) {
        case UIGestureRecognizerStateBegan: {
            self.isPanEventBegin = YES;
            self.startPanPoint = point;
            [self.currentCell moveMeidaState:TMediaBrowserViewGestureState_Began point:CGPointZero];
        }
            break;
        case UIGestureRecognizerStateChanged: {
            CGPoint changePoint = CGPointMake(point.x - self.startPanPoint.x, point.y - self.startPanPoint.y);
            if (self.isPanEventBegin && fabs(changePoint.x) > fabs(changePoint.y)) {  // 说明是横向移动，关闭手势交互
                self.panGesture.enabled = NO;
                [self.currentCell moveMeidaState:TMediaBrowserViewGestureState_Ended point:CGPointZero];
            } else {  // 说明是竖向移动
                [self.currentCell moveMeidaState:TMediaBrowserViewGestureState_Changed point:changePoint];
                CGFloat colorAlpha = (changePoint.y > 0 ? (1 - changePoint.y / CGRectGetHeight(self.contentView.frame)) : 1);
                self.browserAnimateDelegate.maskViewColorAlpha = colorAlpha;
            }
            self.isPanEventBegin = NO;
        }
            break;
        case UIGestureRecognizerStateEnded: {
            if (point.y < self.startPanPoint.y - 10) {
                [self.currentCell moveMeidaState:TMediaBrowserViewGestureState_Ended point:CGPointZero];
                [UIView animateWithDuration:0.25 animations:^{
                    self.browserAnimateDelegate.maskViewColorAlpha = 1;
                }];
            } else {
                [self dismiss];
            }
        }
            break;
        default:
            break;
    }
}

- (void)pinchEvent:(UIPinchGestureRecognizer *)pinch {
    if (self.currentCell.mediaModel.mediaType != YJMediaModelType_Image) {  // 不是图片cell没有捏合手势
        return;
    }
    
    switch (pinch.state) {
        case UIGestureRecognizerStateBegan: {
            self.pinchPoint = self.contentView.center;
            if (pinch.numberOfTouches == 2) {
                CGPoint pointFirst = [pinch locationOfTouch:0 inView:self.contentView];
                CGPoint pointSecond = [pinch locationOfTouch:1 inView:self.contentView];
                self.pinchPoint = CGPointMake((pointFirst.x + pointSecond.x) / 2.0, (pointFirst.y + pointSecond.y) / 2.0);
            }
            [self.currentCell scaleMeidaState:TMediaBrowserViewGestureState_Began scale:pinch.scale pinchPoint:self.pinchPoint];
        }
            break;
        case UIGestureRecognizerStateChanged: {
            [self.currentCell scaleMeidaState:TMediaBrowserViewGestureState_Changed scale:pinch.scale pinchPoint:self.pinchPoint];
            // 重置缩放比例
            pinch.scale = 1;
        }
            break;
        case UIGestureRecognizerStateEnded: {
            [self.currentCell scaleMeidaState:TMediaBrowserViewGestureState_Ended scale:pinch.scale pinchPoint:self.pinchPoint];
            self.panGesture.enabled = !self.currentCell.mediaModel.isEnlargeMode;
        }
            break;
        default:
            break;
    }
}

#pragma mark - Private
- (void)changeDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    NSInteger idx = self.currentIndex;
    
    self.deviceOrientationChanging = YES;
    self.collectionView.hidden = YES;
    // 把 mediaView 拿出来做动画，避免因 collectionView 的 contentSize 改变导致的显示异常
    UIView *mediaView = [self.currentCell fetchMediaView];
    [self.contentView addSubview:mediaView];
    mediaView.frame = CGRectMake((CGRectGetWidth(self.contentView.frame) - CGRectGetWidth(mediaView.frame)) / 2.0, (CGRectGetHeight(self.contentView.frame) - CGRectGetHeight(mediaView.frame)) / 2.0, CGRectGetWidth(mediaView.frame), CGRectGetHeight(mediaView.frame));
    
    self.view.backgroundColor = UIColor.clearColor;
    CGFloat viewWidth = self.originalViewWidth;
    CGFloat viewHeight = self.originalViewHeight;
    CGRect viewRect = CGRectMake(0, 0, viewWidth, viewHeight);
    
    if (deviceOrientation == UIDeviceOrientationPortrait) {
        [UIView animateWithDuration:0.25 animations:^{
            // 重置 transform
            self.contentView.transform = CGAffineTransformIdentity;
        }];
        
        CGFloat mediaViewW = viewWidth - MARGIN_LEFT_RIGHT * 2;
        CGFloat mediaViewH = viewWidth * self.currentCell.mediaModel.mediaHeight / self.currentCell.mediaModel.mediaWidth;
        if (mediaViewH > viewHeight) {
            mediaViewH = viewHeight;
            mediaViewW = viewHeight * self.currentCell.mediaModel.mediaWidth / self.currentCell.mediaModel.mediaHeight;
        }
        
        self.contentView.frame = viewRect;
        self.collectionView.frame = self.contentView.bounds;
        mediaView.frame = CGRectMake((viewWidth - mediaViewW) / 2.0, (viewHeight - mediaViewH) / 2.0, mediaViewW, mediaViewH);
        
        [self updateMediaListWithWidth:viewWidth height:viewHeight isHorizontal:NO];
        
        [self.collectionView reloadData];
        self.collectionView.contentOffset = CGPointMake(MAX(idx, 0) * CGRectGetWidth(self.collectionView.frame), 0);
        
        self.deviceOrientationChanging = NO;
        self.collectionView.hidden = NO;
        self.panGesture.enabled = YES;
        
        [self resetOrientationMediaView:mediaView];
    } else {
        self.view.backgroundColor = UIColor.blackColor;
        viewWidth = self.originalViewHeight;
        viewHeight = self.originalViewWidth;
        CGPoint viewCenter = self.contentView.center;
        viewRect = CGRectMake(viewCenter.x - viewWidth / 2.0, viewCenter.y - viewHeight / 2.0, viewWidth, viewHeight);
        
        // 重置 transform
        self.contentView.transform = CGAffineTransformIdentity;
        // 获取需要旋转的角度
        CGAffineTransform targetTransform = CGAffineTransformMakeRotation(0);
        if (deviceOrientation == UIDeviceOrientationLandscapeRight) {  // home 键在左
            targetTransform = CGAffineTransformMakeRotation(M_PI * 1.5);
        } else if(deviceOrientation == UIDeviceOrientationLandscapeLeft) {  // home 键在右
            targetTransform = CGAffineTransformMakeRotation(M_PI * 0.5);
        }
        
        CGFloat mediaViewW = viewWidth - MARGIN_LEFT_RIGHT * 2;
        CGFloat mediaViewH = viewWidth * self.currentCell.mediaModel.mediaHeight / self.currentCell.mediaModel.mediaWidth;
        if (mediaViewH > viewHeight) {
            mediaViewH = viewHeight;
            mediaViewW = viewHeight * self.currentCell.mediaModel.mediaWidth / self.currentCell.mediaModel.mediaHeight;
        }
        
        self.contentView.frame = viewRect;
        self.collectionView.frame = self.contentView.bounds;
        mediaView.frame = CGRectMake((viewWidth - mediaViewW) / 2.0, (viewHeight - mediaViewH) / 2.0, mediaViewW, mediaViewH);
        
        [UIView animateWithDuration:0.25 animations:^{
            self.contentView.transform = targetTransform;
        } completion:^(BOOL finished) {
            [self updateMediaListWithWidth:viewWidth height:viewHeight isHorizontal:YES];
            
            [self.collectionView reloadData];
            self.collectionView.contentOffset = CGPointMake(MAX(idx, 0) * CGRectGetWidth(self.collectionView.frame), 0);
            
            self.deviceOrientationChanging = NO;
            self.collectionView.hidden = NO;
            self.panGesture.enabled = YES;
            
            [self resetOrientationMediaView:mediaView];
        }];
    }
}

// 重置 mediaView
- (void)resetOrientationMediaView:(UIView *)mediaView {
    // 竖屏转横屏时，获取的 self.currentCell 可能为 nil，如果直接重置 mediaVie，有可能会导致 mediaView 显示不出来
    if (self.currentCell) {
        // 把 mediaView 放回到 cell
        [mediaView removeFromSuperview];
        [self.currentCell resetMediaView];
    } else {
        // 如果 self.currentCell 为 nil，延迟重新获取 self.currentCell 后再重置 mediaVie
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.currentCell = (YJMediaBrowserCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:MAX(self.currentIndex, 0) inSection:0]];
            
            // 把 mediaView 放回到 cell
            [mediaView removeFromSuperview];
            [self.currentCell resetMediaView];
        });
    }
}

// 更新 MediaList
- (void)updateMediaListWithWidth:(CGFloat)superWidth height:(CGFloat)superHeight isHorizontal:(BOOL)isHorizontal {
    for (YJMediaModel *mediaModel in self.mediaList) {
        mediaModel.maxEnlargeMultiple = DEFAULT_MAX_ENLARGE_MULTIPLE;
        
        CGFloat viewX = MARGIN_LEFT_RIGHT;
        CGFloat viewY = 0;
        CGFloat viewW = superWidth - MARGIN_LEFT_RIGHT * 2;
        CGFloat viewH = superHeight;
        if (mediaModel.mediaWidth > 0 && mediaModel.mediaHeight > 0) {
            viewH = viewW * mediaModel.mediaHeight / mediaModel.mediaWidth;
            
            CGFloat mediaProportion = mediaModel.mediaWidth / mediaModel.mediaHeight;
            if (viewH > superHeight) {
                if (mediaProportion < LONG_IMAGE_PROPORTION) {  // 超长图
                    
                } else {
                    viewH = superHeight;
                    viewW = superHeight * mediaModel.mediaWidth / mediaModel.mediaHeight;
                    viewX = (superWidth - viewW) * 0.5;
                }
            } else {
                if (mediaProportion > WIDE_IMAGE_PROPORTION) {  // 超宽图
                    mediaModel.maxEnlargeMultiple = (superHeight / viewH) * 2.0;
                }
                viewY = (superHeight - viewH) * 0.5;
            }
        }
        mediaModel.viewRect = CGRectMake(viewX, viewY, viewW, viewH);
        mediaModel.isHorizontal = isHorizontal;
    }
}

- (void)dismiss {
    if (self.mediaBrowserDismissed) {
        self.mediaBrowserDismissed(self.currentIdx);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

// 请求相册权限
- (void)requestPhotoLibraryHander:(void(^)(BOOL authorized, NSString * _Nullable message))handler {
    PHAuthorizationStatus authStatus = [PHPhotoLibrary authorizationStatus];
    if (authStatus == PHAuthorizationStatusNotDetermined) {  // 未选择
        // 申请权限
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (status == PHAuthorizationStatusAuthorized) {
                    handler(YES, nil);
                } else {
                    handler(NO, @"相册权限没打开");
                }
            });
        }];
    } else if (authStatus == PHAuthorizationStatusAuthorized) {  // 已授权
        handler(YES, nil);
    } else {
        handler(NO, @"相册权限没打开");
    }
}

#pragma mark - UISaveVideoAtPathToSavedPhotosAlbum
// 视频保存完毕的回调
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInf {
    NSString *errorMsg = @"保存成功";
    if (error) {
        errorMsg = @"保存失败";
    }
    if (self.mediaBrowserSavePhotoLibrary) {
        self.mediaBrowserSavePhotoLibrary(error ? NO : YES, errorMsg);
    }
}

#pragma mark - UIImageWriteToSavedPhotosAlbum
// 图片保存完毕的回调
- (void)image:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInf {
    NSString *errorMsg = @"保存成功";
    if (error) {
        errorMsg = @"保存失败";
    }
    if (self.mediaBrowserSavePhotoLibrary) {
        self.mediaBrowserSavePhotoLibrary(error ? NO : YES, errorMsg);
    }
}

#pragma mark - UICollectionViewDataSource、UICollectionViewDelegate、UICollectionViewDelegateFlowLayout、UIScrollViewDelegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.mediaList.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YJMediaModel *mediaModel = [self.mediaList objectAtIndex:indexPath.item];
    YJMediaBrowserCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(YJMediaBrowserCell.class) forIndexPath:indexPath];
    cell.delegate = self;
    cell.mediaModel = mediaModel;
    return cell;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.mediaBrowserCellClicked) {
        self.mediaBrowserCellClicked(indexPath);
    }
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return collectionView.bounds.size;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.deviceOrientationChanging) {
        return;
    }
    
    int index = scrollView.contentOffset.x / scrollView.bounds.size.width + 0.5;
    if (self.currentIndex == index) {
        return;
    }
    
    [self.currentCell resetMediaViewRect];
    
    // 如果上一个cell是视频，则停止播放视频
    YJMediaModel *mediaModel = [self.mediaList objectAtIndex:self.currentIndex];
    if (mediaModel.mediaType == YJMediaModelType_Video) {
        YJMediaBrowserCell *cell = (YJMediaBrowserCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:MAX(self.currentIndex, 0) inSection:0]];
        if (mediaModel.isPlaying) {
            [cell videoStop];
        }
        [cell videoControlViewHidden];
    }
    
    self.currentIndex = index;
    self.currentCell = (YJMediaBrowserCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:MAX(self.currentIndex, 0) inSection:0]];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!self.currentCell.mediaModel.isEnlargeMode) {
        self.panGesture.enabled = YES;
    }
}

#pragma mark - YJMediaBrowserCellDelegate
- (void)mediaBrowserCellDismissed {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self dismiss];
}

// 改变遮罩透明度
- (void)mediaBrowserCellMaskViewColorAlphaChanged:(CGFloat)colorAlpha {
    self.browserAnimateDelegate.maskViewColorAlpha = colorAlpha;
}

#pragma mark - YJBrowserAnimateDelegateProtocol
// 放大动画使用的 view
- (UIView *)browserAnimateShowView {
    // 创建一个与当前显示的源 view 相同的 imageView
    YJMediaModel *mediaModel = [self.mediaList objectAtIndex:self.currentIndex];
    UIImage *image = mediaModel.thumbnailImage;
    if (!image) {
        NSString *imagePath = (mediaModel.mediaType == YJMediaModelType_Video ? mediaModel.coverPath : mediaModel.thumbnailPath);
        image = [UIImage imageWithContentsOfFile:imagePath];
    }
    // 创建一个新的 imageView
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    
    CGFloat mediaProportion = mediaModel.mediaWidth / mediaModel.mediaHeight;
    if (mediaProportion < LONG_IMAGE_PROPORTION) {  // 超长图
        // 超长图显示顶部
//        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.layer.contentsRect = CGRectMake(0, 0, 1, self.view.bounds.size.height / (self.view.bounds.size.width- MARGIN_LEFT_RIGHT * 2) * image.size.width / image.size.height);
    }
    
    return imageView;
}

// 缩小动画使用的 view
- (UIView *)browserAnimateDismissView {
    if (self.currentDeviceOrientation != UIDeviceOrientationPortrait) {
        self.contentView.backgroundColor = UIColor.blackColor;
        return self.contentView;
    }
    
    YJMediaBrowserCell *cell = (YJMediaBrowserCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:self.currentIndex inSection:0]];
    return [cell fetchDismissView];
}

// 显示时的位置（起点，被点击 view 相对于 keywindow 的 frame）
- (CGRect)browserAnimationShowRect {
    YJMediaModel *mediaModel = [self.mediaList objectAtIndex:self.currentIndex];
    CGRect frame = [mediaModel.srcView.superview convertRect:mediaModel.srcView.frame toView:nil];
    return frame;
}

// 显示时的位置（终点，被点击的 view 在图片浏览器中显示的 frame）
- (CGRect)browserAnimationShowEndRect {
    YJMediaModel *mediaModel = [self.mediaList objectAtIndex:self.currentIndex];
    CGFloat mediaProportion = mediaModel.mediaWidth / mediaModel.mediaHeight;
    if (mediaProportion < LONG_IMAGE_PROPORTION) {  // 超长图
        return CGRectMake(MARGIN_LEFT_RIGHT, 0, self.view.bounds.size.width - MARGIN_LEFT_RIGHT * 2, self.view.bounds.size.height);
    }
    return mediaModel.viewRect;
}

// 消失时的位置（起点，view 当前显示的 rect）
- (CGRect)browserAnimateDismissRect {
    if (self.currentDeviceOrientation != UIDeviceOrientationPortrait) {
        return self.view.frame;
    }
    
    return [self.currentCell fetchMediaViewRect];
}

// 消失时的位置（终点，最终动画在这个 rect 区域消失）
- (CGRect)browserAnimateDismissEndRect {
    if (self.currentDeviceOrientation == UIDeviceOrientationLandscapeRight) {  // home 键在左
        return CGRectMake(-CGRectGetHeight(self.view.frame), 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame));
    } else if(self.currentDeviceOrientation == UIDeviceOrientationLandscapeLeft) {  // home 键在右
        return CGRectMake(CGRectGetHeight(self.view.frame), 0, CGRectGetHeight(self.view.frame), CGRectGetHeight(self.view.frame));
    }
    
    YJMediaModel *mediaModel = [self.mediaList objectAtIndex:self.currentIndex];
    UIView *srcView = mediaModel.srcView;
    CGRect rect = [srcView.superview convertRect:srcView.frame toView:nil];
    if (CGRectEqualToRect(rect, CGRectZero)) {
        rect = mediaModel.srcViewRect;
    }
    return rect;
}

// 消失时的透明度
- (CGFloat)browserAnimateDismissAlpha {
    if (self.currentDeviceOrientation != UIDeviceOrientationPortrait) {
        return 1.0;
    }
    
    return 1.0;
}

// 消失时蒙层是否渐隐
- (BOOL)browserAnimateDismissFadeAway {
    if (self.currentDeviceOrientation != UIDeviceOrientationPortrait) {
        return NO;
    }
    
    return YES;
}

// 出现&消失时视图的圆角
- (CGFloat)browserAnimateViewCornerRadius {
    if (self.currentDeviceOrientation != UIDeviceOrientationPortrait) {
        return 0;
    }
    
    return self.viewCornerRadius;
}

#pragma mark - Lazy
- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] initWithFrame:self.view.bounds];
    }
    return _contentView;
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
        _collectionView.backgroundColor = UIColor.clearColor;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.pagingEnabled = YES;
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.delaysContentTouches = NO;  // 是否延迟把事件传递给subView（延迟150ms），设置为NO会立即把事件传递给subView
        _collectionView.canCancelContentTouches = YES;  // 如果设置为NO，这消息一旦传递给subView，这scroll事件就不会再发生
        
        [_collectionView registerClass:YJMediaBrowserCell.class forCellWithReuseIdentifier:NSStringFromClass(YJMediaBrowserCell.class)];
    }
    return _collectionView;
}

- (YJBrowserAnimateDelegate *)browserAnimateDelegate {
    if (!_browserAnimateDelegate) {
        _browserAnimateDelegate = [[YJBrowserAnimateDelegate alloc] init];
        _browserAnimateDelegate.delegate = self;
    }
    return _browserAnimateDelegate;
}

@end
