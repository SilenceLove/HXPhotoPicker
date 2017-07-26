//
//  HXVideoPreviewViewController.h
//  微博照片选择
//
//  Created by 洪欣 on 17/2/9.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HXPhotoModel.h"
#import "HXPhotoManager.h"

@protocol HXVideoPreviewViewControllerDelegate <NSObject>

- (void)previewVideoDidSelectedClick:(HXPhotoModel *)model;
- (void)previewVideoDidNextClick;

@end

@class HXPhotoView;
@interface HXVideoPreviewViewController : UIViewController<UINavigationControllerDelegate>
@property (assign, nonatomic) BOOL isTouch;
@property (weak, nonatomic) id<HXVideoPreviewViewControllerDelegate> delegate;
@property (strong, nonatomic) HXPhotoModel *model;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (strong, nonatomic) UIView *maskView;
@property (strong, nonatomic) AVPlayer *playVideo;
@property (strong, nonatomic) UIButton *playBtn;
@property (assign, nonatomic) BOOL isCamera;
@property (assign, nonatomic) BOOL selectedComplete;
@property (assign, nonatomic) BOOL isPreview; // 是否预览
@property (strong, nonatomic) UIImage *coverImage;
@property (strong, nonatomic) UIButton *selectedBtn;

@property (strong, nonatomic) HXPhotoView *photoView;
- (void)setup;
- (void)selectClick;
@end
