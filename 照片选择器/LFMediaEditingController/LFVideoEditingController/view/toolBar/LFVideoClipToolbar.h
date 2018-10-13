//
//  LFVideoClipToolbar.h
//  LFMediaEditingController
//
//  Created by LamTsanFeng on 2017/7/18.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LFVideoClipToolbarDelegate;

@interface LFVideoClipToolbar : UIView

/** 代理 */
@property (nonatomic, weak) id<LFVideoClipToolbarDelegate> delegate;

@end

@protocol LFVideoClipToolbarDelegate <NSObject>

/** 取消 */
- (void)lf_videoClipToolbarDidCancel:(LFVideoClipToolbar *)clipToolbar;
/** 完成 */
- (void)lf_videoClipToolbarDidFinish:(LFVideoClipToolbar *)clipToolbar;
@end
