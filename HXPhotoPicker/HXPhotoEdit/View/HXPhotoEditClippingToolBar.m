//
//  HXPhotoEditClippingToolBar.m
//  photoEditDemo
//
//  Created by Silence on 2020/6/30.
//  Copyright © 2020 Silence. All rights reserved.
//

#import "HXPhotoEditClippingToolBar.h"
#import "UIImage+HXExtension.h"
#import "NSBundle+HXPhotoPicker.h"
#import "UIButton+HXExtension.h"
#import "UIView+HXExtension.h"
#import "UIFont+HXExtension.h"
#import "UILabel+HXExtension.h"
#import "HXPhotoDefine.h"

#define HXScaleViewSize 28.f

@interface HXPhotoEditClippingToolBar ()<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@property (weak, nonatomic) IBOutlet UIButton *confirmBtn;
@property (weak, nonatomic) IBOutlet UIButton *cancelBtn;
@property (weak, nonatomic) IBOutlet UIButton *resetBtn;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (copy, nonatomic) NSArray<HXPhotoEditClippingToolBarRotaioModel *> *models;
@property (strong, nonatomic) HXPhotoEditClippingToolBarRotaioModel *currentSelectedModel;
@end

@implementation HXPhotoEditClippingToolBar

+ (instancetype)initView {
    return [[[NSBundle hx_photoPickerBundle] loadNibNamed:NSStringFromClass(self) owner:nil options:nil] lastObject];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.confirmBtn setImage:[UIImage hx_imageContentsOfFile:@"hx_photo_edit_clip_confirm"] forState:UIControlStateNormal];
    [self.cancelBtn setImage:[UIImage hx_imageContentsOfFile:@"hx_photo_edit_clip_cancel"] forState:UIControlStateNormal];
    self.resetBtn.enabled = NO;
    [self.resetBtn setTitle:[NSBundle hx_localizedStringForKey:@"还原"] forState:UIControlStateNormal];
    
    UICollectionViewFlowLayout *flowlayout = (id)self.collectionView.collectionViewLayout;
    flowlayout.minimumInteritemSpacing = 20;
    flowlayout.sectionInset = UIEdgeInsetsMake(0, 20, 0, 10);
    flowlayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    [self.collectionView registerClass:[HXPhotoEditClippingToolBarHeader class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HXPhotoEditClippingToolBarHeaderId"];
    [self.collectionView registerClass:[HXPhotoEditClippingToolBarHeaderViewCell class] forCellWithReuseIdentifier:@"HXPhotoEditClippingToolBarHeaderViewCellId"];
}
- (void)resetRotate {
    self.currentSelectedModel.isSelected = NO;
    self.currentSelectedModel = self.models.firstObject;
    self.currentSelectedModel.isSelected = YES;
    [self.collectionView reloadData];
}
- (void)setRotateAlpha:(CGFloat)alpha {
    if (alpha == 1) {
        self.collectionView.userInteractionEnabled = YES;
    }else {
        self.collectionView.userInteractionEnabled = NO;
    }
    self.collectionView.alpha = alpha;
}
- (void)setEnableReset:(BOOL)enableReset {
    _enableReset = enableReset;
    self.resetBtn.enabled = enableReset;
}
- (IBAction)didBtnClick:(UIButton *)sender {
    if (self.enableRotaio) {
        [self resetRotate];
        [self.collectionView setContentOffset:CGPointMake(0, 0) animated:YES];
    }
    if (self.didBtnBlock) {
        self.didBtnBlock(sender.tag);
    }
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.enableRotaio) {
        return self.models.count;
    }else {
        return 0;
    }
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HXPhotoEditClippingToolBarHeaderViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"HXPhotoEditClippingToolBarHeaderViewCellId" forIndexPath:indexPath];
    cell.themeColor = self.themeColor;
    cell.model = self.models[indexPath.item];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        HXPhotoEditClippingToolBarHeader *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"HXPhotoEditClippingToolBarHeaderId" forIndexPath:indexPath];
        header.enableRotaio = self.enableRotaio;
        header.didRotateBlock = self.didRotateBlock;
        header.didMirrorHorizontallyBlock = self.didMirrorHorizontallyBlock;
        return header;
    }
    return [UICollectionReusableView new];
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    HXPhotoEditClippingToolBarRotaioModel *model = self.models[indexPath.item];
    if (!CGSizeEqualToSize(model.scaleSize, CGSizeZero)) {
        return model.scaleSize;
    }
    CGFloat scaleWidth = HXScaleViewSize + 10;
    if (!model.widthRatio || model.widthRatio == 1) {
        model.size = CGSizeMake(HXScaleViewSize, HXScaleViewSize);
        model.scaleSize = CGSizeMake(HXScaleViewSize, scaleWidth);
    }else {
        CGFloat scale = scaleWidth / model.widthRatio;
        CGFloat width = model.widthRatio * scale;
        CGFloat height = model.heightRatio * scale;
        if (height > scaleWidth) {
            height = scaleWidth;
            width = scaleWidth / model.heightRatio * model.widthRatio;
        }
        model.size = CGSizeMake(width, height);
        if (height < scaleWidth) {
            height = scaleWidth;
        }
        CGFloat textWidth = [UILabel hx_getTextWidthWithText:model.scaleText height:height - 3 font:[UIFont hx_mediumHelveticaNeueOfSize:12]] + 5;
        if (width < textWidth) {
            height = textWidth / width * height;
            width = textWidth;
            if (height > 45.f) {
                height = 45.f;
            }
            model.size = CGSizeMake(width, height);
        }
        model.scaleSize = CGSizeMake(width, height);
    }
    return model.scaleSize;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(100, 50);
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *selectedIndexPath;
    if (self.currentSelectedModel) {
        selectedIndexPath = [NSIndexPath indexPathForItem:[self.models indexOfObject:self.currentSelectedModel] inSection:0];
    }
    if (selectedIndexPath && selectedIndexPath.item == indexPath.item) {
        return;
    }
    self.currentSelectedModel.isSelected = NO;
    HXPhotoEditClippingToolBarRotaioModel *model = self.models[indexPath.item];
    model.isSelected = YES;
    if (self.selectedRotaioBlock) {
        self.selectedRotaioBlock(model);
    }
    self.currentSelectedModel = model;
    if (selectedIndexPath) {
        [collectionView reloadItemsAtIndexPaths:@[indexPath, selectedIndexPath]];
    }else {
        [collectionView reloadItemsAtIndexPaths:@[indexPath]];
    }
}
- (NSArray<HXPhotoEditClippingToolBarRotaioModel *> *)models {
    if (!_models) {
        NSArray *scaleArray = @[@[@0, @0], @[@1, @1], @[@3, @2], @[@2, @3], @[@4, @3], @[@3, @4], @[@16, @9], @[@9, @16]];
        NSMutableArray *modelArray = [NSMutableArray array];
        for (NSArray *array in scaleArray) {
            HXPhotoEditClippingToolBarRotaioModel *model = [[HXPhotoEditClippingToolBarRotaioModel alloc] init];
            model.widthRatio = [array.firstObject floatValue];
            model.heightRatio = [array.lastObject floatValue];
            if (modelArray.count == 0) {
                model.isSelected = YES;
                self.currentSelectedModel = model;
            }
            [modelArray addObject:model];
        }
        _models = modelArray.copy;
    }
    return _models;
}
@end

@interface HXPhotoEditClippingToolBarHeader ()
@property (strong, nonatomic) UIButton *rotateBtn;
@property (strong, nonatomic) UIButton *mirrorHorizontallyBtn;
@property (strong, nonatomic) UIView *lineView;
@end

@implementation HXPhotoEditClippingToolBarHeader

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.rotateBtn];
        [self addSubview:self.mirrorHorizontallyBtn];
        [self addSubview:self.lineView];
    }
    return self;
}
- (void)setEnableRotaio:(BOOL)enableRotaio {
    _enableRotaio = enableRotaio;
    self.lineView.hidden = !enableRotaio;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.rotateBtn.hx_centerY = self.hx_h / 2;
    self.rotateBtn.hx_x = 20;
    
    self.mirrorHorizontallyBtn.hx_x = CGRectGetMaxX(self.rotateBtn.frame) + 10;
    self.mirrorHorizontallyBtn.hx_centerY = self.rotateBtn.hx_centerY;
    
    self.lineView.hx_x = self.hx_w - 2;
    self.lineView.hx_centerY = self.hx_h / 2;
}

- (UIButton *)rotateBtn {
    if (!_rotateBtn) {
        _rotateBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [_rotateBtn setImage:[UIImage hx_imageContentsOfFile:@"hx_photo_edit_clip_rotate"] forState:UIControlStateNormal];
        _rotateBtn.hx_size = _rotateBtn.currentImage.size;
        _rotateBtn.tintColor = [UIColor whiteColor];
        [_rotateBtn addTarget:self action:@selector(didRotateBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        [_rotateBtn hx_setEnlargeEdgeWithTop:5 right:5 bottom:5 left:5];
    }
    return _rotateBtn;
}
- (void)didRotateBtnClick:(UIButton *)button {
    if (self.didRotateBlock) {
        self.didRotateBlock();
    }
}
- (UIButton *)mirrorHorizontallyBtn {
    if (!_mirrorHorizontallyBtn) {
        _mirrorHorizontallyBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [_mirrorHorizontallyBtn setImage:[UIImage hx_imageContentsOfFile:@"hx_photo_edit_clip_mirror_horizontally"] forState:UIControlStateNormal];
        _mirrorHorizontallyBtn.hx_size = _rotateBtn.currentImage.size;
        _mirrorHorizontallyBtn.tintColor = [UIColor whiteColor];
        [_mirrorHorizontallyBtn addTarget:self action:@selector(didMirrorHorizontallyBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        [_mirrorHorizontallyBtn hx_setEnlargeEdgeWithTop:5 right:5 bottom:5 left:5];
    }
    return _mirrorHorizontallyBtn;
}
- (void)didMirrorHorizontallyBtnClick:(UIButton *)button {
    if (self.didMirrorHorizontallyBlock) {
        self.didMirrorHorizontallyBlock();
    }
}
- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, 20)];
        _lineView.backgroundColor = [UIColor whiteColor];
    }
    return _lineView;
}
@end


@interface HXPhotoEditClippingToolBarHeaderViewCell ()
@property (strong, nonatomic) UIImageView *scaleImageView;
@property (strong, nonatomic) UIView *scaleView;
@property (strong, nonatomic) UILabel *scaleLb;
@end

@implementation HXPhotoEditClippingToolBarHeaderViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self.contentView addSubview:self.scaleView];
    }
    return self;
}
- (void)setModel:(HXPhotoEditClippingToolBarRotaioModel *)model {
    _model = model;
    [self setSubviewFrame];
    self.scaleLb.text = model.scaleText;
    if (!model.widthRatio) {
        self.scaleView.layer.borderWidth = 0.f;
        self.scaleImageView.hidden = NO;
    }else {
        self.scaleView.layer.borderWidth = 1.25f;
        self.scaleImageView.hidden = YES;
    }
    if (model.isSelected) {
        self.scaleImageView.tintColor = self.themeColor;
        self.scaleView.layer.borderColor = self.themeColor.CGColor;
        self.scaleLb.textColor = self.themeColor;
    }else {
        self.scaleImageView.tintColor = UIColor.whiteColor;
        self.scaleView.layer.borderColor = UIColor.whiteColor.CGColor;
        self.scaleLb.textColor = [UIColor whiteColor];
    }
}
- (void)setSubviewFrame {
    self.scaleView.hx_size = self.model.size;
    self.scaleView.center = CGPointMake(self.model.scaleSize.width / 2, self.model.scaleSize.height / 2);
    self.scaleLb.frame = CGRectMake(1.5, 1.5, self.scaleView.hx_w - 3, self.scaleView.hx_h - 3);
    self.scaleImageView.frame = self.scaleView.bounds;
    if (HX_IOS11_Earlier) {
        [self.scaleView hx_radiusWithRadius:2 corner:UIRectCornerAllCorners];
    }
}
- (UIView *)scaleView {
    if (!_scaleView) {
        _scaleView = [[UIView alloc] init];
        if (HX_IOS11_Later) {
            [_scaleView hx_radiusWithRadius:2 corner:UIRectCornerAllCorners];
        }
        [_scaleView addSubview:self.scaleImageView];
        [_scaleView addSubview:self.scaleLb];
    }
    return _scaleView;
}
- (UIImageView *)scaleImageView {
    if (!_scaleImageView) {
        _scaleImageView = [[UIImageView alloc] initWithImage:[[UIImage hx_imageContentsOfFile:@"hx_photo_edit_clip_free"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    }
    return _scaleImageView;
}
- (UILabel *)scaleLb {
    if (!_scaleLb) {
        _scaleLb = [[UILabel alloc] init];
        _scaleLb.textColor = [UIColor whiteColor];
        _scaleLb.textAlignment = NSTextAlignmentCenter;
        _scaleLb.font = [UIFont hx_mediumHelveticaNeueOfSize:12];
    }
    return _scaleLb;
}
@end

@implementation HXPhotoEditClippingToolBarRotaioModel
- (NSString *)scaleText {
    if (!self.widthRatio) {
        return [NSBundle hx_localizedStringForKey:@"自由"];
    }else {
        return [NSString stringWithFormat:@"%ld:%ld", (NSInteger)self.widthRatio, (NSInteger)self.heightRatio];
    }
}
@end
