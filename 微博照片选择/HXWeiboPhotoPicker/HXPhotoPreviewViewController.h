//
//  HXPhotoPreviewViewController.h
//  微博照片选择
//
//  Created by 洪欣 on 17/2/9.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HXPhotoManager.h"

@protocol HXPhotoPreviewViewControllerDelegate <NSObject>

- (void)didSelectedClick:(HXPhotoModel *)model AddOrDelete:(BOOL)state;
- (void)previewDidNextClick;

@end

@class HXPhotoView;
@interface HXPhotoPreviewViewController : UIViewController<UINavigationControllerDelegate>
@property (weak, nonatomic) id<HXPhotoPreviewViewControllerDelegate> delegate;
@property (strong, nonatomic) NSMutableArray *modelList;
@property (assign, nonatomic) NSInteger index;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (weak, nonatomic, readonly) UICollectionView *collectionView;
@property (assign, nonatomic) BOOL selectedComplete;
@property (assign, nonatomic) BOOL isPreview; // 是否预览
@property (strong, nonatomic) HXPhotoView *photoView;
@property (assign, nonatomic) BOOL isTouch;// 是否为3dThouch预览
@property (strong, nonatomic) UIButton *selectedBtn;
@property (strong, nonatomic) UIImage *gifCoverImage;
@property (strong, nonatomic) HXPhotoModel *currentModel; // 当前查看的照片模型
- (void)setup;
- (void)selectClick;
@end
