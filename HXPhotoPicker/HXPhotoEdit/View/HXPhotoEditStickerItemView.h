//
//  HXPhotoEditStickerItemView.h
//  photoEditDemo
//
//  Created by Silence on 2020/6/23.
//  Copyright © 2020 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class HXPhotoEditStickerItem, HXPhotoEditStickerItemContentView, HXPhotoEditConfiguration;
@interface HXPhotoEditStickerItemView : UIView
@property (strong, nonatomic, readonly) HXPhotoEditStickerItemContentView *contentView;
/// 是否处于选中状态
@property (assign, nonatomic) BOOL isSelected;
/// 显示界面的缩放率
@property (nonatomic, assign) CGFloat screenScale;
/// 当前比例
@property (assign, nonatomic) CGFloat scale;
/// 当前弧度
@property (assign, nonatomic) CGFloat arg;
@property (assign, nonatomic) CGFloat currentItemDegrees;
@property (assign, nonatomic) BOOL firstTouch;

@property (copy, nonatomic) BOOL (^ shouldTouchBegan)(HXPhotoEditStickerItemView *view);
@property (copy, nonatomic) void (^ tapNotInScope)(HXPhotoEditStickerItemView *view, CGPoint point);
@property (nonatomic, copy, nullable) void (^ tapEnded)(HXPhotoEditStickerItemView *view);
@property (nonatomic, copy, nullable) BOOL (^ moveCenter)(CGRect rect);
@property (nonatomic, copy, nullable) CGFloat (^ getMinScale)(CGSize size);
@property (nonatomic, copy, nullable) CGFloat (^ getMaxScale)(CGSize size);
@property (nonatomic, strong, nullable) HXPhotoEditConfiguration * (^ getConfiguration)(void);

@property (copy, nonatomic) void (^ touchBegan)(HXPhotoEditStickerItemView *itemView);
@property (copy, nonatomic) void (^ touchEnded)(HXPhotoEditStickerItemView *itemView);

@property (copy, nonatomic) void (^ panChanged)(UIPanGestureRecognizer *pan);
@property (copy, nonatomic) BOOL (^ panEnded)(HXPhotoEditStickerItemView *itemView);

@property (assign, nonatomic) NSInteger mirrorType;
@property (assign, nonatomic) NSInteger superMirrorType;
@property (assign, nonatomic) NSInteger superAngle;

- (instancetype)initWithItem:(HXPhotoEditStickerItem *)item screenScale:(CGFloat)screenScale;
- (void)setScale:(CGFloat)scale;
- (void)setScale:(CGFloat)scale rotation:(CGFloat)rotation;
- (void)setScale:(CGFloat)scale rotation:(CGFloat)rotation isInitialize:(BOOL)isInitialize;
- (void)setScale:(CGFloat)scale rotation:(CGFloat)rotation isInitialize:(BOOL)isInitialize isPinch:(BOOL)isPinch setMirror:(BOOL)setMirror;
//- (void)updateItem:(HXPhotoEditStickerItem *)item;
- (void)resetRotation;
- (void)viewDidPan:(UIPanGestureRecognizer *)sender;
- (void)viewDidPinch:(UIPinchGestureRecognizer *)sender;
- (void)viewDidRotation:(UIRotationGestureRecognizer *)sender;
@end

NS_ASSUME_NONNULL_END
