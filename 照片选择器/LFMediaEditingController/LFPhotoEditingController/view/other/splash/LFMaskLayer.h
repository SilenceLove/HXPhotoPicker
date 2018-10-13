//
//  LFMaskLayer.h
//  DrawTest
//
//  Created by LamTsanFeng on 2017/3/3.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LFBlurBezierPath : UIBezierPath

@property (nonatomic, assign) BOOL isClear;

@end




@interface LFMaskLayer : CALayer

@property (nonatomic, strong) NSMutableArray <LFBlurBezierPath *>*lineArray;
@end
