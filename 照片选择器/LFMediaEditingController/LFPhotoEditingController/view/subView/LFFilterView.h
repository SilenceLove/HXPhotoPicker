//
//  LFFilterView.h
//  LFMediaEditingController
//
//  Created by TsanFeng Lam on 2018/8/6.
//  Copyright © 2018年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LFColorMatrixType.h"

@interface LFFilterView : UIView

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) LFColorMatrixType cmType;

/** 数据 */
@property (nonatomic, strong) NSDictionary *data;

@end
