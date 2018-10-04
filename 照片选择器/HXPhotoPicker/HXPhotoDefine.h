//
//  HXPhotoDefine.h
//  照片选择器
//
//  Created by 洪欣 on 2017/11/24.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#ifndef HXPhotoDefine_h
#define HXPhotoDefine_h

// 日志输出
#ifdef DEBUG
#define NSSLog(FORMAT, ...) fprintf(stderr,"%s:%d\t%s\n",[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
#define NSSLog(...)
#endif

#define HXEncodeKey @"HXModelArray"

#define HXShowLog YES
#define HX_UI_IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
// 判断iPhone X
#define HX_Is_iPhoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)

//判断iPHoneXr
#define HX_Is_iPhoneXR ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(828, 1792), [[UIScreen mainScreen] currentMode].size) && !HX_UI_IS_IPAD : NO)

//判断iPHoneXs
#define HX_Is_iPhoneXS ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) && !HX_UI_IS_IPAD : NO)

//判断iPhoneXs Max
#define HX_Is_iPhoneXS_MAX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1242, 2688), [[UIScreen mainScreen] currentMode].size) && !HX_UI_IS_IPAD : NO)

#define HX_IS_IPhoneX_All (HX_Is_iPhoneX || HX_Is_iPhoneXR || HX_Is_iPhoneXS || HX_Is_iPhoneXS_MAX)


// 导航栏 + 状态栏 的高度
#define hxNavigationBarHeight (HX_IS_IPhoneX_All ? 88 : 64)
#define hxTopMargin (HX_IS_IPhoneX_All ? 44 : 0)
#define hxBottomMargin (HX_IS_IPhoneX_All ? 34 : 0)

#define iOS11_Later ([UIDevice currentDevice].systemVersion.floatValue >= 11.0f)

#define iOS9Later ([UIDevice currentDevice].systemVersion.floatValue >= 9.1f)

#define iOS9_Later ([UIDevice currentDevice].systemVersion.floatValue >= 9.0f)

#define iOS8_2Later ([UIDevice currentDevice].systemVersion.floatValue >= 8.2f)

// 弱引用
#define HXWeakSelf __weak typeof(self) weakSelf = self;

CG_INLINE UIAlertController * hx_showAlert(UIViewController *vc,
                                          NSString *title,
                                          NSString *message,
                                          NSString *buttonTitle1,
                                          NSString *buttonTitle2,
                                          dispatch_block_t buttonTitle1Handler,
                                          dispatch_block_t buttonTitle2Handler) {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:buttonTitle1
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             if (buttonTitle1Handler) buttonTitle1Handler();
                                                         }];
    [alertController addAction:cancelAction];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:buttonTitle2
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * _Nonnull action) {
                                                         if (buttonTitle2Handler) buttonTitle2Handler();
                                                     }];
    [alertController addAction:okAction];
    
    [vc presentViewController:alertController animated:YES completion:nil];
    return alertController;
}

#endif /* HXPhotoDefine_h */
