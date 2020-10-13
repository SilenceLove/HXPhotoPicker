//
//  HXPhotoEditResizeControl.h
//  photoEditDemo
//
//  Created by 洪欣 on 2020/6/29.
//  Copyright © 2020 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HXPhotoEditResizeControlDelegate;

@interface HXPhotoEditResizeControl : UIView
@property (weak, nonatomic) id<HXPhotoEditResizeControlDelegate> delegate;
@property (nonatomic, readonly) CGPoint translation;
@property (nonatomic, getter=isEnabled) BOOL enabled;
@end

@protocol HXPhotoEditResizeControlDelegate <NSObject>

- (void)resizeConrolDidBeginResizing:(HXPhotoEditResizeControl *)resizeConrol;
- (void)resizeConrolDidResizing:(HXPhotoEditResizeControl *)resizeConrol;
- (void)resizeConrolDidEndResizing:(HXPhotoEditResizeControl *)resizeConrol;

@end
NS_ASSUME_NONNULL_END
