//
//  HXAlbumlistView.h
//  照片选择器
//
//  Created by 洪欣 on 2018/9/26.
//  Copyright © 2018年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HXAlbumModel, HXPhotoManager;
@interface HXAlbumlistView : UIView
@property (strong, nonatomic) HXPhotoManager *manager;
@property (strong, nonatomic) NSMutableArray *albumModelArray;
@end

@interface HXAlbumlistViewCell : UITableViewCell
@property (strong, nonatomic) HXAlbumModel *model;
- (void)cancelRequest ;
@end

@interface HXAlbumTitleView : UIView
@property (strong, nonatomic) HXPhotoManager *manager;
@property (strong, nonatomic) HXAlbumModel *model;
@end
