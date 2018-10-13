//
//  JRImgObj.h
//  JRCollectionView
//
//  Created by Mr.D on 2018/8/6.
//  Copyright © 2018年 Mr.D. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LFColorMatrixType.h"

@interface JRFilterModel : NSObject

@property (nonatomic, readonly) NSString *name;

@property (nonatomic, readonly) UIImage *image;

@property (nonatomic, readonly) LFColorMatrixType effectType;

@property (nonatomic, assign) BOOL isSelect;

- (instancetype)initWithEffectType:(LFColorMatrixType)type;

- (void)createFilterImage:(UIImage *)image;

@end
