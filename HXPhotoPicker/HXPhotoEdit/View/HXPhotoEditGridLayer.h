//
//  HXPhotoEditGridLayer.h
//  photoEditDemo
//
//  Created by Silence on 2020/6/29.
//  Copyright © 2020 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HXPhotoEditGridLayer : CAShapeLayer

@property (nonatomic, assign) CGRect gridRect;
- (void)setGridRect:(CGRect)gridRect animated:(BOOL)animated;
- (void)setGridRect:(CGRect)gridRect animated:(BOOL)animated completion:(void (^ _Nullable)(BOOL finished))completion;
@property (nonatomic, assign) BOOL isRound;
@property (nonatomic, strong) UIColor *bgColor;
@property (nonatomic, strong) UIColor *gridColor;
@end

NS_ASSUME_NONNULL_END
