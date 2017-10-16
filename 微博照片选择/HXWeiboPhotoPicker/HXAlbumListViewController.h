//
//  HXDateAlbumViewController.h
//  微博照片选择
//
//  Created by 洪欣 on 2017/10/14.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HXAlbumModel.h"
#import "HXPhotoManager.h"
@interface HXAlbumListViewController : UIViewController
@property (strong, nonatomic) HXPhotoManager *manager;
@end

@interface HXAlbumListQuadrateViewCell : UICollectionViewCell
@property (strong, nonatomic) HXAlbumModel *model;
@end
