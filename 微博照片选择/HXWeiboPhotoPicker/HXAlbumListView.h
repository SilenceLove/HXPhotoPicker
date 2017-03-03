//
//  HXAlbumListView.h
//  微博照片选择
//
//  Created by 洪欣 on 17/2/8.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HXAlbumModel.h"

@protocol HXAlbumListViewDelegate <NSObject>

- (void)didTableViewCellClick:(HXAlbumModel *)model animate:(BOOL)anim;

@end

@interface HXAlbumListView : UIView
@property (weak, nonatomic) id<HXAlbumListViewDelegate> delegate;
@property (copy, nonatomic) NSArray *list;
@end

@interface HXAlbumListViewCell : UITableViewCell
@property (strong, nonatomic) HXAlbumModel *model;
@end
