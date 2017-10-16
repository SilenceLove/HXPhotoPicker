//
//  HXDatePhotoViewController.h
//  微博照片选择
//
//  Created by 洪欣 on 2017/10/14.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HXPhotoManager.h"
@interface HXDatePhotoViewController : UIViewController
@property (strong, nonatomic) HXPhotoManager *manager;
@property (strong, nonatomic) HXAlbumModel *albumModel;
@end

@interface HXDatePhotoViewCell : UICollectionViewCell
@property (strong, nonatomic, readonly) UIImageView *imageView;
@property (strong, nonatomic) HXPhotoModel *model;
@end

@interface HXDatePhotoViewSectionHeaderView : UICollectionReusableView
@property (strong, nonatomic) HXPhotoDateModel *model;
@end
