//
//  LFTextBar.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/3/22.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LFTextBarDelegate;

@class LFText;
@interface LFTextBar : UIView

/** 需要显示的文字 */
@property (nonatomic, copy) LFText *showText;

/** 样式 */
@property (nonatomic, strong) UIColor *oKButtonTitleColorNormal;
@property (nonatomic, strong) UIColor *cancelButtonTitleColorNormal;
@property (nonatomic, copy) NSString *oKButtonTitle;
@property (nonatomic, copy) NSString *cancelButtonTitle;
@property (nonatomic, assign) CGFloat customTopbarHeight;
@property (nonatomic, assign) CGFloat naviHeight;

/** 代理 */
@property (nonatomic, weak) id<LFTextBarDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame layout:(void (^)(LFTextBar *textBar))layoutBlock;

@end

@protocol LFTextBarDelegate <NSObject>

/** 完成回调 */
- (void)lf_textBarController:(LFTextBar *)textBar didFinishText:(LFText *)text;
/** 取消回调 */
- (void)lf_textBarControllerDidCancel:(LFTextBar *)textBar;

@end
