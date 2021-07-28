//
//  YJMediaModel.h
//  timingapp
//
//  Created by YZ X on 2020/12/16.
//  Copyright © 2020 huiian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


#define LONG_IMAGE_PROPORTION (9.0 / 20.0)  // 超长图的比例
#define WIDE_IMAGE_PROPORTION (16.0 / 9.0)  // 超长图的比例


NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, YJMediaModelType) {
    YJMediaModelType_Image,  // 图片
    YJMediaModelType_Video,  // 视频
};


@interface YJMediaModel : NSObject

@property (nonatomic, assign) YJMediaModelType mediaType;  // 资源类型
@property (nonatomic, assign) CGFloat mediaWidth;  //
@property (nonatomic, assign) CGFloat mediaHeight;  //

@property (nonatomic, weak) UIView *srcView;  // 来源 view
@property (nonatomic, assign) CGRect srcViewRect;  // 当 srcView 获取不到 frame 时使用（比如 srcView 移动到屏幕外时）

// 图片
@property (nonatomic, weak) UIImage *thumbnailImage;  // 缩略图图片
@property (nonatomic, copy) NSString *thumbnailPath;  // 缩略图本地路径
@property (nonatomic, copy) NSString *thumbnailUrl;  // 缩略图远端路径（暂未处理）
@property (nonatomic, copy) NSString *imagePath;  // 图片本地路径
@property (nonatomic, copy) NSString *imageUrl;  // 图片远端路径
@property (nonatomic, assign) BOOL isGif;  //

// 视频
@property (nonatomic, copy) NSString *coverPath;  // 封面本地路径
@property (nonatomic, copy) NSString *coverUrl;  // 封面远端路径
@property (nonatomic, copy) NSString *videoPath;  // 视频本地路径
@property (nonatomic, copy) NSString *videoUrl;  // 视频远端路径
@property (nonatomic, assign) CGFloat videoDuration;  // 视频时长（秒）

@property (nonatomic, assign) CGRect viewRect;  // 资源在浏览器中的 frame（不用传，会自动计算）
@property (nonatomic, assign) BOOL isHorizontal;  // 是否是横屏
@property (nonatomic, assign) BOOL isAutoPlay;  // 是否自动播放（点击视频进媒体浏览器时，视频要自动播放）

@property (nonatomic, assign) BOOL isEnlargeMode;  // 是否是放大模式
@property (nonatomic, assign) BOOL isPlaying;  // 是否正在播放
@property (nonatomic, assign) BOOL isPausing;  // 是否是暂停状态
@property (nonatomic, assign) CGFloat progress;  // 播放进度

@property (nonatomic, assign) CGFloat maxEnlargeMultiple;  // 最大放大倍数（不用传，会自动计算）

@end

NS_ASSUME_NONNULL_END
