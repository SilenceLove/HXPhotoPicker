//
//  HXPhotoEditGraffitiColorSizeView.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2020/8/14.
//  Copyright © 2020 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HXPhotoEditGraffitiColorSizeView : UIView
@property (assign, nonatomic) CGFloat scale;

@property (copy, nonatomic) void (^ changeColorSize)(CGFloat scale);

+ (instancetype)initView;

@end

NS_ASSUME_NONNULL_END
