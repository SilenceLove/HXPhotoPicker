//
//  HXPhotoView.h
//  微博照片选择
//
//  Created by 洪欣 on 17/2/17.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HXPhotoManager.h"

@protocol HXPhotoViewDelegate <NSObject>

- (void)photoViewChangeComplete:(NSArray *)allList Photos:(NSArray *)photos Videos:(NSArray *)videos Original:(BOOL)isOriginal;

- (void)photoViewUpdateFrame:(CGRect)frame;

@end

@interface HXPhotoView : UIView

@property (weak, nonatomic) id<HXPhotoViewDelegate> delegate;
@property (strong, nonatomic) NSIndexPath *currentIndexPath;
- (instancetype)initWithFrame:(CGRect)frame WithManager:(HXPhotoManager *)manager;
@end
