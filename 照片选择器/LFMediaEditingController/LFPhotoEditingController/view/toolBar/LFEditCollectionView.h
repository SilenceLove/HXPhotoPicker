//
//  LFEditCollectionView.h
//  SafeAreaTest
//
//  Created by TsanFeng Lam on 2017/11/16.
//  Copyright © 2017年 TsanFeng Lam. All rights reserved.
//


#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

typedef NSString * _Nonnull (^LFEditCollectionViewDequeueReusableCellBlock)(NSIndexPath * _Nonnull indexPath);
typedef void (^LFEditCollectionViewCellConfigureBlock)(NSIndexPath * _Nonnull indexPath, id _Nonnull item, UICollectionViewCell * _Nonnull cell);
typedef void (^LFEditCollectionViewDidSelectItemAtIndexPathBlock)(NSIndexPath * _Nonnull indexPath, id _Nonnull item);

@protocol LFEditCollectionViewDelegate;

@interface LFEditCollectionView : UIView

@property (nonatomic, strong) NSArray <NSArray *> *dataSources;

- (void)callbackCellIdentifier:(LFEditCollectionViewDequeueReusableCellBlock)aCellIdentifier
                 configureCell:(LFEditCollectionViewCellConfigureBlock)aConfigureCell
      didSelectItemAtIndexPath:(LFEditCollectionViewDidSelectItemAtIndexPathBlock)aDidSelectItemAtIndexPath;


#pragma mark - UICollectionView
@property (nonatomic, strong) UICollectionViewLayout * _Nullable collectionViewLayout;
@property(nonatomic,getter=isPagingEnabled) BOOL          pagingEnabled __TVOS_PROHIBITED;// default NO. if YES, stop on multiples of view bounds
@property(nonatomic)         BOOL                         showsHorizontalScrollIndicator; // default YES. show indicator while we are tracking. fades out after tracking
@property(nonatomic)         BOOL                         showsVerticalScrollIndicator;   // default YES. show indicator while we are tracking. fades out after tracking
- (void)registerClass:(nullable Class)cellClass forCellWithReuseIdentifier:(NSString *)identifier;
- (void)registerNib:(nullable UINib *)nib forCellWithReuseIdentifier:(NSString *)identifier;

- (void)scrollToItemAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(UICollectionViewScrollPosition)scrollPosition animated:(BOOL)animated;

#pragma mark - UICollectionViewFlowLayout
@property (nonatomic) CGFloat minimumLineSpacing;
@property (nonatomic) CGFloat minimumInteritemSpacing;
@property (nonatomic) CGSize itemSize;
@property (nonatomic) CGSize estimatedItemSize NS_AVAILABLE_IOS(8_0); // defaults to CGSizeZero - setting a non-zero size enables cells that self-size via -preferredLayoutAttributesFittingAttributes:
@property (nonatomic) UICollectionViewScrollDirection scrollDirection; // default is UICollectionViewScrollDirectionVertical
@property (nonatomic) CGSize headerReferenceSize;
@property (nonatomic) CGSize footerReferenceSize;
@property (nonatomic) UIEdgeInsets sectionInset;

#pragma mark - UIScrollView
@property(nonatomic)         BOOL                         bounces;                        // default YES. if YES, bounces past edge of content and back again
@property(nullable,nonatomic,weak) id<LFEditCollectionViewDelegate>        delegate;                       // default nil. weak reference
- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated;  // animate at constant velocity to new offset
- (void)scrollRectToVisible:(CGRect)rect animated:(BOOL)animated;         // scroll so rect is just visible (nearest edges). nothing if rect completely visible

@end

@protocol LFEditCollectionViewDelegate<NSObject>

@optional
- (void)scrollViewDidScroll:(UIScrollView *)scrollView;                                               // any offset changes

// called on start of dragging (may require some time and or distance to move)
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView;
// called on finger up if the user dragged. velocity is in points/millisecond. targetContentOffset may be changed to adjust where the scroll view comes to rest
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset NS_AVAILABLE_IOS(5_0);
// called on finger up if the user dragged. decelerate is true if it will continue moving afterwards
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate;

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView;   // called on finger up as we are moving
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView;      // called when scroll view grinds to a halt
@end

NS_ASSUME_NONNULL_END
