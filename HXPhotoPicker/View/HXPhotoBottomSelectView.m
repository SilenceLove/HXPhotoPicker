//
//  HXPhotoBottomSelectView.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2019/9/30.
//  Copyright © 2019 Silence. All rights reserved.
//

#import "HXPhotoBottomSelectView.h"
#import "HXPhotoCommon.h"
#import "HXPhotoDefine.h"
#import "UIView+HXExtension.h"
#import "UIFont+HXExtension.h"
#import "UIColor+HXExtension.h"
#import "UILabel+HXExtension.h"
#import "NSBundle+HXPhotoPicker.h"
#import "HXPreviewVideoView.h"
#import "UIImage+HXExtension.h"
#import "HXAlbumlistView.h"

@implementation HXPhotoBottomViewModel
- (instancetype)init {
    self = [super init];
    if (self) {
        self.canSelect = YES;
    }
    return self;
}
- (UIColor *)backgroundColor {
    if (!_backgroundColor) {
        _backgroundColor = [UIColor whiteColor];
    }
    return _backgroundColor;
}
- (UIColor *)titleColor {
    if (!_titleColor) {
        _titleColor = [UIColor colorWithRed:32.f/255.f green:32.f/255.f blue:32.f/255.f alpha:1];
    }
    return _titleColor;
}
- (UIColor *)titleDarkColor {
    if (!_titleDarkColor) {
        _titleDarkColor = [UIColor whiteColor];
    }
    return _titleDarkColor;
}
- (UIColor *)subTitleColor {
    if (!_subTitleColor) {
        _subTitleColor = [UIColor hx_colorWithHexStr:@"#999999"];
    }
    return _subTitleColor;
}
- (UIColor *)subTitleDarkColor {
    if (!_subTitleDarkColor) {
        _subTitleDarkColor = [[UIColor whiteColor] colorWithAlphaComponent:0.8f];
    }
    return _subTitleDarkColor;
}
- (UIColor *)lineColor {
    if (!_lineColor) {
        _lineColor = [UIColor colorWithRed:0.93 green:0.93 blue:0.93 alpha:1];
    }
    return _lineColor;
}
- (UIColor *)selectColor {
    if (!_selectColor) {
        _selectColor = [UIColor hx_colorWithHexStr:@"#E5E5E5"];
    }
    return _selectColor;
}
- (UIFont *)titleFont {
    if (!_titleFont) {
        _titleFont = [UIFont hx_helveticaNeueOfSize:17];
    }
    return _titleFont;
}
- (UIFont *)subTitleFont {
    if (!_subTitleFont) {
        _subTitleFont = [UIFont hx_helveticaNeueOfSize:13];
    }
    return _subTitleFont;
}
- (CGFloat)cellHeight {
    if (_cellHeight <= 0) {
        _cellHeight = 55.f;
    }
    return _cellHeight;
}
@end

@interface HXPhotoBottomSelectView ()<UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UIView *footerCancelView;
@property (strong, nonatomic) HXAlbumTitleButton *cancelBtn;
@property (strong, nonatomic) UIView *bgView;
@property (strong, nonatomic) UIView *contentView;
@property (strong, nonatomic) UIView *topView;
@property (strong, nonatomic) UIView *lineView;
@property (assign, nonatomic) BOOL showViewCompletion;
@property (strong, nonatomic) HXPanGestureRecognizer *panGesture;
@property (assign, nonatomic) CGFloat centerY;
@property (assign, nonatomic) CGFloat contentViewHeight;
@property (assign, nonatomic) CGFloat tableViewHeight;
@property (assign, nonatomic) CGFloat panPointY;
@property (assign, nonatomic) CGFloat locationPointY;
@property (assign, nonatomic) BOOL canPanGesture;
@property (assign, nonatomic) BOOL tableViewDidScroll;
@property (strong, nonatomic) HXPhotoBottomSelectViewCell *currentSelectCell;
@property (assign, nonatomic) BOOL shouldHidden;
@end

@implementation HXPhotoBottomSelectView

/// 显示底部选择视图
/// @param models 模型数组
/// @param headerView tableViewHeaderView
/// @param showTopLineView 显示可拖动隐藏的视图
/// @param cancelTitle 取消按钮标题
/// @param selectCompletion 选择完成
/// @param cancelClick 取消选择
+ (instancetype)showSelectViewWithModels:(NSArray * _Nullable)models
                              headerView:(UIView * _Nullable)headerView
                         showTopLineView:(BOOL)showTopLineView
                             cancelTitle:(NSString * _Nullable)cancelTitle
                        selectCompletion:(void (^ _Nullable)(NSInteger index, HXPhotoBottomViewModel *model))selectCompletion
                             cancelClick:(void (^ _Nullable)(void))cancelClick {
    HXPhotoBottomSelectView *selectView = [[HXPhotoBottomSelectView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    selectView.tableHeaderView = headerView;
    selectView.adaptiveDarkness = YES;
    selectView.cancelTitle = cancelTitle;
    selectView.selectCompletion = selectCompletion;
    selectView.cancelClick = cancelClick;
    selectView.showTopLineView = showTopLineView;
    selectView.modelArray = models;
    [[UIApplication sharedApplication].keyWindow addSubview:selectView];
    [selectView showView];
    return selectView;
}
+ (instancetype)showSelectViewWithModels:(NSArray *)models
                              headerView:(UIView *)headerView
                             cancelTitle:(NSString *)cancelTitle
                        selectCompletion:(void (^)(NSInteger, HXPhotoBottomViewModel * _Nonnull))selectCompletion
                             cancelClick:(void (^)(void))cancelClick {
    return [self showSelectViewWithModels:models headerView:headerView showTopLineView:NO cancelTitle:cancelTitle selectCompletion:selectCompletion cancelClick:cancelClick];
}
+ (instancetype)showSelectViewWithModels:(NSArray * _Nullable)models
                        selectCompletion:(void (^ _Nullable)(NSInteger index, HXPhotoBottomViewModel *model))selectCompletion
                             cancelClick:(void (^ _Nullable)(void))cancelClick {
    return [self showSelectViewWithModels:models headerView:nil showTopLineView:NO cancelTitle:nil selectCompletion:selectCompletion cancelClick:cancelClick];
}
+ (instancetype)showSelectViewWithTitles:(NSArray *)titles
                        selectCompletion:(void (^)(NSInteger, HXPhotoBottomViewModel * _Nonnull))selectCompletion
                             cancelClick:(void (^)(void))cancelClick {
    NSMutableArray *models = [NSMutableArray array];
    for (NSString *title in titles) {
        HXPhotoBottomViewModel *model = [[HXPhotoBottomViewModel alloc] init];
        model.title = title;
        [models addObject:model];
    }
    return [self showSelectViewWithModels:models headerView:nil showTopLineView:NO cancelTitle:nil selectCompletion:selectCompletion cancelClick:cancelClick];
}
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.showViewCompletion = NO;
        self.tableViewDidScroll = NO;
        self.panPointY = 0;
        self.locationPointY = 0;
        self.shouldHidden = NO;
        self.panGesture = [[HXPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureReconClick:)];
        self.panGesture.delegate = self;
        self.panGesture.cancelsTouchesInView = NO;
        [self.contentView addGestureRecognizer:self.panGesture];
        
        [self addSubview:self.bgView];
        [self addSubview:self.contentView];
        if (HX_IOS11_Later) {
            [self.contentView hx_radiusWithRadius:10 corner:UIRectCornerTopLeft | UIRectCornerTopRight];
            [self.tableView hx_radiusWithRadius:10 corner:UIRectCornerTopLeft | UIRectCornerTopRight];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    }
    return self;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isKindOfClass:[UIButton class]]) {
        return NO;
    }
    return YES;
}
- (void)panGestureReconClick:(UIPanGestureRecognizer *)panGesture {
    CGPoint point = [panGesture translationInView:self.contentView];
    if (self.shouldHidden) {
        return;
    }
    if (panGesture.state == UIGestureRecognizerStateBegan) {
        self.tableViewDidScroll = NO;
        self.contentView.hx_centerY = self.centerY + point.y;
        CGPoint locationPoint = [panGesture locationInView:self.contentView];
        self.locationPointY = locationPoint.y;
        if (self.currentSelectCell) {
            self.currentSelectCell.showSelectBgView = NO;
        }
        if (locationPoint.y >= 15) {
            CGPoint convertPoint = [self.tableView convertPoint:locationPoint fromView:self.contentView];
            NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:convertPoint];
            if (indexPath) {
                self.currentSelectCell = (HXPhotoBottomSelectViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                self.currentSelectCell.showSelectBgView = YES;
            }
        }
        self.canPanGesture = locationPoint.y <= 15;
    }else if (panGesture.state == UIGestureRecognizerStateChanged) {
        if (!self.tableViewDidScroll && self.tableView.contentOffset.y <= 0 && self.tableView.tracking) {
            if (point.y<= 0) {
                return;
            }
        }
        if (self.currentSelectCell) {
            CGPoint locationPoint = [panGesture locationInView:self.contentView];
            CGPoint convertPoint = [self.tableView convertPoint:locationPoint fromView:self.contentView];
            if (CGRectContainsPoint(self.currentSelectCell.frame, convertPoint)) {
                self.currentSelectCell.showSelectBgView = YES;
            }else {
                self.currentSelectCell.showSelectBgView = NO;
            }
        }
        if (self.tableView.contentOffset.y > 0 && !self.canPanGesture) {
            CGFloat y = self.hx_h - self.contentView.hx_h;
            self.contentView.hx_y = y;
            self.panPointY = point.y;
            return;
        }else {
            point.y -= self.panPointY;
        }
        CGFloat y = self.hx_h - self.contentViewHeight;
        CGFloat contentViewCenterY = self.centerY + point.y;
        if (self.locationPointY > 15) {
            if (contentViewCenterY < self.contentViewHeight / 2 + y) {
                contentViewCenterY = self.contentViewHeight / 2 + y;
            }
        }
        self.contentView.hx_centerY = contentViewCenterY;
        CGFloat scale = (self.contentView.hx_y - y) / self.contentViewHeight;
        self.bgView.alpha = 1 - scale;
        if (self.contentView.hx_y < y && self.locationPointY <= 15) {
            CGFloat distance = point.y * 0.15;
            if (distance < -60) {
                distance = -60;
            }
            self.contentView.hx_centerY = self.centerY + distance;
            CGFloat margin = y - self.contentView.hx_y;
            self.contentView.hx_h = self.contentViewHeight + margin;
            self.tableView.hx_h = self.tableViewHeight + margin;
        }else {
            self.tableView.hx_h = self.tableViewHeight;
        }
        self.footerCancelView.hx_y = CGRectGetMaxY(self.tableView.frame) + 8.f;
    }else if (panGesture.state == UIGestureRecognizerStateEnded ||
              panGesture.state == UIGestureRecognizerStateCancelled) {
        self.tableViewDidScroll = NO;
        self.centerY = self.contentView.hx_centerY;
        if (self.hx_h - self.contentView.hx_y < self.contentViewHeight / 4 * 3) {
            [self hideView];
        }else {
            [self resetContentViewFrame];
        }
        self.panPointY = 0;
        self.locationPointY = 0;
        self.canPanGesture = YES;
        if (self.currentSelectCell) {
            self.currentSelectCell.showSelectBgView = NO;
            self.currentSelectCell = nil;
        }
    }else {
        if (self.currentSelectCell) {
            self.currentSelectCell.showSelectBgView = NO;
            self.currentSelectCell = nil;
        }
    }
}
- (void)deviceOrientationChanged:(NSNotification *)notify {
    [self didCancelBtnClick:self.cancelBtn];
}
- (void)setModelArray:(NSArray *)modelArray {
    _modelArray = modelArray;
    [self changeColor];
    [self recalculateHeight];
}
- (void)setAdaptiveDarkness:(BOOL)adaptiveDarkness {
    if (_adaptiveDarkness == adaptiveDarkness) {
        return;
    }
    _adaptiveDarkness = adaptiveDarkness;
    [self changeColor];
    [self.tableView reloadData];
}
- (void)setShowTopLineView:(BOOL)showTopLineView {
    if (_showTopLineView != showTopLineView) {
        _showTopLineView = showTopLineView;
        [self recalculateHeight];
    }
}
- (void)setTableHeaderView:(UIView *)tableHeaderView {
    _tableHeaderView = tableHeaderView;
    self.tableView.tableHeaderView = tableHeaderView;
}
- (void)setCancelTitle:(NSString *)cancelTitle {
    _cancelTitle = cancelTitle;
    cancelTitle = cancelTitle ?: [NSBundle hx_localizedStringForKey:@"取消"];
    [self.cancelBtn setTitle:cancelTitle forState:UIControlStateNormal];
}
- (void)recalculateHeight {
    CGFloat height = self.tableView.tableHeaderView.hx_h + self.tableView.tableFooterView.hx_h;
    NSInteger index = 0;
    CGFloat canScrollHeight = 0;
    for (HXPhotoBottomViewModel *model in self.modelArray) {
        height += model.cellHeight;
        index++;
        if (index <= 4) {
            canScrollHeight += model.cellHeight;
        }
    }
    if (height > self.hx_h - canScrollHeight - hxBottomMargin) {
        height = self.hx_h - canScrollHeight - hxBottomMargin;
        self.tableView.scrollEnabled = YES;
    }
    self.tableView.hx_h = height;
    self.tableViewHeight = height;
    if (self.showTopLineView) {
        self.topView.hidden = NO;
        self.panGesture.enabled = YES;
        self.tableView.hx_y = 15;
    }else {
        self.topView.hidden = YES;
        self.panGesture.enabled = NO;
        self.tableView.hx_y = 0;
    }
    self.footerCancelView.hx_y = CGRectGetMaxY(self.tableView.frame) + 8.f;
    self.contentView.hx_h = CGRectGetMaxY(self.footerCancelView.frame);
    self.contentViewHeight = self.contentView.hx_h;
    [self.tableView reloadData];
//    if (self.showViewCompletion) {
        [self resetContentViewFrame];
//    }
    if (HX_IOS11_Earlier) {
        [self.contentView hx_radiusWithRadius:10 corner:UIRectCornerTopLeft | UIRectCornerTopRight];
        [self.tableView hx_radiusWithRadius:10 corner:UIRectCornerTopLeft | UIRectCornerTopRight];
    }
}
- (void)resetContentViewFrame {
    if (self.contentView.hx_y != self.hx_h - self.contentViewHeight) {
        if (!self.showViewCompletion) {
            self.bgView.alpha = 0.f;
            self.contentView.hx_y = self.hx_h;
        }
        [UIView animateWithDuration:0.25 animations:^{
            self.bgView.alpha = 1.f;
            self.contentView.hx_y = self.hx_h - self.contentViewHeight;
            self.contentView.hx_h = self.contentViewHeight;
            self.tableView.hx_h = self.tableViewHeight;
            self.footerCancelView.hx_y = CGRectGetMaxY(self.tableView.frame) + 8.f;
        } completion:^(BOOL finished) {
           self.showViewCompletion = YES;
           self.centerY = self.contentView.hx_centerY;
        }];
    }
}
- (void)showView {
    self.bgView.alpha = 0.f;
    self.contentView.hx_y = self.hx_h;
    [UIView animateWithDuration:0.25 animations:^{
        self.bgView.alpha = 1.f;
        self.contentView.hx_y = self.hx_h - self.contentView.hx_h;
    } completion:^(BOOL finished) {
        self.showViewCompletion = YES;
        self.centerY = self.contentView.hx_centerY;
    }];
}
- (void)hideView {
    self.shouldHidden = YES;
    self.showViewCompletion = NO;
    [UIView animateWithDuration:0.2 animations:^{
        self.bgView.alpha = 0.f;
        self.contentView.hx_y = self.hx_h;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}
- (UIView *)bgView {
    if (!_bgView) {
        _bgView = [[UIView alloc] initWithFrame:self.bounds];
        _bgView.userInteractionEnabled = YES;
        [_bgView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideView)]];
    }
    return _bgView;
}
- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.hx_w, 0)];
        [_contentView addSubview:self.footerCancelView];
        [_contentView addSubview:self.tableView];
        [_contentView addSubview:self.topView];
    }
    return _contentView;
}
- (UIView *)topView {
    if (!_topView) {
        _topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.hx_w, 15)];
        _topView.backgroundColor = [UIColor whiteColor];
        [_topView addSubview:self.lineView];
        [_topView hx_radiusWithRadius:10 corner:UIRectCornerTopLeft | UIRectCornerTopRight];
    }
    return _topView;
}
- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 7, 35, 4)];
        _lineView.hx_centerX = self.hx_w / 2;
        [_lineView hx_radiusWithRadius:_lineView.hx_h / 2.f corner:UIRectCornerAllCorners];
    }
    return _lineView;
}
- (UIView *)footerCancelView {
    if (!_footerCancelView) {
        _footerCancelView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.hx_w, 60.f + hxBottomMargin)];
        [_footerCancelView addSubview:self.cancelBtn];
        _footerCancelView.userInteractionEnabled = YES;
        [_footerCancelView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideView)]];
        self.cancelBtn.frame = CGRectMake(0, 0, self.hx_w, _footerCancelView.hx_h);
        self.cancelBtn.titleEdgeInsets = UIEdgeInsetsMake(-hxBottomMargin, 0, 0, 0);
    }
    return _footerCancelView;
}
- (UIButton *)cancelBtn {
    if (!_cancelBtn) {
        _cancelBtn = [HXAlbumTitleButton buttonWithType:UIButtonTypeCustom];
        [_cancelBtn setTitle:[NSBundle hx_localizedStringForKey:@"取消"] forState:UIControlStateNormal];
        _cancelBtn.titleLabel.font = [UIFont hx_helveticaNeueOfSize:17];;
        [_cancelBtn addTarget:self action:@selector(didCancelBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        HXWeakSelf
        _cancelBtn.highlightedBlock = ^(BOOL highlighted) {
            if (highlighted) {
                BOOL isDark = weakSelf.adaptiveDarkness ? [HXPhotoCommon photoCommon].isDark : NO;
                [weakSelf.cancelBtn setBackgroundColor:isDark ? [UIColor colorWithRed:0.125 green:0.125 blue:0.125 alpha:1] : [UIColor hx_colorWithHexStr:@"#E5E5E5"]];
            }else {
                [weakSelf.cancelBtn setBackgroundColor:[UIColor clearColor]];
            }
        };
    }
    return _cancelBtn;
}
- (void)didCancelBtnClick:(UIButton *)button {
    if (self.cancelClick) {
        self.cancelClick();
    }
    [self hideView];
}
- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 15, self.hx_w, 0) style:UITableViewStylePlain];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.scrollEnabled = NO;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        [_tableView registerClass:[HXPhotoBottomSelectViewCell class] forCellReuseIdentifier:@"CellId"];
    }
    return _tableView;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    HXPhotoBottomSelectViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellId"];
    cell.adaptiveDarkness = self.adaptiveDarkness;
    cell.model = self.modelArray[indexPath.row];
    if (indexPath.row == self.modelArray.count - 1) {
        cell.hiddenBottomLine = YES;
    }else {
        cell.hiddenBottomLine = NO;
    }
    if (self.showTopLineView) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }else {
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    HXWeakSelf
    cell.didCellBlock = ^(HXPhotoBottomSelectViewCell * _Nonnull myCell) {
        NSIndexPath *myIndexPath = [weakSelf.tableView indexPathForCell:myCell];
        [weakSelf tableView:weakSelf.tableView didSelectRowAtIndexPath:myIndexPath];
    };
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.modelArray.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    HXPhotoBottomViewModel *model = self.modelArray[indexPath.row];
    return model.cellHeight;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    HXPhotoBottomViewModel *model = self.modelArray[indexPath.row];
    if (!model.canSelect) {
        return;
    }
    if (self.selectCompletion) {
        self.selectCompletion(indexPath.row, model);
    }
    [self hideView];
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.tracking) {
        self.tableViewDidScroll = YES;
    }
    if (scrollView.contentOffset.y < 0 && scrollView.tracking && !scrollView.dragging) {
        scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, 0);
    }else {
        if (self.contentView.hx_y > self.hx_h - self.contentViewHeight && scrollView.tracking) {
            scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, 0);
        }
    }
}
- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];

#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self changeColor];
        }
    }
#endif
}
- (void)changeColor {
    BOOL isDark = self.adaptiveDarkness ? [HXPhotoCommon photoCommon].isDark : NO;
    self.bgView.backgroundColor = isDark ? [UIColor colorWithRed:0.075 green:0.075 blue:0.075 alpha:0.5f] : [[UIColor blackColor] colorWithAlphaComponent:0.5f];
    self.contentView.backgroundColor = isDark ? [UIColor hx_colorWithHexStr:@"#1E1E1E"] : [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1];
    self.tableView.backgroundColor = isDark ? [UIColor hx_colorWithHexStr:@"#2D2D2D"] : [UIColor whiteColor];
    self.footerCancelView.backgroundColor = isDark ? [UIColor hx_colorWithHexStr:@"#2D2D2D"] : [UIColor whiteColor];
    [self.cancelBtn setTitleColor:isDark ? [UIColor whiteColor] : [UIColor colorWithRed:32.f/255.f green:32.f/255.f blue:32.f/255.f alpha:1] forState:UIControlStateNormal];
    if (self.cancelBtn.isHighlighted) {
        [self.cancelBtn setBackgroundColor:isDark ? [UIColor colorWithRed:0.125 green:0.125 blue:0.125 alpha:1] : [UIColor hx_colorWithHexStr:@"#E5E5E5"]];
    }else {
        [self.cancelBtn setBackgroundColor:[UIColor clearColor]];
    }
    self.topView.backgroundColor = self.footerCancelView.backgroundColor;
    self.lineView.backgroundColor = isDark ? [UIColor whiteColor] : [UIColor lightGrayColor];
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end


@interface HXPhotoBottomSelectViewCell ()
@property (strong, nonatomic) UILabel *titleLb;
@property (strong, nonatomic) UILabel *subTitleLb;
@property (strong, nonatomic) UIView *selectBgView;
@property (strong, nonatomic) UIView *cellSelectBgView;
@property (strong, nonatomic) UIView *lineView;
@property (strong, nonatomic) UITapGestureRecognizer *tap;
@end

@implementation HXPhotoBottomSelectViewCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectedBackgroundView = self.cellSelectBgView;
        [self.contentView addSubview:self.selectBgView];
        [self.contentView addSubview:self.titleLb];
        [self.contentView addSubview:self.subTitleLb];
        [self.contentView addSubview:self.lineView];
        
        self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizerClick:)];
        self.tap.enabled = NO;
        [self addGestureRecognizer:self.tap];
    }
    return self;
}
- (void)setSelectionStyle:(UITableViewCellSelectionStyle)selectionStyle {
    [super setSelectionStyle:selectionStyle];
    if (selectionStyle == UITableViewCellSelectionStyleNone) {
        self.tap.enabled = YES;
    }else {
        self.tap.enabled = NO;
    }
}
- (void)setShowSelectBgView:(BOOL)showSelectBgView {
    _showSelectBgView = showSelectBgView;
    self.selectBgView.hidden = !showSelectBgView;
}
- (void)tapGestureRecognizerClick:(UITapGestureRecognizer *)tapGesture {
    if (self.didCellBlock) {
        self.didCellBlock(self);
    }
}
- (void)setModel:(HXPhotoBottomViewModel *)model {
    _model = model;
    [self setSelectBgViewColor];
    self.titleLb.text = model.title;
    self.titleLb.font = model.titleFont;
    self.titleLb.numberOfLines = model.subTitle.length ? 1 : 0;
    
    self.subTitleLb.text = model.subTitle;
    self.subTitleLb.font = model.subTitleFont;
    self.subTitleLb.hidden = !model.subTitle.length;
    
    [self changeColor];
}
- (void)setHiddenBottomLine:(BOOL)hiddenBottomLine {
    _hiddenBottomLine = hiddenBottomLine;
    self.lineView.hidden = hiddenBottomLine;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    BOOL isLandscape = orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight;
    CGFloat margin = isLandscape ? hxBottomMargin + 10 : 10;
    if (HX_IS_IPhoneX_All) {
//        margin += 10;
    }
    if (self.model.subTitle.length) {
        self.titleLb.hx_x = 10;
        self.titleLb.hx_w = self.hx_w - margin * 2;
        self.titleLb.hx_h = [self.titleLb hx_getTextHeight];
        
        self.subTitleLb.hx_x = 10;
        self.subTitleLb.hx_w = self.hx_w - margin * 2;
        self.subTitleLb.hx_h = [self.subTitleLb hx_getTextHeight];
        
        self.titleLb.hx_y = (self.hx_h - (self.titleLb.hx_h + self.subTitleLb.hx_h + 3)) / 2;
        self.subTitleLb.hx_y = CGRectGetMaxY(self.titleLb.frame) + 3;
    }else {
        self.titleLb.frame = CGRectMake(10, 0, self.hx_w - margin * 2, self.hx_h);
    }
    if (isLandscape) {
        self.lineView.frame = CGRectMake(0, self.hx_h - 0.5f, self.hx_w - hxBottomMargin * 2, 0.5f);
    }else {
        self.lineView.frame = CGRectMake(0, self.hx_h - 0.5f, self.hx_w, 0.5f);
    }
    self.selectBgView.frame = self.bounds;
    self.cellSelectBgView.frame = self.bounds;
    
}
- (UILabel *)titleLb {
    if (!_titleLb) {
        _titleLb = [[UILabel alloc] init];
        _titleLb.textAlignment = NSTextAlignmentCenter;
        _titleLb.adjustsFontSizeToFitWidth = YES;
    }
    return _titleLb;
}
- (UILabel *)subTitleLb {
    if (!_subTitleLb) {
        _subTitleLb = [[UILabel alloc] init];
        _subTitleLb.textAlignment = NSTextAlignmentCenter;
        _subTitleLb.numberOfLines = 1;
        _subTitleLb.adjustsFontSizeToFitWidth = YES;
    }
    return _subTitleLb;
}
- (UIView *)selectBgView {
    if (!_selectBgView) {
        _selectBgView = [[UIView alloc] init];
        _selectBgView.hidden = YES;
    }
    return _selectBgView;
}
- (UIView *)cellSelectBgView {
    if (!_cellSelectBgView) {
        _cellSelectBgView = [[UIView alloc] init];
    }
    return _cellSelectBgView;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc] init];
    }
    return _lineView;
}
- (void)setSelectBgViewColor {
    BOOL isDark = self.adaptiveDarkness ? [HXPhotoCommon photoCommon].isDark : NO;
    UIColor *selectBgColor = isDark ? [UIColor colorWithRed:0.125 green:0.125 blue:0.125 alpha:1] : self.model.selectColor;
    if (!self.model.canSelect) {
        selectBgColor = [UIColor clearColor];
    }
    self.selectBgView.backgroundColor =selectBgColor ;
    self.cellSelectBgView.backgroundColor = selectBgColor;
}
- (void)changeColor {
    BOOL isDark = self.adaptiveDarkness ? [HXPhotoCommon photoCommon].isDark : NO;
    self.backgroundColor = isDark ? [UIColor hx_colorWithHexStr:@"#2D2D2D"] : self.model.backgroundColor;
    self.titleLb.textColor = isDark ? self.model.titleDarkColor : self.model.titleColor;
    [self setSelectBgViewColor];
    self.lineView.backgroundColor = isDark ? [UIColor hx_colorWithHexStr:@"#1E1E1E"] : self.model.lineColor;
    self.subTitleLb.textColor = isDark ? self.model.subTitleDarkColor : self.model.subTitleColor;
}
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self changeColor];
        }
    }
#endif
}
@end
