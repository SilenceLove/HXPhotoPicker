//
//  HXPhotoEditStickerView.m
//  photoEditDemo
//
//  Created by 洪欣 on 2020/6/23.
//  Copyright © 2020 洪欣. All rights reserved.
//

#import "HXPhotoEditStickerView.h"
#import "HXPhotoEditStickerItem.h"
#import "HXPhotoEditStickerItemView.h"
#import "HXPhotoEditStickerItemContentView.h"
#import "HXPhotoDefine.h"
#import "HXPhotoEditStickerTrashView.h"
#import "UIView+HXExtension.h"
#import "HXPhotoEditTextView.h"
#import <AudioToolbox/AudioToolbox.h>
#import "HXPhotoClippingView.h"

NSString *const kHXStickerViewData_movingView = @"HXStickerViewData_movingView";

NSString *const kHXStickerViewData_movingView_content = @"HXStickerViewData_movingView_content";
NSString *const kHXStickerViewData_movingView_center = @"HXStickerViewData_movingView_center";
NSString *const kHXStickerViewData_movingView_scale = @"HXStickerViewData_movingView_scale";
NSString *const kHXStickerViewData_movingView_rotation = @"HXStickerViewData_movingView_rotation";

@interface HXPhotoEditStickerView ()
@property (weak, nonatomic) HXPhotoEditStickerItemView *selectItemView;
@property (strong, nonatomic) HXPhotoEditStickerTrashView *transhView;
@property (assign, nonatomic) BOOL hasImpactFeedback;
@property (assign, nonatomic) BOOL addWindowCompletion;
@property (assign, nonatomic) BOOL transhViewIsVisible;
@property (assign, nonatomic) BOOL transhViewDidRemove;
@property (assign, nonatomic) BOOL touching;
@property (assign, nonatomic) CGFloat currentItemDegrees;
@end

@implementation HXPhotoEditStickerView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        self.userInteractionEnabled = YES;
        _screenScale = 1;
    }
    return self;
}
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if (self.touching) {
        return view;
    }
    if ([view isKindOfClass:[HXPhotoEditStickerItemContentView class]]) {
        if (self.selectItemView) {
            CGRect rect = self.selectItemView.frame;
            // 贴图事件范围增大，便于在过小情况下可以放大
            // 手势逻辑不够完美，后期优化
            rect = CGRectMake(rect.origin.x - 35, rect.origin.y - 35, rect.size.width + 70, rect.size.height + 70);
            if (CGRectContainsPoint(rect, point)) {
                self.hitTestSubView = YES;
                return self.selectItemView.contentView;
            }
        }
        HXPhotoEditStickerItemView *itemView = (HXPhotoEditStickerItemView *)view.superview;
        if (itemView != self.selectItemView) {
            self.selectItemView.isSelected = NO;
            self.selectItemView = nil;
        }
        itemView.isSelected = YES;
        [self bringSubviewToFront:itemView];
        self.selectItemView = itemView;
    }else {
        if (self.selectItemView) {
            CGRect rect = self.selectItemView.frame;
            // 贴图事件范围增大，便于在过小情况下可以放大
            // 手势逻辑不够完美，后期优化
            rect = CGRectMake(rect.origin.x - 35, rect.origin.y - 35, rect.size.width + 70, rect.size.height + 70);
            if (CGRectContainsPoint(rect, point)) {
                self.hitTestSubView = YES;
                return self.selectItemView.contentView;
            }
        }
        self.selectItemView.isSelected = NO;
        self.selectItemView = nil;
    }
    self.hitTestSubView = [view isDescendantOfView:self];
    return (view == self ? nil : view);
}
- (HXPhotoEditStickerItemView *)addStickerItem:(HXPhotoEditStickerItem *)item isSelected:(BOOL)selected {
    self.selectItemView.isSelected = NO;
    HXPhotoEditStickerItemView *itemView = [[HXPhotoEditStickerItemView alloc] initWithItem:item screenScale:self.screenScale];
    HXWeakSelf
    itemView.getConfiguration = ^HXPhotoEditConfiguration * _Nonnull{
        return weakSelf.configuration;
    };
    if (self.moveCenter) {
        itemView.moveCenter = ^BOOL(CGRect rect) {
            return weakSelf.moveCenter(rect);
        };
    }
    itemView.shouldTouchBegan = ^BOOL(HXPhotoEditStickerItemView * _Nonnull view) {
        if (weakSelf.selectItemView && view != weakSelf.selectItemView) {
            return NO;
        }
        return YES;
    };
    itemView.tapNotInScope = ^(HXPhotoEditStickerItemView * _Nonnull view, CGPoint point) {
        if (weakSelf.selectItemView == view) {
            weakSelf.selectItemView = nil;
            point = [view convertPoint:point toView:weakSelf];
            for (HXPhotoEditStickerItemView *itemView in weakSelf.subviews) {
                if ([itemView isKindOfClass:[HXPhotoEditStickerItemView class]]) {
                    if (CGRectContainsPoint(itemView.frame, point)) {
                        itemView.isSelected = YES;
                        weakSelf.selectItemView = itemView;
                        [weakSelf bringSubviewToFront:itemView];
                        return;
                    }
                }
            }
        }
    };
    itemView.touchBegan = ^(HXPhotoEditStickerItemView * _Nonnull itemView) {
        weakSelf.touching = YES;
        if (weakSelf.touchBegan) {
            weakSelf.touchBegan(itemView);
        }
        if (!weakSelf.selectItemView) {
            weakSelf.selectItemView =  itemView;
        }else if (weakSelf.selectItemView != itemView) {
            weakSelf.selectItemView.isSelected = NO;
            weakSelf.selectItemView =  itemView;
        }
        if (!weakSelf.addWindowCompletion) {
            [weakSelf windowAddItemView:itemView];
        }
        if (!weakSelf.transhViewIsVisible) {
            weakSelf.transhViewIsVisible = YES;
            [[UIApplication sharedApplication].keyWindow addSubview:weakSelf.transhView];
            [weakSelf showTranshView];
        }
    };
    itemView.panChanged = ^(UIPanGestureRecognizer * _Nonnull pan) {
        if (!weakSelf.transhViewDidRemove) {
            if (!weakSelf.transhViewIsVisible) {
                weakSelf.transhViewIsVisible = YES;
                [[UIApplication sharedApplication].keyWindow addSubview:weakSelf.transhView];
                [weakSelf showTranshView];
            }else {
                if (weakSelf.transhView.hx_y != HX_ScreenHeight - hxBottomMargin - 20 - weakSelf.transhView.hx_h ||
                    weakSelf.transhView.alpha == 0) {
                    [weakSelf showTranshView];
                }else if (!weakSelf.transhView.superview) {
                    [[UIApplication sharedApplication].keyWindow addSubview:weakSelf.transhView];
                    [weakSelf showTranshView];
                }
            }
        }
        CGPoint point = [pan locationInView:[UIApplication sharedApplication].keyWindow];
        if (CGRectContainsPoint(weakSelf.transhView.frame, point) && !weakSelf.transhViewDidRemove) {
            weakSelf.transhView.inArea = YES;
            if (!weakSelf.hasImpactFeedback) {
                [UIView animateWithDuration:0.2 animations:^{
                    weakSelf.selectItemView.alpha = 0.4;
                }];
                [weakSelf performSelector:@selector(hideTranshView) withObject:nil afterDelay:1.2f];
                if (@available(iOS 10.0, *)){
                    UIImpactFeedbackGenerator *feedBackGenertor = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
                    [feedBackGenertor impactOccurred];
                }
                weakSelf.hasImpactFeedback = YES;
            }
        }else {
            [UIView animateWithDuration:0.2 animations:^{
                weakSelf.selectItemView.alpha = 1.f;
            }];
            [UIView cancelPreviousPerformRequestsWithTarget:weakSelf];
            weakSelf.hasImpactFeedback = NO;
            weakSelf.transhView.inArea = NO;
        }
    };
    itemView.panEnded = ^BOOL(HXPhotoEditStickerItemView * _Nonnull itemView) {
        BOOL inArea = weakSelf.transhView.inArea;
        if (inArea) {
            weakSelf.addWindowCompletion = NO;
            weakSelf.transhView.inArea = NO;
            [UIView animateWithDuration:0.25 animations:^{
                itemView.alpha = 0;
            } completion:^(BOOL finished) {
                [itemView removeFromSuperview];
            }];
            weakSelf.selectItemView = nil;
        }else {
            if (!weakSelf.selectItemView) {
                weakSelf.selectItemView =  itemView;
            }else if (weakSelf.selectItemView != itemView) {
                weakSelf.selectItemView.isSelected = NO;
                weakSelf.selectItemView =  itemView;
            }
            if (weakSelf.addWindowCompletion) {
                weakSelf.addWindowCompletion = NO;
                CGRect rect = [[UIApplication sharedApplication].keyWindow convertRect:itemView.frame toView:weakSelf];
                itemView.frame = rect;
                [weakSelf addSubview:itemView];
                [itemView setScale:itemView.scale rotation:itemView.arg + weakSelf.currentItemDegrees];
            }
        }
        if (weakSelf.addWindowCompletion) {
            [weakSelf hideTranshView];
        }
        return inArea;
    };
    itemView.touchEnded = ^(HXPhotoEditStickerItemView * _Nonnull itemView) {
        if (weakSelf.touchEnded) {
            weakSelf.touchEnded(itemView);
        }
        if (!weakSelf.selectItemView) {
            weakSelf.selectItemView =  itemView;
        }else if (weakSelf.selectItemView != itemView) {
            weakSelf.selectItemView.isSelected = NO;
            weakSelf.selectItemView =  itemView;
        }
        if (weakSelf.addWindowCompletion) {
            weakSelf.addWindowCompletion = NO;
            CGRect rect = [[UIApplication sharedApplication].keyWindow convertRect:itemView.frame toView:weakSelf];
            itemView.frame = rect;
            [weakSelf addSubview:itemView];
            [itemView setScale:itemView.scale rotation:itemView.arg + weakSelf.currentItemDegrees];
        }
        if (weakSelf.transhView.alpha == 1) {
            [weakSelf hideTranshView];
        }
        weakSelf.touching = NO;
    };
    /** 屏幕缩放率 */
    itemView.screenScale = self.screenScale;
    itemView.getMinScale = self.getMinScale;
    itemView.getMaxScale = self.getMaxScale;
    CGFloat scale;
    if (!item.textModel) {
        CGFloat ratio = 0.5f;
        CGFloat width = self.hx_w * self.screenScale;
        CGFloat height = self.hx_h * self.screenScale;
        if (width > HX_ScreenWidth) {
            width = HX_ScreenWidth;
        }
        if (height > HX_ScreenHeight) {
            height = HX_ScreenHeight;
        }
        scale = MIN( (ratio * width) / itemView.frame.size.width, (ratio * height) / itemView.frame.size.height);
    }else {
        scale = MIN( MIN(self.hx_w  * self.screenScale - 40, itemView.hx_w) / itemView.hx_w , MIN(self.hx_h * self.screenScale - 40, itemView.hx_h) / itemView.hx_h);
    }
    UIView *clippingView = self.superview.superview;
    // 旋转后，需要处理弧度的变化
    CGFloat radians = atan2f(clippingView.transform.b, clippingView.transform.a);
    if ((radians > 0 && radians < M_PI) || (radians < 0 && radians > -M_PI)) {
        radians = -radians;
    }
    itemView.arg = radians;
    
    [itemView setScale:scale / self.screenScale];

    itemView.isSelected = selected;
    itemView.center = [self convertPoint:[UIApplication sharedApplication].keyWindow.center fromView:(UIView *)[UIApplication sharedApplication].keyWindow];
    itemView.firstTouch = selected;
    [self addSubview:itemView];
    if (selected) {
        self.selectItemView = itemView;
    }
    return itemView;
}
- (void)windowAddItemView:(HXPhotoEditStickerItemView *)itemView {
    self.addWindowCompletion = YES;
    UIView *clippingView = self.superview.superview;
    // 旋转后，需要处理弧度的变化
    CGFloat radians = atan2f(clippingView.transform.b, clippingView.transform.a);
    if ((radians > 0 && radians < M_PI) || (radians < 0 && radians > -M_PI)) {
        self.currentItemDegrees = -radians;
    }else {
        self.currentItemDegrees = radians;
    }
    CGRect rect = [self convertRect:itemView.frame toView:[UIApplication sharedApplication].keyWindow];
    itemView.frame = rect;
    [[UIApplication sharedApplication].keyWindow addSubview:itemView];
    [itemView setScale:itemView.scale rotation:itemView.arg - self.currentItemDegrees];
}
- (HXPhotoEditStickerTrashView *)transhView {
    if (!_transhView) {
        _transhView = [HXPhotoEditStickerTrashView initView];
        _transhView.hx_size = CGSizeMake(160, 70);
        _transhView.hx_centerX = HX_ScreenWidth / 2;
        _transhView.hx_y = HX_ScreenHeight;
        _transhView.alpha = 0;
    }
    return _transhView;
}
- (void)showTranshView {
    self.transhViewDidRemove = NO;
    [UIView animateWithDuration:0.25 animations:^{
        self.transhView.hx_y = HX_ScreenHeight - hxBottomMargin - 20 - self.transhView.hx_h;
        self.transhView.alpha = 1;
    }];
}
- (void)hideTranshView {
    self.transhViewIsVisible = NO;
    self.transhViewDidRemove = YES;
    [UIView animateWithDuration:0.25 animations:^{
        self.transhView.hx_y = HX_ScreenHeight;
        self.transhView.alpha = 0;
    } completion:^(BOOL finished) {
        [self.transhView removeFromSuperview];
        self.transhView.inArea = NO;
    }];
}

- (BOOL)isEnable {
    return self.isHitTestSubView && self.selectItemView.isSelected;
}
- (void)removeSelectItem {
    self.selectItemView.isSelected = NO;
    self.selectItemView = nil;
}
/** 贴图数量 */
- (NSUInteger)count {
    return self.subviews.count;
}
- (void)setScreenScale:(CGFloat)screenScale {
    if (screenScale > 0) {
        _screenScale = screenScale;
        for (HXPhotoEditStickerItemView *subView in self.subviews) {
            if ([subView isKindOfClass:[HXPhotoEditStickerItemView class]]) {
                subView.screenScale = screenScale;
            }
        }
    }
}
- (void)setMoveCenter:(BOOL (^)(CGRect))moveCenter {
    _moveCenter = moveCenter;
    for (HXPhotoEditStickerItemView *subView in self.subviews) {
        if ([subView isKindOfClass:[HXPhotoEditStickerItemView class]]) {
            if (moveCenter) {
                HXWeakSelf
                [subView setMoveCenter:^BOOL (CGRect rect) {
                    return weakSelf.moveCenter(rect);
                }];
            } else {
                [subView setMoveCenter:nil];
            }
        }
    }
}
- (void)clearCoverage {
    [self.subviews performSelector:@selector(removeFromSuperview)];
    [self.selectItemView removeFromSuperview];
}
#pragma mark  - 数据
- (NSDictionary *)data {
    NSMutableArray *itemDatas = [@[] mutableCopy];
    for (HXPhotoEditStickerItemView *view in self.subviews) {
        if ([view isKindOfClass:[HXPhotoEditStickerItemView class]]) {

            [itemDatas addObject:@{kHXStickerViewData_movingView_content:view.contentView.item
                                     , kHXStickerViewData_movingView_scale:@(view.scale)
                                     , kHXStickerViewData_movingView_rotation:@(view.arg)
                                     , kHXStickerViewData_movingView_center:[NSValue valueWithCGPoint:view.center]
                                     }];
        }
    }
    if (itemDatas.count) {
        return @{kHXStickerViewData_movingView:[itemDatas copy]
        };
    }
    return nil;
}

- (void)setData:(NSDictionary *)data {
    NSArray *itemDatas = data[kHXStickerViewData_movingView];
    if (itemDatas.count) {
        for (NSDictionary *itemData in itemDatas) {
            HXPhotoEditStickerItem *item = itemData[kHXStickerViewData_movingView_content];
            CGFloat scale = [itemData[kHXStickerViewData_movingView_scale] floatValue];
            CGFloat rotation = [itemData[kHXStickerViewData_movingView_rotation] floatValue];
            CGPoint center = [itemData[kHXStickerViewData_movingView_center] CGPointValue];
            
            HXPhotoEditStickerItemView *view = [self addStickerItem:item isSelected:NO];
            [view setScale:scale rotation:rotation isInitialize:YES];
            view.center = center;
        }
    }
}
@end
