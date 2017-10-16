//
//  HXDatePhotoPreviewViewController.h
//  微博照片选择
//
//  Created by 洪欣 on 2017/10/14.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HXPhotoManager.h"
@interface HXDatePhotoPreviewViewController : UIViewController
@property (strong, nonatomic) HXPhotoManager *manager;
@end


@interface HXDatePhotoPreviewViewCell : UICollectionViewCell

@end
