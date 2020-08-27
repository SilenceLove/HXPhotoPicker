//
//  HXPhotoEditGraffitiColorSizeView.h
//  HXPhotoPicker-Demo
//
//  Created by 洪欣 on 2020/8/14.
//  Copyright © 2020 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HXPhotoEditGraffitiColorSizeView : UIView
@property (assign, nonatomic) CGFloat scale;

@property (copy, nonatomic) void (^ changeColorSize)(CGFloat scale);

+ (instancetype)initView;

@end

NS_ASSUME_NONNULL_END
