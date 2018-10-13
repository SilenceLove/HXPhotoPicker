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
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (strong, nonatomic) NSMutableArray *albumModelArray;
@property (strong, nonatomic) HXAlbumModel *currentSelectModel;
@property (copy, nonatomic) void (^didSelectRowBlock)(HXAlbumModel *model);
- (instancetype)initWithManager:(HXPhotoManager *)manager;
- (void)refreshCamearCount;
@end

@interface HXAlbumlistViewCell : UITableViewCell
@property (strong, nonatomic) HXAlbumModel *model;
@property (strong, nonatomic) HXPhotoManager *manager;
- (void)cancelRequest ;
@end

@interface HXAlbumTitleView : UIView
@property (strong, nonatomic) HXPhotoManager *manager;
@property (strong, nonatomic) HXAlbumModel *model;
@property (assign, nonatomic, readonly) BOOL selected;
@property (copy, nonatomic) void (^didTitleViewBlock)(BOOL selected);
- (instancetype)initWithManager:(HXPhotoManager *)manager; 
- (void)deSelect;
- (void)setupAlpha:(BOOL)anima;
@end
