//
//  UIImage+YJBundleImage.m
//  MediaBrowserDemo
//
//  Created by YZ X on 2021/4/7.
//

#import "UIImage+YJBundleImage.h"
#import "YJMediaModel.h"

@implementation UIImage (YJBundleImage)

+ (NSBundle *)yj_mediaBrowserBundle {
    static NSBundle *mediaBrowserBundle = nil;
    if (mediaBrowserBundle == nil) {
        mediaBrowserBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[YJMediaModel class]] pathForResource:@"YJMediaBrowser" ofType:@"bundle"]];
    }
    return mediaBrowserBundle;
}

+ (UIImage *)yj_bundleImageNamed:(NSString *)named {
//    UIImage *bundleImg = [[UIImage imageWithContentsOfFile:[[self yj_mediaBrowserBundle] pathForResource:[NSString stringWithFormat:@"%@@2x", named] ofType:@"png"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    UIImage *bundleImg;
    if (@available(iOS 13.0, *)) {
        bundleImg = [UIImage imageNamed:named inBundle:[self yj_mediaBrowserBundle] withConfiguration:nil];
    } else {
        bundleImg = [UIImage imageNamed:named inBundle:[self yj_mediaBrowserBundle] compatibleWithTraitCollection:nil];
    }
    return bundleImg;
}

@end
