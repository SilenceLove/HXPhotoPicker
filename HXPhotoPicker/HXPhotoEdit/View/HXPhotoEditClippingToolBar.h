//
//  HXPhotoEditClippingToolBar.h
//  photoEditDemo
//
//  Created by Silence on 2020/6/30.
//  Copyright © 2020 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class HXPhotoEditClippingToolBarRotaioModel;
@interface HXPhotoEditClippingToolBar : UIView
@property (assign, nonatomic) BOOL enableRotaio;
@property (strong, nonatomic) UIColor *themeColor;
@property (assign, nonatomic) BOOL enableReset;
@property (copy, nonatomic) void (^ didBtnBlock)(NSInteger tag);

@property (copy, nonatomic) void (^ didRotateBlock)(void);
@property (copy, nonatomic) void (^ didMirrorHorizontallyBlock)(void);

@property (copy, nonatomic) void (^ selectedRotaioBlock)(HXPhotoEditClippingToolBarRotaioModel *model);
+ (instancetype)initView;

- (void)resetRotate;

- (void)setRotateAlpha:(CGFloat)alpha;

@end

@interface HXPhotoEditClippingToolBarHeader : UICollectionReusableView
@property (assign, nonatomic) BOOL enableRotaio;
@property (copy, nonatomic) void (^ didRotateBlock)(void);
@property (copy, nonatomic) void (^ didMirrorHorizontallyBlock)(void);
@end

@interface HXPhotoEditClippingToolBarHeaderViewCell : UICollectionViewCell
@property (strong, nonatomic) UIColor *themeColor;
@property (strong, nonatomic) HXPhotoEditClippingToolBarRotaioModel *model;
@end

@interface HXPhotoEditClippingToolBarRotaioModel : NSObject

@property (assign, nonatomic) CGSize size;

@property (assign, nonatomic) CGSize scaleSize;

@property (assign, nonatomic) CGFloat widthRatio;
@property (assign, nonatomic) CGFloat heightRatio;

@property (copy, nonatomic) NSString *scaleText;

@property (assign, nonatomic) BOOL isSelected;
@end
NS_ASSUME_NONNULL_END
