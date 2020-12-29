//
//  HXMECancelBlock.h
//  photoEditDemo
//
//  Created by Silence on 2020/6/29.
//  Copyright © 2020 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^hx_me_dispatch_cancelable_block_t)(BOOL cancel);
OBJC_EXTERN hx_me_dispatch_cancelable_block_t hx_dispatch_block_t(NSTimeInterval delay, void(^block)(void));
OBJC_EXTERN void hx_me_dispatch_cancel(hx_me_dispatch_cancelable_block_t block);

OBJC_EXTERN double const HXMediaEditMinRate;
OBJC_EXTERN double const HXMediaEditMaxRate;

OBJC_EXTERN CGRect HXMediaEditProundRect(CGRect rect);


extern __attribute__((overloadable)) NSData * _Nullable HX_UIImagePNGRepresentation(UIImage * image);

extern __attribute__((overloadable)) NSData * _Nullable HX_UIImageJPEGRepresentation(UIImage * image);

extern __attribute__((overloadable)) NSData * _Nullable HX_UIImageRepresentation(UIImage * image, CFStringRef __nonnull type, NSError * _Nullable __autoreleasing * _Nullable error);



/**
图片解码

@param imageRef 图片
@param size 图片大小（根据大小与contentMode缩放图片，传入CGSizeZero不处理大小）
@param contentMode 内容布局（仅支持UIViewContentModeScaleAspectFill与UIViewContentModeScaleAspectFit，与size搭配）
@param orientation 图片方向（imageRef的方向，会自动更正为up，如果传入up则不更正）
@return 返回解码后的图片，如果失败，则返回NULL
*/
CG_EXTERN CGImageRef _Nullable HX_CGImageScaleDecodedFromCopy(CGImageRef imageRef, CGSize size, UIViewContentMode contentMode, UIImageOrientation orientation);

/**
图片解码

@param imageRef 图片
@return 返回解码后的图片，如果失败，则返回NULL
*/
CG_EXTERN CGImageRef _Nullable HX_CGImageDecodedFromCopy(CGImageRef imageRef);

/**
 图片解码

 @param image 图片
 @return 返回解码后的图片，如果失败，则返回NULL
 */
CG_EXTERN CGImageRef _Nullable HX_CGImageDecodedCopy(UIImage *image);

/**
 图片解码

 @param image 图片
 @return 返回解码后的图片，如果失败，则返回自身
 */
UIKIT_EXTERN UIImage * HX_UIImageDecodedCopy(UIImage *image);
NS_ASSUME_NONNULL_END
