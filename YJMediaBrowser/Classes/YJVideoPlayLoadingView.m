//
//  YJVideoPlayLoadingView.m
//  MediaBrowserDemo
//
//  Created by YZ X on 2021/3/16.
//

#import "YJVideoPlayLoadingView.h"
#import "Masonry.h"
#import "UIImage+YJBundleImage.h"


@interface YJVideoPlayLoadingView ()

@property (nonatomic, strong) UIImageView *loadingImageView;
@property (nonatomic, strong) CADisplayLink *link;

@end


@implementation YJVideoPlayLoadingView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.loadingImageView = [[UIImageView alloc] init];
        [self addSubview:self.loadingImageView];
        self.loadingImageView.image = [UIImage yj_bundleImageNamed:@"media_browser_video_loading"];
        [self.loadingImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.mas_equalTo(self);
            make.width.height.equalTo(@42);
        }];
    }
    return self;
}

- (void)startAnimation {
    if (!self.link) {
        self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(animateRunning)];
        [self.link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    }
}

- (void)animateRunning {
    self.loadingImageView.transform = CGAffineTransformRotate(self.loadingImageView.transform, M_PI / 30.0);
}

- (void)stopAnimation {
    [self.link invalidate];
    self.link = nil;
}

@end
