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

@interface HXPhotoPreviewViewController : UIViewController<UINavigationControllerDelegate>
@property (weak, nonatomic) id<HXPhotoPreviewViewControllerDelegate> delegate;
@property (copy, nonatomic) NSArray *modelList;
@property (assign, nonatomic) NSInteger index;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (weak, nonatomic, readonly) UICollectionView *collectionView;
@property (assign, nonatomic) BOOL selectedComplete;
- (void)selectClick;
@end
