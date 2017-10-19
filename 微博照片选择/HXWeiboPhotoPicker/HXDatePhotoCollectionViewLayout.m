//
//  HXDatePhotoCollectionViewLayout.m
//  微博照片选择
//
//  Created by 洪欣 on 2017/10/17.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXDatePhotoCollectionViewLayout.h"
#import "HXPhotoTools.h"
#import "HXDatePhotoPreviewBottomView.h"
#import "HXPhotoModel.h"
#import "HXDatePhotoCollectionViewLayoutAttributes.h"
@interface HXDatePhotoCollectionViewLayout ()

@end

@implementation HXDatePhotoCollectionViewLayout

- (void)prepareLayout {
    [super prepareLayout];
}
+ (Class)layoutAttributesClass {
    return [HXDatePhotoCollectionViewLayoutAttributes class];
}
- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *array = [super layoutAttributesForElementsInRect:rect];
    CGRect visibleRect;
    visibleRect.origin = self.collectionView.contentOffset;
    visibleRect.size = self.collectionView.bounds.size;
    //遍历所有布局属性
    for (HXDatePhotoCollectionViewLayoutAttributes* attributes in array) {
        //如果cell在屏幕上则进行缩放
        if (CGRectIntersectsRect(attributes.frame, rect)) {
//            HXPhotoModel *model = self.modelArray[attributes.indexPath.item];
//            CGFloat distance = CGRectGetMidX(visibleRect) - attributes.center.x;//距离中点的距离
//            CGFloat normalizedDistance = ABS(distance) / (model.dateBottomImageSize.width / 2);
//            if (!self.collectionView.dragging) {
//                if (attributes.frame.origin.x >= CGRectGetMidX(visibleRect) - self.itemSize.width && CGRectGetMaxX(attributes.frame) <= CGRectGetMidX(visibleRect) + self.itemSize.width) {
//                    NSSLog(@"%d",self.collectionView.dragging);
//                }
//            }
        }
    }
    return array;
}

/**
 *  只要显示的边界发生改变就重新布局:
 内部会重新调用prepareLayout和layoutAttributesForElementsInRect方法获得所有cell的布局属性
 */
- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}
- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity {
    CGFloat offsetAdjustment = MAXFLOAT;
    CGFloat horizontalCenter = proposedContentOffset.x + (CGRectGetWidth(self.collectionView.bounds) / 2.0);//collectionView落在屏幕中点的x坐标
    CGRect targetRect = CGRectMake(proposedContentOffset.x, 0.0, self.collectionView.bounds.size.width, self.collectionView.bounds.size.height);//collectionView落在屏幕的大小
    NSArray* array = [super layoutAttributesForElementsInRect:targetRect];//获得落在屏幕的所有cell的属性
    
    //对当前屏幕中的UICollectionViewLayoutAttributes逐个与屏幕中心进行比较，找出最接近中心的一个
    for (UICollectionViewLayoutAttributes* layoutAttributes in array) {
        CGFloat itemHorizontalCenter = layoutAttributes.center.x;
        if (ABS(itemHorizontalCenter - horizontalCenter) < ABS(offsetAdjustment)) {
            offsetAdjustment = itemHorizontalCenter - horizontalCenter;
        }
    }
    proposedContentOffset.x += offsetAdjustment;
//    NSInteger index = proposedContentOffset.x 
//    NSSLog(@"%ld",index);
    return proposedContentOffset;
}
@end
