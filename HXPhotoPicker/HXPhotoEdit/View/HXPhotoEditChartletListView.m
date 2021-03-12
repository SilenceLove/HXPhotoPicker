//
//  HXPhotoEditChartletListView.m
//  photoEditDemo
//
//  Created by Silence on 2020/6/23.
//  Copyright © 2020 Silence. All rights reserved.
//

#import "HXPhotoEditChartletListView.h"
#import "UIView+HXExtension.h"
#import "HXPhotoDefine.h"
#import "UIImage+HXExtension.h"
#import "HXPhotoEditChartletPreviewView.h"
#import "HXPhotoEditChartletModel.h"
#import "HXPhotoEditChartletContentViewCell.h"
#import "UIImageView+HXExtension.h"
#import "HXPhotoEditConfiguration.h"
#import "NSBundle+HXPhotoPicker.h"

#define HXclViewHeight HX_UI_IS_IPAD ? 500 : (([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait || [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortraitUpsideDown) ? (HX_IS_IPhoneX_All ? 400 : 350) : 200)


@interface HXPhotoEditChartletListView ()<UICollectionViewDataSource, UICollectionViewDelegate>
@property (weak, nonatomic) IBOutlet UIView *bgView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIButton *arrowBtn;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *flowLayout;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionViewHeightConstraint;
@property (copy, nonatomic) void (^ selectImageCompletion)(UIImage *image);
@property (copy, nonatomic) NSArray *models;
@property (strong, nonatomic) HXPhotoEditChartletPreviewView *currentPreview;
@property (weak, nonatomic) IBOutlet UICollectionView *titleCollectionView;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *titleFlowLayout;
@property (weak, nonatomic) IBOutlet UIVisualEffectView *titleView;
@property (strong, nonatomic) NSIndexPath *currentSelectTitleIndexPath;
@property (assign, nonatomic) CGFloat contentViewBottom;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *arrowRightConstraint;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingView;
@property (strong, nonatomic) HXPhotoEditConfiguration *configuration;
@end

@implementation HXPhotoEditChartletListView


+ (void)showEmojiViewWithConfiguration:(HXPhotoEditConfiguration *)configuration
                            completion:(void (^ _Nullable)(UIImage *image))completion {
    HXPhotoEditChartletListView *view = [HXPhotoEditChartletListView initView];
    view.selectImageCompletion = completion;
    view.configuration = configuration;
    view.frame = [UIScreen mainScreen].bounds;
    [[UIApplication sharedApplication].keyWindow addSubview:view];
    [view show];
}

+ (void)showEmojiViewWithModels:(NSArray<HXPhotoEditChartletTitleModel *> *)models
                     completion:(void (^ _Nullable)(UIImage *image))completion {
    HXPhotoEditChartletListView *view = [HXPhotoEditChartletListView initView];
    view.selectImageCompletion = completion;
    view.models = models;
    view.frame = [UIScreen mainScreen].bounds;
    [[UIApplication sharedApplication].keyWindow addSubview:view];
    [view show];
}

+ (instancetype)initView {
    return [[[NSBundle hx_photoPickerBundle] loadNibNamed:NSStringFromClass(self) owner:nil options:nil] lastObject];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.loadingView.hidesWhenStopped = YES;
    if (@available(iOS 11.0, *)){
        [self.collectionView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
        [self.titleCollectionView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
    }
    [self.arrowBtn setImage:[UIImage hx_imageContentsOfFile:@"hx_photo_edit_pull_down"] forState:UIControlStateNormal];
    self.contentViewBottomConstraint.constant = -(HXclViewHeight + hxBottomMargin);
    self.collectionViewHeightConstraint.constant = HXclViewHeight + hxBottomMargin;
    [self.bgView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hide)]];
    self.bgView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
    
    self.contentView.layer.masksToBounds = YES;
    if (HX_IOS11_Later) {
        [self.contentView hx_radiusWithRadius:8 corner:UIRectCornerTopLeft | UIRectCornerTopRight];
    }
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft) {
        self.arrowRightConstraint.constant = hxTopMargin;
        self.titleFlowLayout.sectionInset = UIEdgeInsetsMake(12.5, 20 + hxTopMargin, 12.5, 20);
    }else {
        self.titleFlowLayout.sectionInset = UIEdgeInsetsMake(12.5, 20, 12.5, 20);
    }
    
    self.titleFlowLayout.itemSize = CGSizeMake(35, 35);
    self.titleFlowLayout.minimumInteritemSpacing = 20;
    self.titleFlowLayout.minimumLineSpacing = 20;
    
    self.titleCollectionView.dataSource = self;
    self.titleCollectionView.delegate = self;
    [self.titleCollectionView registerClass:[HXPhotoEditChartletListViewCell class] forCellWithReuseIdentifier:@"HXPhotoEditChartletListViewCellId"];
    
    self.flowLayout.itemSize = CGSizeMake(HX_ScreenWidth, HXclViewHeight + hxBottomMargin);
    self.flowLayout.minimumLineSpacing = 0;
    self.flowLayout.minimumInteritemSpacing = 0;
    
    self.collectionView.pagingEnabled = YES;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([HXPhotoEditChartletContentViewCell class]) bundle:[NSBundle hx_photoPickerBundle]] forCellWithReuseIdentifier:@"HXPhotoEditChartletContentViewCellId"];
     
    
    UILongPressGestureRecognizer *longPgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureRecongizerClick:)];
    [self addGestureRecognizer:longPgr];
    
    UIPanGestureRecognizer *panPgr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panPressGestureRecongizerClick:)];
    [self.titleView addGestureRecognizer:panPgr];
    self.contentViewBottom = 0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationWillChanged) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
}
- (void)deviceOrientationWillChanged {
    [self removeFromSuperview];
}
- (void)setConfiguration:(HXPhotoEditConfiguration *)configuration {
    _configuration = configuration;
    
    if (configuration.requestChartletModels) {
        [self.loadingView startAnimating];
        HXWeakSelf
        configuration.requestChartletModels(^(NSArray<HXPhotoEditChartletTitleModel *> * _Nonnull chartletModels) {
            if (!weakSelf) {
                return;
            }
            [weakSelf.loadingView stopAnimating];
            weakSelf.models = chartletModels;
            [weakSelf.collectionView reloadData];
            [weakSelf.titleCollectionView reloadData];
        });
    }else {
        self.models = configuration.chartletModels;
    }
}
- (void)setModels:(NSArray *)models {
    _models = models;
    for (HXPhotoEditChartletTitleModel *model in models) {
        model.selected = NO;
    }
    HXPhotoEditChartletTitleModel *model = models.firstObject;
    model.selected = YES;
    self.currentSelectTitleIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
}
- (void)panPressGestureRecongizerClick:(UIPanGestureRecognizer *)panPgr {
    CGPoint point = [panPgr translationInView:self.titleView];
    if (panPgr.state == UIGestureRecognizerStateBegan) {
        CGFloat contentViewBottom = self.contentViewBottom - point.y;
        if (contentViewBottom > 0) {
            contentViewBottom = 0;
        }
        self.contentViewBottomConstraint.constant = contentViewBottom;
    }else if (panPgr.state == UIGestureRecognizerStateChanged) {
        CGFloat contentViewBottom = self.contentViewBottom - point.y;
        if (contentViewBottom > 0) {
            contentViewBottom = 0;
        }
        self.contentViewBottomConstraint.constant = contentViewBottom;
    }else if (panPgr.state == UIGestureRecognizerStateEnded ||
              panPgr.state == UIGestureRecognizerStateCancelled) {
        if (self.contentViewBottomConstraint.constant < -100.f) {
            [self hide];
        }else {
            [UIView animateWithDuration:0.15 animations:^{
                self.contentViewBottomConstraint.constant = 0;
                [self layoutIfNeeded];
            }];
        }
        self.contentViewBottom = 0;
    }
}
- (void)longPressGestureRecongizerClick:(UILongPressGestureRecognizer *)longPgr {
    CGPoint point = [longPgr locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:point];
    if (indexPath) {
        HXPhotoEditChartletContentViewCell *cell = (HXPhotoEditChartletContentViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        point = [longPgr locationInView:cell];
        point = [cell convertPoint:point toView:cell.collectionView];
        NSIndexPath *contentIndexPath = [cell.collectionView indexPathForItemAtPoint:point];
        if (contentIndexPath) {
            HXPhotoEditChartletListViewCell *contentCell = (HXPhotoEditChartletListViewCell *)[cell.collectionView cellForItemAtIndexPath:contentIndexPath];
            CGRect cellFrame = [cell.collectionView convertRect:contentCell.frame toView:self];
            CGFloat cellY = cellFrame.origin.y;
            if (cellY < self.contentView.hx_y + 60.f) {
                cellY = self.contentView.hx_y + 60.f;
            }
            CGPoint showPoint = CGPointMake(cellFrame.origin.x + cellFrame.size.width / 2, cellY);
            if (!self.currentPreview) {
                contentCell.showMask = YES;
                self.currentPreview = [self createdPreviewViewWithImage:contentCell.imageView.image point:showPoint cell:contentCell];
                [self addSubview:self.currentPreview];
                [UIView animateWithDuration:0.2 animations:^{
                    self.currentPreview.alpha = 1;
                }];
            }else {
                if (contentCell != self.currentPreview.cell) {
                    [self.currentPreview removeFromSuperview];
                    self.currentPreview = [self createdPreviewViewWithImage:contentCell.imageView.image point:showPoint cell:contentCell];
                    self.currentPreview.alpha = 1;
                    [self addSubview:self.currentPreview];
                }
            }
        }else {
            [self removePreviewView];
        }
    }else {
        [self removePreviewView];
    }
    if (longPgr.state == UIGestureRecognizerStateEnded ||
        longPgr.state == UIGestureRecognizerStateCancelled) {
        [self removePreviewView];
    }
}
- (void)removePreviewView {
    HXPhotoEditChartletPreviewView *previewView = self.currentPreview;
    previewView.cell.showMask = NO;
    [UIView animateWithDuration:0.2 animations:^{
        previewView.alpha = 0;
    } completion:^(BOOL finished) {
        [previewView removeFromSuperview];
    }];
    self.currentPreview = nil;
}
- (HXPhotoEditChartletPreviewView *)createdPreviewViewWithImage:(UIImage *)image point:(CGPoint)point cell:(HXPhotoEditChartletListViewCell *)cell {
    HXPhotoEditChartletPreviewView *preview = [HXPhotoEditChartletPreviewView showPreviewWithModel:cell.model atPoint:point];
    preview.alpha = 0;
    preview.cell = cell;
    return preview;
}
- (IBAction)pullDownBtnClick:(UIButton *)sender {
    [self hide];
}
- (void)show {
    [self layoutIfNeeded];
    [UIView animateWithDuration:0.25 animations:^{
        self.bgView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
        self.contentViewBottomConstraint.constant = 0;
        [self layoutIfNeeded];
    }];
}
- (void)hide {
    [UIView animateWithDuration:0.25 animations:^{
        self.bgView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
        self.contentViewBottomConstraint.constant = -(HXclViewHeight + hxBottomMargin);
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if (collectionView == self.titleCollectionView) {
        return 1;
    }
    return self.models.count;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (collectionView == self.titleCollectionView) {
        return self.models.count;
    }
    return 1;
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == self.collectionView) {
        HXPhotoEditChartletContentViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"HXPhotoEditChartletContentViewCellId" forIndexPath:indexPath];
        HXPhotoEditChartletTitleModel *titleModel = self.models[indexPath.section];
        cell.models = titleModel.models;
        HXWeakSelf
        cell.selectCellBlock = ^(UIImage * _Nonnull image) {
            if (weakSelf.selectImageCompletion) {
                weakSelf.selectImageCompletion(image);
            }
            [weakSelf hide];
        };
        return cell;
    }
    HXPhotoEditChartletListViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"HXPhotoEditChartletListViewCellId" forIndexPath:indexPath];
    cell.titleModel = self.models[indexPath.item];
    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == self.titleCollectionView) {
        HXPhotoEditChartletTitleModel *titleModel = self.models[indexPath.item];
        [(HXPhotoEditChartletListViewCell *)cell setShowMask:titleModel.selected isAnimate:NO];
    }
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == self.titleCollectionView) {
        if (self.currentSelectTitleIndexPath.item == indexPath.item) {
            return;
        }
        [self.collectionView setContentOffset:CGPointMake(HX_ScreenWidth * indexPath.item, 0) animated:NO];
        return;
    }
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.collectionView) {
        CGFloat width = HX_ScreenWidth;
        CGFloat offsetx = self.collectionView.contentOffset.x;
        if (self.models.count) {
            NSInteger currentIndex = (offsetx + width * 0.5) / width;
            if (currentIndex > self.models.count - 1) {
                currentIndex = self.models.count - 1;
            }
            if (currentIndex < 0) {
                currentIndex = 0;
            }
            if (self.currentSelectTitleIndexPath.item == currentIndex) {
                return;
            }
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:currentIndex inSection:0];
            HXPhotoEditChartletListViewCell *cell = (HXPhotoEditChartletListViewCell *)[self.titleCollectionView cellForItemAtIndexPath:indexPath];
            cell.showMask = YES;
            cell.titleModel.selected = YES;
            
            HXPhotoEditChartletListViewCell *selectCell = (HXPhotoEditChartletListViewCell *)[self.titleCollectionView cellForItemAtIndexPath:self.currentSelectTitleIndexPath];
            if (selectCell) {
                selectCell.showMask = NO;
                selectCell.titleModel.selected = NO;
            }else {
                HXPhotoEditChartletTitleModel *titleModel = self.models[self.currentSelectTitleIndexPath.item];
                titleModel.selected = NO;
            }
            
            self.currentSelectTitleIndexPath = indexPath;
            
            [self.titleCollectionView scrollToItemAtIndexPath:self.currentSelectTitleIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
        }
    }
}
@end

@interface HXPhotoEditChartletListViewCell ()
@property (strong, nonatomic) UIView *bgMaskView;
@property (strong, nonatomic) UIActivityIndicatorView *loadingView;
@end

@implementation HXPhotoEditChartletListViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self.contentView addSubview:self.bgMaskView];
        [self.contentView addSubview:self.imageView];
        [self.contentView addSubview:self.loadingView];
    }
    return self;
}
- (void)setTitleModel:(HXPhotoEditChartletTitleModel *)titleModel {
    _titleModel = titleModel;
    if (titleModel.type == HXPhotoEditChartletModelType_Image) {
        [self.loadingView stopAnimating];
        self.imageView.image = titleModel.image;
    }else if (titleModel.type == HXPhotoEditChartletModelType_ImageNamed) {
        [self.loadingView stopAnimating];
        UIImage *image = [UIImage hx_imageContentsOfFile:titleModel.imageNamed];
        self.imageView.image = image;
    }else if (titleModel.type == HXPhotoEditChartletModelType_NetworkURL) {
        HXWeakSelf
        if (!titleModel.loadCompletion) {
            [self.loadingView startAnimating];
        }
        [self.imageView hx_setImageWithURL:titleModel.networkURL progress:^(CGFloat progress) {
            if (progress < 1) {
                [weakSelf.loadingView startAnimating];
            }
        } completed:^(UIImage *image, NSError *error) {
            weakSelf.titleModel.loadCompletion = YES;
            [weakSelf.loadingView stopAnimating];
        }];
    }
    [self setShowMask:titleModel.selected isAnimate:NO];
    self.showMask = titleModel.selected;
}
- (void)setModel:(HXPhotoEditChartletModel *)model {
    _model = model;
    if (model.type == HXPhotoEditChartletModelType_Image) {
        [self.loadingView stopAnimating];
        self.imageView.image = model.image;
    }else if (model.type == HXPhotoEditChartletModelType_ImageNamed) {
        [self.loadingView stopAnimating];
        UIImage *image = [UIImage hx_imageContentsOfFile:model.imageNamed];
        self.imageView.image = image;
    }else if (model.type == HXPhotoEditChartletModelType_NetworkURL) {
        if (!model.loadCompletion) {
            [self.loadingView startAnimating];
        }
        HXWeakSelf
        [self.imageView hx_setImageWithURL:model.networkURL progress:^(CGFloat progress) {
            if (progress < 1) {
                [weakSelf.loadingView startAnimating];
            }
        } completed:^(UIImage *image, NSError *error) {
            weakSelf.model.loadCompletion = YES;
            [weakSelf.loadingView stopAnimating];
        }];
    }
}
- (void)setShowMask:(BOOL)showMask {
    [self setShowMask:showMask isAnimate:YES];
}
- (void)setShowMask:(BOOL)showMask isAnimate:(BOOL)isAnimate {
    _showMask = showMask;
    if (isAnimate) {
        [UIView animateWithDuration:0.2 animations:^{
            self.bgMaskView.alpha = showMask ? 1 :0;
        }];
    }else {
        self.bgMaskView.alpha = showMask ? 1 :0;
    }
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = CGRectMake(2.5, 2.5, self.hx_w - 5, self.hx_h - 5);
    self.bgMaskView.frame = CGRectMake(-5, -5, self.hx_w + 10, self.hx_h + 10);
    self.loadingView.center = CGPointMake(self.hx_w / 2, self.hx_h / 2);
    if (HX_IOS11_Earlier) {
        [self.bgMaskView hx_radiusWithRadius:5.f corner:UIRectCornerAllCorners];
    }
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.clipsToBounds = YES;
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _imageView;
}
- (UIView *)bgMaskView {
    if (!_bgMaskView) {
        _bgMaskView = [[UIView alloc] init];
        _bgMaskView.alpha = 0;
        _bgMaskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3f];
        if (HX_IOS11_Later) {
            [_bgMaskView hx_radiusWithRadius:5.f corner:UIRectCornerAllCorners];
        }
    }
    return _bgMaskView;
}
- (UIActivityIndicatorView *)loadingView {
    if (!_loadingView) {
        _loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _loadingView.hidesWhenStopped = YES;
    }
    return _loadingView;
}
@end
