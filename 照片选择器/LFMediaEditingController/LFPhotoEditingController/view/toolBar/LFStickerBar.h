//
//  LFStickerBar.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/3/21.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

extern CGFloat const lf_stickerSize;
extern CGFloat const lf_stickerMargin;

@protocol LFStickerBarDelegate;

@interface LFStickerBar : UIView;

@property (nonatomic, weak) id <LFStickerBarDelegate> delegate;


/**
 初始化 指定贴图资源目录

 @param frame 位置
 @param resourcePath 资源目录
 @return self
 */
- (instancetype)initWithFrame:(CGRect)frame resourcePath:(NSString *)resourcePath;

@end

@protocol LFStickerBarDelegate <NSObject>

- (void)lf_stickerBar:(LFStickerBar *)lf_stickerBar didSelectImage:(UIImage *)image;

@end
