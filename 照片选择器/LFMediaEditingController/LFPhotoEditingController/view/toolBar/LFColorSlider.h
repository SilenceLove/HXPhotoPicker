//
//  LFColorSlider.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/3/28.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LFColorSliderDelegate;

@interface LFColorSlider : UISlider

/** 无须实现addTarget，实现代理方法即可 */
@property (nonatomic, weak) id<LFColorSliderDelegate> delegate;

/** 当前颜色 */
- (UIColor*)color;

@end

@protocol LFColorSliderDelegate <NSObject>

- (void)lf_colorSliderDidChangeColor:(UIColor *)color;

@end
