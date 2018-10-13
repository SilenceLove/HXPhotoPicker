//
//  LFStickerLabel.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/4/6.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>
@class LFText;

@interface LFStickerLabel : UIView

@property (nonatomic, assign) UIEdgeInsets textInsets; // 控制字体与控件边界的间隙
/** 设置该值会重置frame.size */
@property (nonatomic, strong) LFText *lf_text;
@property (nonatomic, readonly) CGSize textSize;

- (void)drawText;
@end
