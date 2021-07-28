//
//  YJMediaBrowserBottomControlView.h
//  timingapp
//
//  Created by YZ X on 2020/12/17.
//  Copyright © 2020 huiian. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSUInteger, YJMediaBrowserBottomControlViewGestureState) {
    YJMediaBrowserBottomControlViewGestureState_Began,     // 手势开始
    YJMediaBrowserBottomControlViewGestureState_Changing,  // 手势改变
    YJMediaBrowserBottomControlViewGestureState_Ended,     // 手势结束
};


@protocol YJMediaBrowserBottomControlViewDelegate <NSObject>

@optional
- (void)mediaBrowserBottomControlViewProgressChange:(YJMediaBrowserBottomControlViewGestureState)gestureState progress:(CGFloat)progress;
- (void)mediaBrowserBottomControlViewPlayButtonClicked;  // 播放按钮

@end


@interface YJMediaBrowserBottomControlView : UIView

@property (nonatomic, weak) id<YJMediaBrowserBottomControlViewDelegate> delegate;

@property (nonatomic, assign) CGFloat totalTime;  // 总时长
@property (nonatomic, assign) CGFloat progressTime;  // 当前播放时长
@property (nonatomic, assign) BOOL isPlaying;  // 是否正在播放
@property (nonatomic, assign) BOOL isHorizontal;  // 是否是横屏

@end

NS_ASSUME_NONNULL_END
