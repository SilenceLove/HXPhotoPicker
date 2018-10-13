//
//  LFZoomingView.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/3/16.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LFEditingProtocol.h"

@interface LFZoomingView : UIView <LFEditingProtocol>

@property (nonatomic, strong) UIImage *image;

@property (nonatomic, assign, getter=isImageViewHidden) BOOL imageViewHidden;

/** 贴图是否需要移到屏幕中心 */
@property (nonatomic, copy) BOOL(^moveCenter)(CGRect rect);
@end

