//
//  HXDatePhotoViewFlowLayout.m
//  微博照片选择
//
//  Created by 洪欣 on 2017/11/15.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXDatePhotoViewFlowLayout.h"
#import "HXDatePhotoViewController.h"
@interface HXDatePhotoViewFlowLayout ()
@property (assign, nonatomic) BOOL hasSuspension;
@end

@implementation HXDatePhotoViewFlowLayout

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *array = [super layoutAttributesForElementsInRect:rect];
    NSMutableArray *answer = [array mutableCopy];
    
    UICollectionView * const cv = self.collectionView;
    CGPoint const contentOffset = cv.contentOffset;

    NSMutableIndexSet *missingSections = [NSMutableIndexSet indexSet];
    for (UICollectionViewLayoutAttributes *layoutAttributes in answer) {
        if (layoutAttributes.representedElementCategory == UICollectionElementCategoryCell) {
            [missingSections addIndex:layoutAttributes.indexPath.section];
        }
    }
    for (UICollectionViewLayoutAttributes *layoutAttributes in answer) {
        if ([layoutAttributes.representedElementKind isEqualToString:UICollectionElementKindSectionHeader]) {
            [missingSections removeIndex:layoutAttributes.indexPath.section];
        }
    }

    [missingSections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:idx];
        UICollectionViewLayoutAttributes *layoutAttributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:indexPath];

        [answer addObject:layoutAttributes];
    }];
    
    for (UICollectionViewLayoutAttributes *layoutAttributes in answer) {
        if ([layoutAttributes.representedElementKind isEqualToString:UICollectionElementKindSectionHeader]) {
            
            NSInteger section = layoutAttributes.indexPath.section;
            NSInteger numberOfItemsInSection = [cv numberOfItemsInSection:section];
            
            NSIndexPath *firstObjectIndexPath = [NSIndexPath indexPathForItem:0 inSection:section];
            NSIndexPath *lastObjectIndexPath = [NSIndexPath indexPathForItem:MAX(0, (numberOfItemsInSection - 1)) inSection:section];
            
            UICollectionViewLayoutAttributes *firstObjectAttrs;
            UICollectionViewLayoutAttributes *lastObjectAttrs;
            
            if (numberOfItemsInSection > 0) {
                firstObjectAttrs = [self layoutAttributesForItemAtIndexPath:firstObjectIndexPath];
                lastObjectAttrs = [self layoutAttributesForItemAtIndexPath:lastObjectIndexPath];
            } else {
                firstObjectAttrs = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:firstObjectIndexPath];
                lastObjectAttrs = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter atIndexPath:lastObjectIndexPath];
            }
            
            CGFloat headerHeight = CGRectGetHeight(layoutAttributes.frame);
            CGPoint origin = layoutAttributes.frame.origin;
            CGFloat topY = contentOffset.y + cv.contentInset.top;
            CGFloat normalY = (CGRectGetMinY(firstObjectAttrs.frame) - headerHeight);
            CGFloat missingY = (CGRectGetMaxY(lastObjectAttrs.frame) - headerHeight);
            
            CGFloat max = MAX(topY, normalY);
            CGFloat min = MIN(max, missingY);
            
            if (topY >= normalY && topY <= missingY + headerHeight) {
                if (iOS9_Later) {
                    HXDatePhotoViewSectionHeaderView *headerView = (HXDatePhotoViewSectionHeaderView *)[cv supplementaryViewForElementKind:UICollectionElementKindSectionHeader atIndexPath:layoutAttributes.indexPath];
                    if (headerView) {
                        headerView.changeState = YES;
                    }
                }
                self.hasSuspension = YES;
            }else {
                if (iOS9_Later) {
                    HXDatePhotoViewSectionHeaderView *headerView = (HXDatePhotoViewSectionHeaderView *)[cv supplementaryViewForElementKind:UICollectionElementKindSectionHeader atIndexPath:layoutAttributes.indexPath];
                    if (headerView) {
                        headerView.changeState = NO;
                    }
                }
                self.hasSuspension = NO;
            }
            if (origin.y != min && self.hasSuspension) {
                origin.y = min;
                layoutAttributes.zIndex = 1024;
                layoutAttributes.frame = (CGRect){
                    .origin = origin,
                    .size = layoutAttributes.frame.size
                };
            }
        }
    }
    return answer;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}

@end
