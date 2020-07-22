//
//  HXPhotoEditClippingToolBar.h
//  photoEditDemo
//
//  Created by 洪欣 on 2020/6/30.
//  Copyright © 2020 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HXPhotoEditClippingToolBar : UIView
@property (assign, nonatomic) BOOL enableReset;
@property (copy, nonatomic) void (^ didBtnBlock)(NSInteger tag);
+ (instancetype)initView;
@end

NS_ASSUME_NONNULL_END
