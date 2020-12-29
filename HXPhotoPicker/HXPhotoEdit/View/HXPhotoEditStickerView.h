//
//  HXPhotoEditStickerView.h
//  photoEditDemo
//
//  Created by Silence on 2020/6/23.
//  Copyright © 2020 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class HXPhotoEditStickerItem, HXPhotoEditStickerItemView, HXPhotoEditConfiguration;
@interface HXPhotoEditStickerView : UIView

@property (weak, nonatomic, readonly) HXPhotoEditStickerItemView *selectItemView;
@property (copy, nonatomic) void (^ touchBegan)(HXPhotoEditStickerItemView *itemView);
@property (copy, nonatomic) void (^ touchEnded)(HXPhotoEditStickerItemView *itemView);

@property (strong, nonatomic) HXPhotoEditConfiguration *configuration;
/** 贴图数量 */
@property (nonatomic, readonly) NSUInteger count;
/// 显示界面的缩放率
@property (nonatomic, assign) CGFloat screenScale;
/** 是否启用（移动或点击） */
@property (nonatomic, readonly, getter=isEnable) BOOL enable;
@property (nonatomic, copy, nullable) BOOL (^ moveCenter)(CGRect rect);
@property (nonatomic, copy, nullable) CGFloat (^ getMinScale)(CGSize size);
@property (nonatomic, copy, nullable) CGFloat (^ getMaxScale)(CGSize size);

/** 数据 */
@property (nonatomic, strong, nullable) NSDictionary *data;
@property (assign, nonatomic, getter=isHitTestSubView) BOOL hitTestSubView;
- (HXPhotoEditStickerItemView *)addStickerItem:(HXPhotoEditStickerItem *)item isSelected:(BOOL)selected;

@property (assign, nonatomic) NSInteger angle;
@property (assign, nonatomic) NSInteger mirrorType;

- (void)removeSelectItem;
- (void)clearCoverage;
@end

NS_ASSUME_NONNULL_END
