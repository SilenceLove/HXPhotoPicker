//
//  JRStrainImageShowViewCell.h
//  JRCollectionView
//
//  Created by Mr.D on 2018/8/6.
//  Copyright © 2018年 Mr.D. All rights reserved.
//

#import <UIKit/UIKit.h>

extern CGFloat const JR_LABEL_HEIGHT;
@class JRFilterModel;
@interface JRFilterBarCell : UICollectionViewCell

/** 默认字体和框框颜色 */
@property (nonatomic, strong) UIColor *defaultColor;
/** 已选字体和框框颜色 */
@property (nonatomic, strong) UIColor *selectColor;

@property (nonatomic, assign) BOOL isSelectedModel;

- (void)setCellData:(JRFilterModel *)cellData image:(UIImage *)image;

+ (NSString *)identifier;


@end

