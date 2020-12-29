//
//  HXPhotoView.h
//  HXPhotoPickerExample
//
//  Created by Silence on 17/2/17.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HXPhotoManager.h"
#import "HXPhotoSubViewCell.h"
#import "HXCollectionView.h"
#import "HXPhotoViewCellCustomProtocol.h"
#import "HXPhotoViewProtocol.h"

typedef NS_ENUM(NSUInteger, HXPhotoViewPreViewShowStyle) {
    HXPhotoViewPreViewShowStyleDefault, //!< 默认
    HXPhotoViewPreViewShowStyleDark     //!< 暗黑，此样式下视频会有进度条
};

@interface HXPhotoView : UIView
#pragma mark - < init >
- (instancetype)initWithFrame:(CGRect)frame
                      manager:(HXPhotoManager *)manager;
- (instancetype)initWithFrame:(CGRect)frame
                      manager:(HXPhotoManager *)manager
              scrollDirection:(UICollectionViewScrollDirection)scrollDirection;
- (instancetype)initWithManager:(HXPhotoManager *)manager;
- (instancetype)initWithManager:(HXPhotoManager *)manager
                scrollDirection:(UICollectionViewScrollDirection)scrollDirection;
+ (instancetype)photoManager:(HXPhotoManager *)manager;
+ (instancetype)photoManager:(HXPhotoManager *)manager
             scrollDirection:(UICollectionViewScrollDirection)scrollDirection;

@property (weak, nonatomic) id<HXPhotoViewDelegate> delegate;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (strong, nonatomic) HXCollectionView *collectionView;

#pragma mark - < Block >
/// 照片/视频发生改变时调用 - 选择、移动顺序、删除
@property (copy, nonatomic) HXPhotoViewChangeCompleteBlock changeCompleteBlock;
/// 点击了添加按钮的cell
@property (copy, nonatomic) HXPhotoViewDidAddCellBlock didAddCellBlock;
/// 当view高度改变时调用
@property (copy, nonatomic) HXPhotoViewUpdateFrameBlock updateFrameBlock;
/// 点击取消时调用
@property (copy, nonatomic) HXPhotoViewDidCancelBlock didCancelBlock;
/// 删除网络图片时调用
@property (copy, nonatomic) HXPhotoViewDeleteNetworkPhotoBlock deleteNetworkPhotoBlock;
/// 当前删除的模型
@property (copy, nonatomic) HXPhotoViewCurrentDeleteModelBlock currentDeleteModelBlock;
/// 长按手势结束时是否删除当前拖动的cell
@property (copy, nonatomic) HXPhotoViewShouldDeleteCurrentMoveItemBlock shouldDeleteCurrentMoveItemBlock;
/// 长按手势发生改变时调用
@property (copy, nonatomic) HXPhotoViewLongGestureRecognizerChangeBlock longGestureRecognizerChangeBlock;
/// 长按手势开始时调用
@property (copy, nonatomic) HXPhotoViewLongGestureRecognizerBeganBlock longGestureRecognizerBeganBlock;
/// 长按手势结束时调用
@property (copy, nonatomic) HXPhotoViewLongGestureRecognizerEndedBlock longGestureRecognizerEndedBlock;

#pragma mark - < Configuration >
/// 自定义cell协议
@property (weak, nonatomic) id<HXPhotoViewCellCustomProtocol> cellCustomProtocol;
/// default is UICollectionViewScrollDirectionVertical
/// 重新设置需要调用 refreshView 刷新界面
@property (assign, nonatomic) UICollectionViewScrollDirection scrollDirection;
/// 是否把相机功能放在外面 默认NO
@property (assign, nonatomic) IBInspectable BOOL outerCamera;
/// 每行个数 默认 3
/// cell的宽高取决于 每行个数 与 HXPhotoView 的宽度 和 item间距
/// cell.width = (view.width - (lineCount - 1) * spacing - contentInset.left - contentInset.right) / lineCount
/// 横向布局时 cell.width -= 10
@property (assign, nonatomic) NSInteger lineCount;
/// 每个item间距 默认 3
@property (assign, nonatomic) CGFloat spacing;
/// 隐藏cell上的删除按钮
@property (assign, nonatomic) BOOL hideDeleteButton;
/// cell是否可以长按拖动编辑
@property (assign, nonatomic) BOOL editEnabled;
/// 是否显示添加的cell 默认 YES
@property (assign, nonatomic) BOOL showAddCell;
/// 预览大图时是否显示删除按钮
@property (assign, nonatomic) BOOL previewShowDeleteButton;
/// 添加按钮的图片
@property (copy, nonatomic) NSString *addImageName;
/// 暗黑模式下添加按钮的图片
@property (copy, nonatomic) NSString *addDarkImageName;
/// 删除按钮图片
@property (copy, nonatomic) NSString *deleteImageName;
/// 预览大图时是否禁用手势返回  默认NO
@property (assign, nonatomic) BOOL disableaInteractiveTransition;
/// 是否拦截添加Cell的点击事件 默认NO
@property (assign, nonatomic) BOOL interceptAddCellClick;
/// 删除网络图片时是否显示Alert 默认NO
@property (assign, nonatomic) BOOL showDeleteNetworkPhotoAlert;
/// 删除cell时是否显示Alert 默认NO
@property (assign, nonatomic) BOOL deleteCellShowAlert;
/// 预览大图时的风格样式
@property (assign, nonatomic) HXPhotoViewPreViewShowStyle previewStyle;
/// 预览时是否显示底部pageControl，暗黑样式下才有效
@property (assign, nonatomic) BOOL previewShowBottomPageControl;
/// 底部选择视图是否自适应暗黑风格
@property (assign, nonatomic) BOOL adaptiveDarkness;
/// HXPhotoView最大高度，默认屏幕高度
@property (assign, nonatomic) CGFloat maximumHeight;
/// 跳转相册 如果需要选择相机/相册时 还是需要选择
- (void)goPhotoViewController;
/// 跳转相册 过滤掉选择 - 不管需不需要选择 直接前往相册
- (void)directGoPhotoViewController;
/// 跳转相机
- (void)goCameraViewController;
/// 删除某个模型
- (void)deleteModelWithIndex:(NSInteger)index;
/// 刷新view
- (void)refreshView;
/// 跳转预览大图的界面
- (void)jumpPreviewViewControllerWithModel:(HXPhotoModel *)model;
- (void)jumpPreviewViewControllerWithIndex:(NSInteger)index;
/// 根据坐标获取cell
/// @param point 传入的坐标是在HXPhotoView上的坐标,里面已经做了转换处理
- (HXPhotoSubViewCell *)previewingContextViewWithPoint:(CGPoint)point;
- (HXPhotoSubViewCell *)collectionViewCellWithIndex:(NSInteger)index;


#pragma mark - < other >
- (NSIndexPath *)currentModelIndexPath:(HXPhotoModel *)model;
@property (strong, nonatomic) NSIndexPath *currentIndexPath; // 自定义转场动画时用到的属性
@end
