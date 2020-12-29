//
//  HXPhotoSubViewCell.h
//  HXPhotoPickerExample
//
//  Created by Silence on 17/2/17.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIImageView+HXExtension.h"
#import "HXPhotoViewCellCustomProtocol.h"

#if __has_include(<SDWebImage/UIImageView+WebCache.h>)
#import <SDWebImage/UIImageView+WebCache.h>
#elif __has_include("UIImageView+WebCache.h")
#import "UIImageView+WebCache.h"
#endif

#if __has_include(<YYWebImage/YYWebImage.h>)
#import <YYWebImage/YYWebImage.h>
#elif __has_include("YYWebImage.h")
#import "YYWebImage.h"
#elif __has_include(<YYKit/YYKit.h>)
#import <YYKit/YYKit.h>
#elif __has_include("YYKit.h")
#import "YYKit.h"
#endif

@protocol HXPhotoSubViewCellDelegate <NSObject>

- (void)cellDidDeleteClcik:(UICollectionViewCell *)cell; 
@end

@class HXPhotoModel;
@interface HXPhotoSubViewCell : UICollectionViewCell
@property (weak, nonatomic) id<HXPhotoSubViewCellDelegate> delegate;
@property (strong, nonatomic, readonly) UIImageView *imageView;
@property (strong, nonatomic, readonly) UIButton *deleteBtn;
@property (weak, nonatomic) id<HXPhotoViewCellCustomProtocol> customProtocol;
@property (assign, nonatomic) BOOL canEdit;
@property (strong, nonatomic) UIView *highlightMaskView;
@property (strong, nonatomic) HXPhotoModel *model;
/**  删除按钮图片  */
@property (copy, nonatomic) NSString *deleteImageName;
/**  隐藏cell上的删除按钮  */
@property (assign, nonatomic) BOOL hideDeleteButton;
/**  删除网络图片时是否显示Alert  */
@property (assign, nonatomic) BOOL showDeleteNetworkPhotoAlert;
@property (assign, nonatomic) BOOL deleteCellShowAlert;

@property (assign, nonatomic) NSInteger index;
// 重新下载
- (void)againDownload;
- (void)resetNetworkImage;
@end
