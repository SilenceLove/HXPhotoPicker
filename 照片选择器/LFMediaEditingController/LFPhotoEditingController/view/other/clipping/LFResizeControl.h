//
//  LFResizeControl.h
//  ClippingText
//
//  Created by LamTsanFeng on 2017/3/7.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol lf_resizeConrolDelegate;

@interface LFResizeControl : UIView

@property (weak, nonatomic) id<lf_resizeConrolDelegate> delegate;
@property (nonatomic, readonly) CGPoint translation;

@end

@protocol lf_resizeConrolDelegate <NSObject>

- (void)lf_resizeConrolDidBeginResizing:(LFResizeControl *)resizeConrol;
- (void)lf_resizeConrolDidResizing:(LFResizeControl *)resizeConrol;
- (void)lf_resizeConrolDidEndResizing:(LFResizeControl *)resizeConrol;

@end
