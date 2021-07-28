//
//  YJBrowserAnimateDelegate.h
//  timingapp
//
//  Created by YZ X on 2020/12/16.
//  Copyright © 2020 huiian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class YJBrowserAnimateDelegate;

@protocol YJBrowserAnimateDelegateProtocol <NSObject>

// 放大动画使用的 view
- (UIView *)browserAnimateShowView;

// 缩小动画使用的 view
- (UIView *)browserAnimateDismissView;

// 显示时的位置（起点，被点击 view 相对于 keywindow 的 frame）
- (CGRect)browserAnimationShowRect;

// 显示时的位置（终点，被点击的 view 在图片浏览器中显示的 frame）
- (CGRect)browserAnimationShowEndRect;

// 消失时的位置（起点，view 当前显示的 rect）
- (CGRect)browserAnimateDismissRect;

// 消失时的位置（终点，最终动画在这个 rect 区域消失）
- (CGRect)browserAnimateDismissEndRect;

// 消失时的透明度
- (CGFloat)browserAnimateDismissAlpha;

// 消失时蒙层是否渐隐
- (BOOL)browserAnimateDismissFadeAway;

// 出现&消失时视图的圆角
- (CGFloat)browserAnimateViewCornerRadius;

@end


@interface YJBrowserAnimateDelegate : NSObject <UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning>

@property (nonatomic, weak) id<YJBrowserAnimateDelegateProtocol> delegate;

@property (nonatomic, assign) CGFloat maskViewColorAlpha;  //

@end

NS_ASSUME_NONNULL_END
