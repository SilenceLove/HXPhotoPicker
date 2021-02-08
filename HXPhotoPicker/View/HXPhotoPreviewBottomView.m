//
//  HXPhotoPreviewBottomView.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2017/10/16.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "HXPhotoPreviewBottomView.h"
#import "HXPhotoManager.h"
#import "UIImageView+HXExtension.h"
#import "HXPhotoEdit.h"
@interface HXPhotoPreviewBottomView ()<UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout>
@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) UICollectionViewFlowLayout *flowLayout;
@property (strong, nonatomic) NSIndexPath *currentIndexPath;
@property (strong, nonatomic) UIButton *doneBtn;
@property (strong, nonatomic) UIButton *editBtn;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (strong, nonatomic) UIColor *barTintColor;
@end

@implementation HXPhotoPreviewBottomView
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
- (instancetype)initWithFrame:(CGRect)frame modelArray:(NSArray *)modelArray manager:(HXPhotoManager *)manager {
    self = [super initWithFrame:frame];
    if (self) {
        self.manager = manager;
        self.modelArray = [NSMutableArray arrayWithArray:modelArray];
        [self setupUI];
    }
    return self;
}
- (void)setManager:(HXPhotoManager *)manager {
    _manager = manager;
    self.barTintColor = manager.configuration.bottomViewBgColor;
    self.bgView.barStyle = manager.configuration.bottomViewBarStyle;
    self.bgView.translucent = manager.configuration.bottomViewTranslucent;
    self.tipView.translucent = manager.configuration.bottomViewTranslucent;
    self.tipView.barStyle = manager.configuration.bottomViewBarStyle;
}
- (void)setupUI {
    _currentIndex = -1;
    [self addSubview:self.bgView];
    [self addSubview:self.collectionView];
    [self addSubview:self.doneBtn];
    [self addSubview:self.editBtn];
    [self addSubview:self.tipView];
    [self changeDoneBtnFrame];
    [self changeColor];
}
- (void)setEnabled:(BOOL)enabled {
    _enabled = enabled;
    self.editBtn.enabled = enabled;
}
- (void)setHideEditBtn:(BOOL)hideEditBtn {
    _hideEditBtn = hideEditBtn;
    if (hideEditBtn) {
        [self.editBtn removeFromSuperview];
        [self layoutSubviews];
    }else {
        [self addSubview:self.editBtn];
    }
}
- (void)setOutside:(BOOL)outside {
    _outside = outside;
    if (outside) {
        self.doneBtn.hidden = YES;
    }
}
- (void)changeTipViewState:(HXPhotoModel *)model {
    NSString *tipText;
    if (!self.manager.configuration.selectTogether) {
        if (self.manager.selectedPhotoCount && model.subType == HXPhotoModelMediaSubTypeVideo) {
            tipText = [NSBundle hx_localizedStringForKey:@"选择照片时不能选择视频"];
        }else if (self.manager.selectedVideoCount && model.subType == HXPhotoModelMediaSubTypePhoto) {
            tipText = [NSBundle hx_localizedStringForKey:@"选择视频时不能选择照片"];
        }
    }
    if (model.subType == HXPhotoModelMediaSubTypeVideo && !tipText) {
        if (round(model.videoDuration) >= self.manager.configuration.videoMaximumSelectDuration + 1) {
            if (self.manager.configuration.videoCanEdit) {
                tipText = [NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"只能选择%ld秒内的视频，需进行编辑"], self.manager.configuration.videoMaximumSelectDuration];
            }else {
                tipText = [NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"视频大于%ld秒，无法选择"], self.manager.configuration.videoMaximumSelectDuration];
            }
        }else if (round(model.videoDuration) < self.manager.configuration.videoMinimumSelectDuration) {
            tipText = [NSString stringWithFormat:[NSBundle hx_localizedStringForKey:@"视频少于%ld秒，无法选择"], self.manager.configuration.videoMinimumSelectDuration];
        }
    }
    self.tipLb.text = tipText;
    self.tipView.hidden = !tipText;
    self.collectionView.hidden = tipText;
}
- (void)reloadData {
    [self.collectionView reloadData];
    if (self.currentIndex >= 0 && self.currentIndex < self.modelArray.count) {
        [self.collectionView selectItemAtIndexPath:self.currentIndexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
    }
}
- (void)insertModel:(HXPhotoModel *)model {
    [self.modelArray addObject:model];
    [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:self.modelArray.count - 1 inSection:0]]];
    [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:self.modelArray.count - 1 inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
    self.currentIndex = self.modelArray.count - 1;
}
- (void)deleteModel:(HXPhotoModel *)model {
    if ([self.modelArray containsObject:model] && self.currentIndex >= 0) {
        NSInteger index = [self.modelArray indexOfObject:model];
        [self.modelArray removeObject:model];
        [self.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]]];
        _currentIndex = -1;
    }
}
- (void)setCurrentIndex:(NSInteger)currentIndex {
    if (_currentIndex == currentIndex) {
        return;
    }
    if (currentIndex < 0 || currentIndex > self.modelArray.count - 1) {
        return;
    }
    _currentIndex = currentIndex;
    self.currentIndexPath = [NSIndexPath indexPathForItem:currentIndex inSection:0];
    
    [self.collectionView selectItemAtIndexPath:self.currentIndexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
}
- (void)setSelectCount:(NSInteger)selectCount {
    _selectCount = selectCount;
    NSString *text;
    if (selectCount <= 0) {
        text = @"";
        [self.doneBtn setTitle:[NSBundle hx_localizedStringForKey:@"完成"] forState:UIControlStateNormal];
    }else {
        if (self.manager.configuration.doneBtnShowDetail) {
            if (!self.manager.configuration.selectTogether) {
                if (self.manager.selectedPhotoCount > 0) {
                    NSInteger maxCount = self.manager.configuration.photoMaxNum > 0 ? self.manager.configuration.photoMaxNum : self.manager.configuration.maxNum;
                    text = [NSString stringWithFormat:@"(%ld/%ld)", selectCount,maxCount];
                }else {
                    NSInteger maxCount = self.manager.configuration.videoMaxNum > 0 ? self.manager.configuration.videoMaxNum : self.manager.configuration.maxNum;
                    text = [NSString stringWithFormat:@"(%ld/%ld)", selectCount,maxCount];
                }
            }else {
                text = [NSString stringWithFormat:@"(%ld/%ld)", selectCount,self.manager.configuration.maxNum];
            }
        }else {
            text = [NSString stringWithFormat:@"(%ld)", selectCount];
        }
    }
    [self.doneBtn setTitle:[NSString stringWithFormat:@"%@%@",[NSBundle hx_localizedStringForKey:@"完成"], text] forState:UIControlStateNormal];
    [self changeDoneBtnFrame];
}
#pragma mark - < UICollectionViewDataSource >
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.modelArray count];
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HXPhotoPreviewBottomViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"DatePreviewBottomViewCellId" forIndexPath:indexPath];
    cell.selectColor = self.manager.configuration.previewBottomSelectColor ? : self.manager.configuration.themeColor;
    HXPhotoModel *model = self.modelArray[indexPath.item];
    if ([HXPhotoTools isRTLLanguage]) {
        model = self.modelArray[self.modelArray.count - 1 - indexPath.item];
    }
    cell.model = model;
    return cell;
}
#pragma mark - < UICollectionViewDelegate >
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.delagate respondsToSelector:@selector(photoPreviewBottomViewDidItem:currentIndex:beforeIndex:)]) {
        [self.delagate photoPreviewBottomViewDidItem:self.modelArray[indexPath.item] currentIndex:indexPath.item beforeIndex:self.currentIndex];
    }
}
- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [(HXPhotoPreviewBottomViewCell *)cell cancelRequest];
}
- (void)deselectedWithIndex:(NSInteger)index {
    if (index < 0 || index > self.modelArray.count - 1 || self.currentIndex < 0) {
        return;
    }
    [self.collectionView deselectItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] animated:NO];
    _currentIndex = -1;
}

- (void)deselected {
    if (self.currentIndex < 0 || self.currentIndex > self.modelArray.count - 1) {
        return;
    }
    [self.collectionView deselectItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex inSection:0] animated:NO];
    _currentIndex = -1;
}

- (void)didDoneBtnClick {
    if ([self.delagate respondsToSelector:@selector(photoPreviewBottomViewDidDone:)]) {
        [self.delagate photoPreviewBottomViewDidDone:self];
    }
}
- (void)didEditBtnClick {
    if ([self.delagate respondsToSelector:@selector(photoPreviewBottomViewDidEdit:)]) {
        [self.delagate photoPreviewBottomViewDidEdit:self];
    }
}
- (void)changeDoneBtnFrame {
    if (self.outside) {
        if (self.manager.afterSelectedPhotoArray.count && self.manager.afterSelectedVideoArray.count) {
            if (!self.manager.configuration.videoCanEdit && !self.manager.configuration.photoCanEdit) {
                if (self.collectionView.hx_w != self.hx_w - 12) self.collectionView.hx_w = self.hx_w - 12;
            }else {
                self.editBtn.hx_x = self.hx_w - 12 - self.editBtn.hx_w;
                if (self.collectionView.hx_w != self.editBtn.hx_x) self.collectionView.hx_w = self.editBtn.hx_x;
            }
        }else {
            if (self.hideEditBtn) {
                if (self.collectionView.hx_w != self.hx_w - 12) self.collectionView.hx_w = self.hx_w - 12;
            }else {
                self.editBtn.hx_x = self.hx_w - 12 - self.editBtn.hx_w;
                if (self.collectionView.hx_w != self.editBtn.hx_x) self.collectionView.hx_w = self.editBtn.hx_x;
            }
        }
    }else {
        
        CGFloat width = self.doneBtn.titleLabel.hx_getTextWidth;
        self.doneBtn.hx_w = width + 20;
        if (self.doneBtn.hx_w < 60) {
            self.doneBtn.hx_w = 60;
        }
        self.doneBtn.hx_x = self.hx_w - 12 - self.doneBtn.hx_w;
        self.editBtn.hx_x = self.doneBtn.hx_x - self.editBtn.hx_w;
        if (self.manager.type == HXPhotoManagerSelectedTypePhoto || self.manager.type == HXPhotoManagerSelectedTypeVideo) {
            if (!self.hideEditBtn) {
                if (self.collectionView.hx_w != self.editBtn.hx_x) self.collectionView.hx_w = self.editBtn.hx_x;
            }else {
                if (self.collectionView.hx_w != self.doneBtn.hx_x - 12) self.collectionView.hx_w = self.doneBtn.hx_x - 12;
            }
        }else {
            if (!self.manager.configuration.videoCanEdit && !self.manager.configuration.photoCanEdit) {
                if (self.collectionView.hx_w != self.doneBtn.hx_x - 12) self.collectionView.hx_w = self.doneBtn.hx_x - 12;
            }else {
                if (self.collectionView.hx_w != self.editBtn.hx_x) self.collectionView.hx_w = self.editBtn.hx_x;
            }
        }
    }
    self.tipView.frame = self.collectionView.frame;
    
    self.tipLb.frame = CGRectMake(12, 0, self.tipView.hx_w - 12, self.tipView.hx_h);
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.bgView.frame = self.bounds;
 
    self.doneBtn.frame = CGRectMake(0, 0, 60, 30);
    self.doneBtn.center = CGPointMake(self.doneBtn.center.x, 25);
    
    
    [self changeDoneBtnFrame];
}
- (void)changeColor {
    UIColor *themeColor;
    UIColor *selectedTitleColor;
    if ([HXPhotoCommon photoCommon].isDark) {
        themeColor = [UIColor whiteColor];
        selectedTitleColor = [UIColor whiteColor];
        self.bgView.barTintColor = [UIColor blackColor];
        self.tipView.barTintColor = [UIColor blackColor];
    }else {
        themeColor = self.manager.configuration.themeColor;
        if (self.manager.configuration.bottomDoneBtnTitleColor) {
            selectedTitleColor = self.manager.configuration.bottomDoneBtnTitleColor;
        }else {
            selectedTitleColor = self.manager.configuration.selectedTitleColor;
        }
        self.bgView.barTintColor = self.barTintColor;
        self.tipView.barTintColor = self.barTintColor;
    }
    _tipLb.textColor = themeColor;
    if ([themeColor isEqual:[UIColor whiteColor]]) {
        [_doneBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_doneBtn setTitleColor:[[UIColor blackColor] colorWithAlphaComponent:0.5] forState:UIControlStateDisabled];
    }else {
        [_doneBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_doneBtn setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.5] forState:UIControlStateDisabled];
    }
    if (selectedTitleColor) {
        [_doneBtn setTitleColor:selectedTitleColor forState:UIControlStateNormal];
        [_doneBtn setTitleColor:[selectedTitleColor colorWithAlphaComponent:0.5] forState:UIControlStateDisabled];
    }
    UIColor *doneBtnDarkBgColor = self.manager.configuration.bottomDoneBtnDarkBgColor ?: [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1];
    UIColor *doneBgColor = self.manager.configuration.bottomDoneBtnBgColor ?: themeColor;
    _doneBtn.backgroundColor = [HXPhotoCommon photoCommon].isDark ? doneBtnDarkBgColor : doneBgColor;
    [_editBtn setTitleColor:themeColor forState:UIControlStateNormal];
    [_editBtn setTitleColor:[themeColor colorWithAlphaComponent:0.5] forState:UIControlStateDisabled];
}
#pragma mark - < 懒加载 >
- (UIToolbar *)bgView {
    if (!_bgView) {
        _bgView = [[UIToolbar alloc] init];
    }
    return _bgView;
}
- (UIToolbar *)tipView {
    if (!_tipView) {
        _tipView = [[UIToolbar alloc] init];
        _tipView.hidden = YES;
        [_tipView setShadowImage:[UIImage new] forToolbarPosition:UIBarPositionAny];
        [_tipView addSubview:self.tipLb];
    }
    return _tipView;
}
- (UILabel *)tipLb {
    if (!_tipLb) {
        _tipLb = [[UILabel alloc] init];
        _tipLb.numberOfLines = 0;
        _tipLb.font = [UIFont systemFontOfSize:14];
    }
    return _tipLb;
}
- (UICollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0,self.hx_w - 12 - 50, 50) collectionViewLayout:self.flowLayout];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        [_collectionView registerClass:[HXPhotoPreviewBottomViewCell class] forCellWithReuseIdentifier:@"DatePreviewBottomViewCellId"];
    }
    return _collectionView;
}
- (UICollectionViewFlowLayout *)flowLayout {
    if (!_flowLayout) {
        _flowLayout = [[UICollectionViewFlowLayout alloc] init];
        CGFloat itemWidth = 40;
        _flowLayout.itemSize = CGSizeMake(itemWidth, 48);
        _flowLayout.sectionInset = UIEdgeInsetsMake(1, 12, 1, 0);
        _flowLayout.minimumInteritemSpacing = 1;
        _flowLayout.minimumLineSpacing = 1;
        _flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    }
    return _flowLayout;
} 
- (UIButton *)doneBtn {
    if (!_doneBtn) {
        _doneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_doneBtn setTitle:[NSBundle hx_localizedStringForKey:@"完成"] forState:UIControlStateNormal];
        _doneBtn.titleLabel.font = [UIFont hx_mediumPingFangOfSize:16];
        _doneBtn.layer.cornerRadius = 3;
        [_doneBtn addTarget:self action:@selector(didDoneBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _doneBtn;
}
- (UIButton *)editBtn {
    if (!_editBtn) {
        _editBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_editBtn setTitle:[NSBundle hx_localizedStringForKey:@"编辑"] forState:UIControlStateNormal];
        _editBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        [_editBtn addTarget:self action:@selector(didEditBtnClick) forControlEvents:UIControlEventTouchUpInside];
        _editBtn.hx_size = CGSizeMake(50, 50);
    }
    return _editBtn;
}
@end

@interface HXPhotoPreviewBottomViewCell ()
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIView *editTipView;
@property (strong, nonatomic) UIImageView *editTipIcon;
@property (assign, nonatomic) PHImageRequestID requestID;
@end

@implementation HXPhotoPreviewBottomViewCell
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {

            UIColor *themeColor = [HXPhotoCommon photoCommon].isDark ? [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1] : self.selectColor;

            self.layer.borderColor = self.selected ? [themeColor colorWithAlphaComponent:0.75].CGColor : nil;
            
        }
    }
#endif
}
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}
- (void)setupUI {
    [self.contentView addSubview:self.imageView];
    [self.contentView addSubview:self.editTipView];
}
- (void)setModel:(HXPhotoModel *)model {
    _model = model;
    self.editTipView.hidden = !(model.photoEdit);
    if (model.photoEdit) {
        self.imageView.image = model.photoEdit.editPosterImage;
    }else {
        HXWeakSelf
        if (model.thumbPhoto) {
            self.imageView.image = model.thumbPhoto;
            if (model.networkPhotoUrl) {
                [self.imageView hx_setImageWithModel:model progress:^(CGFloat progress, HXPhotoModel *model) {
                    if (weakSelf.model == model) {
                        
                    }
                } completed:^(UIImage *image, NSError *error, HXPhotoModel *model) {
                    if (weakSelf.model == model) {
                        if (error != nil) {
                        }else {
                            if (image) {
                                weakSelf.imageView.image = image;
                            }
                        }
                    }
                }];
            }
        }else {
            self.requestID = [self.model requestThumbImageCompletion:^(UIImage *image, HXPhotoModel *model, NSDictionary *info) {
                if (weakSelf.model == model) {
                    weakSelf.imageView.image = image;
                }
            }];
        }
    }
    self.layer.borderWidth = self.selected ? 5 : 0;
    self.layer.borderColor = self.selected ? [([HXPhotoCommon photoCommon].isDark ? [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1] : self.selectColor) colorWithAlphaComponent:0.75].CGColor : nil;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = self.bounds;
    self.editTipView.frame = self.imageView.frame;
    self.editTipIcon.center = CGPointMake(self.hx_w / 2, self.hx_h / 2);
}
- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
    }
    return _imageView;
}
- (UIView *)editTipView {
    if (!_editTipView) {
        _editTipView = [[UIView alloc] init];
        _editTipView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3f];
        [_editTipView addSubview:self.editTipIcon];
    }
    return _editTipView;;
}
- (UIImageView *)editTipIcon {
    if (!_editTipIcon) {
        _editTipIcon = [[UIImageView alloc] initWithImage:[UIImage hx_imageNamed:@"hx_photo_edit_show_tip"]];
        _editTipIcon.hx_size = CGSizeMake(15.5, 11);
    }
    return _editTipIcon;
}
- (void)setSelectColor:(UIColor *)selectColor {
    _selectColor = selectColor;
    if (!_selectColor) {
        if ([HXPhotoCommon photoCommon].isDark) {
            selectColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1];
        }
        self.layer.borderColor = self.selected ? [selectColor colorWithAlphaComponent:0.75].CGColor : nil;
    }
}
- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    self.layer.borderWidth = selected ? 5 : 0;
    self.layer.borderColor = selected ? [([HXPhotoCommon photoCommon].isDark ? [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1] : self.selectColor) colorWithAlphaComponent:0.75].CGColor : nil;
}
- (void)cancelRequest {
    if (self.requestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.requestID];
        self.requestID = -1;
    }
}
- (void)dealloc {
    [self cancelRequest];
} 
@end
