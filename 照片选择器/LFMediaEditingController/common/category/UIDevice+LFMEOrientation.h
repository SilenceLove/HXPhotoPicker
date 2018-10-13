//
//  UIDevice+LFOrientation.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/4/26.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIDevice (LFMEOrientation)

/**
 强制旋转设备
 
 @param orientation 旋转方向
 */
+ (void)LFME_setOrientation:(UIInterfaceOrientation)orientation;

@end
