//
//  WxMomentHeaderView.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2020/8/4.
//  Copyright © 2020 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class HXPhotoManager;
@interface WxMomentHeaderView : UIView
@property (strong, nonatomic) HXPhotoManager *photoManager;
+ (instancetype)initView;

@end

NS_ASSUME_NONNULL_END
