//
//  YJBrowserAnimateDelegate.m
//  timingapp
//
//  Created by YZ X on 2020/12/16.
//  Copyright © 2020 huiian. All rights reserved.
//

#import "YJBrowserAnimateDelegate.h"

static CGFloat YJAnimationDuration = 0.25;

@interface YJBrowserAnimateDelegate ()

/** 记录当前是否是弹出 */
@property (nonatomic, assign, getter=isPresented) BOOL presented;

/** modal时的黑色背景 */
@property (nonatomic, strong) UIView *maskView;

@end


@implementation YJBrowserAnimateDelegate

- (void)dealloc {
    NSLog(@"资源释放 - YJBrowserAnimateDelegate dealloc");
}

#pragma mark - UIViewControllerTransitioningDelegate
// 该代理方法用于返回负责转场的控制器对象
- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source {
    /**
     创建一个负责管理自定义转场动画的控制器
     - parameter presentedViewController:  被弹出的控制器
     - parameter presentingViewController: 发起modal的 源控制器
     Xocde7以前系统传递给我们的是nil, Xcode7开始传递给我们的是一个野指针
     - returns: 负责管理自定义转场动画的控制器
     */
    return [[UIPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting];
}

// 该代理方法用于告诉系统谁来负责控制器如何弹出
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    self.presented = YES;
    return self;
}

// 该代理方法用于告诉系统谁来负责控制器如何消失
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    self.presented = NO;
    return self;
}

#pragma mark - UIViewControllerAnimatedTransitioning
// 用于返回动画的时长, 默认用不上
- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 1.0;
}

// 该方法用于负责控制器如何弹出和如何消失，只要是自定义转场, 控制器弹出和消失都会调用该方法，需要在该方法中告诉系统控制器如何弹出和如何消失
// 注意: 只要告诉系统我们需要自己来控制 VC 的弹出和消失（也就是实现了代理 UIViewControllerAnimatedTransitioning 方法）之后, 系统就不会再控制 VC 的动画了, 所有的操作都需要自己完成
// 系统调用该方法时会传递一个 transitionContext 参数, 该参数中包含了我们所有需要的值
- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    // 判断当前是弹出还是消失
    if (self.isPresented) {  // 弹出
        [self animatePresentedController:transitionContext];
    } else {
        [self animateDismissedController:transitionContext];
    }
}

#pragma mark - Setter
- (void)setMaskViewColorAlpha:(CGFloat)maskViewColorAlpha {
    _maskViewColorAlpha = maskViewColorAlpha;
    
    self.maskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:maskViewColorAlpha];
}

#pragma mark - Private
// 弹出动画
- (void)animatePresentedController:(id<UIViewControllerContextTransitioning>)transitionContext {
    NSAssert(self.delegate != nil, @"必须有代理对象才能执行动画");
    // 添加遮盖
    [self addMaskView:[transitionContext containerView]];
    
    // 1.得到当前点击的 view
    UIView *presenteView = [self.delegate browserAnimateShowView];
    presenteView.layer.masksToBounds = YES;
    presenteView.layer.cornerRadius = [self.delegate browserAnimateViewCornerRadius];
    // 2.设置 frame
    presenteView.frame = [self.delegate browserAnimationShowRect];
    // 3.将 presenteView 添加到容器视图上
    [[transitionContext containerView] addSubview:presenteView];
    // 4.执行动画，使 presenteView 放大到最大
    CGRect toRect = [self.delegate browserAnimationShowEndRect];
    
    [UIView animateWithDuration:YJAnimationDuration animations:^{
        presenteView.layer.cornerRadius = 0;
        presenteView.frame = toRect;
    } completion:^(BOOL finished) {
        // 5.添加原来的图片浏览器
        UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
        [[transitionContext containerView] addSubview:toView];
        // 6.通知系统,动画执行完毕
        // 注意: 自定义转场一定要在自定义动画完成之后告诉系统动画已经完成了，否则会出现一些未知异常
        [transitionContext completeTransition:YES];
        // 移除 presenteView（presenteView 的使命就是让用户看到这个动画过程），不然遮挡 browser，collectionView 不能滑动
        [presenteView removeFromSuperview];
    }];
}

// 隐藏动画
- (void)animateDismissedController:(id<UIViewControllerContextTransitioning>)transitionContext {
    // 1.得到当前点击的 view
    UIView *dismissView = [self.delegate browserAnimateDismissView];
    dismissView.layer.masksToBounds = YES;
    // 2.设置 frame，此时初始值为 dismissView 当前的 frame
    dismissView.frame = [self.delegate browserAnimateDismissRect];
    // 3.将 dismissView 添加到容器视图上
    [[transitionContext containerView] addSubview:dismissView];
    // 4.dismissView 最终的 frame,
    CGRect endRect = [self.delegate browserAnimateDismissEndRect];
    // 5.移除图片浏览器控制器的 view
    UIView *browserVcView = [transitionContext viewForKey:UITransitionContextFromViewKey];
    [browserVcView removeFromSuperview];
    
    // 移除遮盖
    [self dismissMaskView];
    
    [UIView animateWithDuration:YJAnimationDuration animations:^{
        dismissView.alpha = [self.delegate browserAnimateDismissAlpha];
        dismissView.layer.cornerRadius = [self.delegate browserAnimateViewCornerRadius];
        dismissView.frame = endRect;
    } completion:^(BOOL finished) {
        // 移除 dismissView（dismissView 的使命就是让用户看到这个动画过程）
        [dismissView removeFromSuperview];
        // 6.通知系统，动画执行完毕
        // 注意: 自定义转场一定要在自定义动画完成之后告诉系统动画已经完成了，否则会出现一些未知异常
        [transitionContext completeTransition:YES];
    }];
}

- (void)addMaskView:(UIView *)view {
    if (!self.maskView) {
        self.maskView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [view addSubview:self.maskView];
    }
    self.maskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.1];
    [UIView animateWithDuration:YJAnimationDuration animations:^{
        self.maskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:1];
    }];
}

- (void)dismissMaskView {
    if ([self.delegate browserAnimateDismissFadeAway]) {
        [UIView animateWithDuration:YJAnimationDuration animations:^{
            self.maskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.1];
        } completion:^(BOOL finished) {
            [self.maskView removeFromSuperview];
            self.maskView = nil;
        }];
    } else {
        [self.maskView removeFromSuperview];
        self.maskView = nil;
    }
}

@end
