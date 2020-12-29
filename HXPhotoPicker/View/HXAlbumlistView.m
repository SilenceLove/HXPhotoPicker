//
//  HXAlbumlistView.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2018/9/26.
//  Copyright © 2018年 Silence. All rights reserved.
//

#import "HXAlbumlistView.h"
#import "HXPhotoManager.h"
#import "HXPhotoTools.h"
#import "UIButton+HXExtension.h"
#import "UIView+HXExtension.h"
#import "UIColor+HXExtension.h"
#import "HXAssetManager.h"

@interface HXAlbumlistView ()<UITableViewDataSource, UITableViewDelegate>
@property (assign, nonatomic) BOOL cellCanSetModel;
@property (copy, nonatomic) NSArray *tableVisibleCells;
@property (strong, nonatomic) NSMutableArray *deleteCellArray;
@end

@implementation HXAlbumlistView
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            self.tableView.backgroundColor = [HXPhotoCommon photoCommon].isDark ? [UIColor colorWithRed:0.125 green:0.125 blue:0.125 alpha:1] : self.manager.configuration.popupTableViewBgColor;
        }
    }
#endif
}
- (instancetype)initWithManager:(HXPhotoManager *)manager {
    self = [super init];
    if (self) {
        self.cellCanSetModel = YES;
        self.manager = manager;
        self.tableView.backgroundColor = [HXPhotoCommon photoCommon].isDark ? [UIColor colorWithRed:0.125 green:0.125 blue:0.125 alpha:1] : self.manager.configuration.popupTableViewBgColor;
        [self addSubview:self.tableView];
    }
    return self;
}
- (void)setAlbumModelArray:(NSMutableArray *)albumModelArray {
    _albumModelArray = albumModelArray;
    self.currentSelectModel = albumModelArray.firstObject;
}
- (void)selectCellScrollToCenter {
    if (!self.currentSelectModel) {
        return;
    }
    if (self.albumModelArray.count <= self.currentSelectModel.index) {
        return;
    }
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.currentSelectModel.index inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
}
- (void)refreshCamearCount {
    if (!self.albumModelArray.count) {
        return;;
    }
    HXAlbumModel *albumMd = self.albumModelArray.firstObject;
    albumMd.cameraCount = self.manager.cameraCount;
    if (!albumMd.assetResult && !albumMd.localIdentifier) {
        albumMd.tempImage = [self.manager firstCameraModel].thumbPhoto;
    }
    self.cellCanSetModel = NO;
    [self.tableView reloadData];
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:self.currentSelectModel.index inSection:0] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    dispatch_async(dispatch_get_main_queue(),^{
        self.deleteCellArray = [NSMutableArray array];
        self.tableVisibleCells = [self.tableView.visibleCells sortedArrayUsingComparator:^NSComparisonResult(HXAlbumlistViewCell *obj1, HXAlbumlistViewCell *obj2) {
            // visibleCells 这个数组的数据顺序是乱的，所以在获取image之前先将可见cell排序
            NSIndexPath *indexPath1 = [self.tableView indexPathForCell:obj1];
            NSIndexPath *indexPath2 = [self.tableView indexPathForCell:obj2];
            if (indexPath1.item > indexPath2.item) {
                return NSOrderedDescending;
            }else {
                return NSOrderedAscending;
            }
        }];
        [self cellSetModelData:self.tableVisibleCells.firstObject];
    });
}
- (void)reloadAlbumAssetCountWithAlbumModel:(HXAlbumModel *)model {
    if (!model || !self.albumModelArray.count) {
        return;
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:model.index inSection:0];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:0];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
}
- (void)cellSetModelData:(HXAlbumlistViewCell *)cell {
    if ([cell isKindOfClass:[HXAlbumlistViewCell class]]) {
        HXWeakSelf
        [cell setAlbumImageWithCompletion:^(NSInteger count, HXAlbumlistViewCell *myCell) {
            if (count <= 0 && cell.model.index > 0) {
                if ([weakSelf.albumModelArray containsObject:myCell.model]) {
                    [weakSelf.albumModelArray removeObject:myCell.model];
                    [weakSelf.deleteCellArray addObject:[weakSelf.tableView indexPathForCell:myCell]];
                }
            }
            [weakSelf setCellModel:myCell];
        }];
    }else {
        [self setCellModel:cell];
    }
}
- (void)setCellModel:(HXAlbumlistViewCell *)cell {
    NSInteger count = self.tableVisibleCells.count;
    NSInteger index = [self.tableVisibleCells indexOfObject:cell];
    if (index < count - 1) {
        [self cellSetModelData:self.tableVisibleCells[index + 1]];
    }else {
        self.cellCanSetModel = YES;
        self.tableVisibleCells = nil;
        if (self.deleteCellArray.count) {
            [self.tableView deleteRowsAtIndexPaths:self.deleteCellArray withRowAnimation:UITableViewRowAnimationFade];
        }
        [self.deleteCellArray removeAllObjects];
        self.deleteCellArray = nil;
    }
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.albumModelArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HXAlbumlistViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([HXAlbumlistViewCell class])];
    cell.model = self.albumModelArray[indexPath.row];
    cell.configuration = self.manager.configuration;
    HXWeakSelf
    if (self.cellCanSetModel) {
        [cell setAlbumImageWithCompletion:^(NSInteger count, HXAlbumlistViewCell *myCell) {
            if (count <= 0) {
                if ([weakSelf.albumModelArray containsObject:myCell.model]) {
                    NSIndexPath *myIndexPath = [weakSelf.tableView indexPathForCell:myCell];
                    if (myIndexPath) {
                        [weakSelf.albumModelArray removeObject:myCell.model];
                        [weakSelf.tableView deleteRowsAtIndexPaths:@[myIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                    }
                }
            }
        }];
    }
        
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    HXAlbumModel *model = self.albumModelArray[indexPath.row];
    self.currentSelectModel = model;
    if (self.didSelectRowBlock) {
        self.didSelectRowBlock(model);
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.manager.configuration.popupTableViewCellHeight;
}
- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [(HXAlbumlistViewCell *)cell cancelRequest];
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.tableView.frame = self.bounds;
}
- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.estimatedRowHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
#ifdef __IPHONE_11_0
        if (@available(iOS 11.0, *)) {
            _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
#else
            if ((NO)) {
#endif
            }
        [_tableView registerClass:[HXAlbumlistViewCell class] forCellReuseIdentifier:NSStringFromClass([HXAlbumlistViewCell class])];
    }
    return _tableView;
}

@end

@interface HXAlbumlistViewCell ()
@property (strong, nonatomic) UIImageView *coverView;
@property (strong, nonatomic) UILabel *albumNameLb;
@property (strong, nonatomic) UILabel *countLb;
@property (assign, nonatomic) PHImageRequestID requestId;
@property (strong, nonatomic) UIView *lineView;
@property (strong, nonatomic) UIView *selectedBgView;
@property (strong, nonatomic) UIImageView *selectIcon;
@end

@implementation HXAlbumlistViewCell
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self setConfiguration:self.configuration];
        }
    }
#endif
}
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectedBackgroundView = self.selectedBgView;
        [self.contentView addSubview:self.coverView];
        [self.contentView addSubview:self.albumNameLb];
        [self.contentView addSubview:self.countLb];
        [self.contentView addSubview:self.lineView];
    }
    return self;
}
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    UIColor *selectedBgColor;
    if (self.configuration.popupTableViewCellSelectColor) {
        selectedBgColor = self.configuration.popupTableViewCellSelectColor;
    }else {
        selectedBgColor = [UIColor colorWithRed:0.93 green:0.93 blue:0.93 alpha:1.f];
    }
    self.selectedBgView.backgroundColor = highlighted ? (self.configuration.popupTableViewCellHighlightedColor ?: selectedBgColor) : selectedBgColor;
    if (!self.selected && self.configuration.popupTableViewCellSelectIconColor) {
        self.selectIcon.hidden = highlighted;
    }
}
- (void)setModel:(HXAlbumModel *)model {
    _model = model;
    self.albumNameLb.text = self.model.albumName;
}
- (void)setAlbumImageWithCompletion:(void (^)(NSInteger, HXAlbumlistViewCell *))completion {
    HXWeakSelf
    if (!self.model.assetResult && self.model.localIdentifier) {
        [self.model getResultWithCompletion:^(HXAlbumModel *albumModel) {
            if (albumModel == weakSelf.model) {
                [weakSelf getAlbumImageWithCompletion:^(UIImage *image, PHAsset *asset) {
                    NSInteger photoCount = weakSelf.model.count;
                    if (completion) {
                        completion(photoCount + weakSelf.model.cameraCount, weakSelf);
                    }
                }];
            }
        }];
    }else {
        [self getAlbumImageWithCompletion:^(UIImage *image, PHAsset *asset) {
            NSInteger photoCount = weakSelf.model.count;
            if (completion) {
                completion(photoCount + weakSelf.model.cameraCount, weakSelf);
            }
        }];
    }
    if (!self.model.assetResult || !self.model.count) {
        self.coverView.image = self.model.tempImage ?: [UIImage hx_imageNamed:@"hx_yundian_tupian"];
    }
}
- (void)getAlbumImageWithCompletion:(void (^)(UIImage *image, PHAsset *asset))completion {
    NSInteger photoCount = self.model.count + self.model.cameraCount;
    PHAsset *coverAsset = self.model.assetResult.lastObject;
    if (self.model.needReloadCount && photoCount != self.model.realCount) {
        coverAsset = self.model.realCoverAsset;
        photoCount = self.model.realCount;
    }
    self.countLb.text = @(photoCount).stringValue;
    HXWeakSelf
    if (coverAsset) {
        self.requestId = [HXAssetManager requestThumbnailImageForAsset:coverAsset targetWidth:self.hx_h * 1.4 completion:^(UIImage * _Nonnull result, NSDictionary<NSString *,id> * _Nonnull info) {
            if (weakSelf.model.assetResult.lastObject == coverAsset && result) {
                weakSelf.coverView.image = result;
            }
            if (completion && result) {
                completion(result, coverAsset);
            }
        }];
    }
}
- (void)setConfiguration:(HXPhotoConfiguration *)configuration {
    _configuration = configuration;
    if ([HXPhotoCommon photoCommon].isDark) {
        if (configuration.popupTableViewCellSelectColor != [UIColor clearColor]) {
            self.selectedBgView.backgroundColor = [UIColor hx_colorWithHexStr:@"#2E2F30"];
        }
        self.lineView.backgroundColor = [[UIColor hx_colorWithHexStr:@"#434344"] colorWithAlphaComponent:0.6];
        self.backgroundColor = [UIColor hx_colorWithHexStr:@"#2E2F30"];
        self.albumNameLb.textColor = [UIColor whiteColor];
        self.countLb.textColor = [UIColor whiteColor];
        if (configuration.popupTableViewCellSelectIconColor) {
            self.selectIcon.tintColor = [UIColor whiteColor];
        }
    }else {
        if (configuration.popupTableViewCellSelectColor) {
            self.selectedBgView.backgroundColor = configuration.popupTableViewCellSelectColor;
        }else {
            self.selectedBgView.backgroundColor = [UIColor colorWithRed:0.93 green:0.93 blue:0.93 alpha:1.f];
        }
        if (configuration.popupTableViewCellLineColor) {
            self.lineView.backgroundColor = configuration.popupTableViewCellLineColor;
        }else {
            self.lineView.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.f];
        }
        if (configuration.popupTableViewCellBgColor) {
            self.backgroundColor = configuration.popupTableViewCellBgColor;
        }else {
            self.backgroundColor = nil;
        }
        if (configuration.popupTableViewCellAlbumNameColor) {
            self.albumNameLb.textColor = configuration.popupTableViewCellAlbumNameColor;
        }else {
            self.albumNameLb.textColor = [UIColor blackColor];
        }
        if (configuration.popupTableViewCellPhotoCountColor) {
            self.countLb.textColor = configuration.popupTableViewCellPhotoCountColor;
        }else {
            self.countLb.textColor = [UIColor blackColor];
        }
        if (configuration.popupTableViewCellSelectIconColor) {
            self.selectIcon.tintColor = configuration.popupTableViewCellSelectIconColor;
        }else {
            self.selectIcon.hidden = YES;;
        }
    }
    if (configuration.popupTableViewCellPhotoCountFont) {
        self.countLb.font = configuration.popupTableViewCellPhotoCountFont;
    }else {
        self.countLb.font = [UIFont systemFontOfSize:13];
    }
    if (configuration.popupTableViewCellAlbumNameFont) {
        self.albumNameLb.font = configuration.popupTableViewCellAlbumNameFont;
    }else {
        self.albumNameLb.font = [UIFont systemFontOfSize:14];
    }
}
- (void)cancelRequest {
    if (self.requestId) {
        [[PHImageManager defaultManager] cancelImageRequest:self.requestId];
        self.requestId = -1;
    }
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.selectedBgView.frame = self.bounds;
    
    self.selectIcon.hx_x = self.hx_w - 20 - self.selectIcon.hx_w;
    self.selectIcon.hx_centerY = self.hx_h / 2;
    
    self.coverView.frame = CGRectMake(12, 5, self.hx_h - 10, self.hx_h - 10);
    self.albumNameLb.hx_x = CGRectGetMaxX(self.coverView.frame) + 12;
    self.albumNameLb.hx_w = self.selectIcon.hx_x - self.albumNameLb.hx_x - 10;
    self.albumNameLb.hx_h = self.albumNameLb.hx_getTextHeight;
    
    self.countLb.hx_x = CGRectGetMaxX(self.coverView.frame) + 12;
    self.countLb.hx_w = self.hx_w - self.countLb.hx_x - 10;
    self.countLb.hx_h = 14;
    
    self.albumNameLb.hx_y = self.hx_h / 2 - self.albumNameLb.hx_h - 2;
    self.countLb.hx_y = self.hx_h / 2 + 2;
    
    self.lineView.frame = CGRectMake(12, self.hx_h - 0.5f, self.hx_w - 12, 0.5f);
}
- (UIView *)selectedBgView {
    if (!_selectedBgView) {
        _selectedBgView = [[UIView alloc] init];
        [_selectedBgView addSubview:self.selectIcon];
    }
    return _selectedBgView;
}
- (UIImageView *)coverView {
    if (!_coverView) {
        _coverView = [[UIImageView alloc] init];
        _coverView.clipsToBounds = YES;
        _coverView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _coverView;
}
- (UILabel *)albumNameLb {
    if (!_albumNameLb) {
        _albumNameLb = [[UILabel alloc] init];
    }
    return _albumNameLb;
}
- (UILabel *)countLb {
    if (!_countLb) {
        _countLb = [[UILabel alloc] init];
    }
    return _countLb;
}
- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc] init];
    }
    return _lineView;
}
- (UIImageView *)selectIcon {
    if (!_selectIcon) {
        UIImage *image = [[UIImage hx_imageNamed:@"hx_photo_edit_clip_confirm"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _selectIcon = [[UIImageView alloc] initWithImage:image];
        _selectIcon.hx_size = CGSizeMake(image.size.width * 0.75, image.size.height * 0.75);;
    }
    return _selectIcon;
}
@end


@interface HXAlbumTitleView ()
@property (strong, nonatomic) UIView *contentView;
@property (strong, nonatomic) UIImageView *arrowIcon;
@property (strong, nonatomic) UILabel *titleLb;
@property (strong, nonatomic) HXAlbumTitleButton *button;
@end

@implementation HXAlbumTitleView
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
- (instancetype)initWithManager:(HXPhotoManager *)manager {
    self = [super init];
    if (self) {
        self.canSelect = NO;
        self.manager = manager;
        [self addSubview:self.contentView];
        [self addSubview:self.button];
        if (HX_IOS11_Later) {
            if (self.manager.configuration.type == HXConfigurationTypeWXChat ||
                self.manager.configuration.type == HXConfigurationTypeWXMoment) {
                self.contentView.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.3];
                [self.contentView hx_radiusWithRadius:15 corner:UIRectCornerAllCorners];
            }
        }
        [self changeColor];
        self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width - 120, 30);
        self.contentView.hx_h = 30;
        self.titleLb.hx_centerY = self.hx_h / 2;
        self.arrowIcon.hx_centerY = self.titleLb.hx_centerY;
        [self setTitleFrame];
    }
    return self;
}
- (void)changeColor {
    UIColor *themeColor;
    UIColor *navigationTitleColor;
    UIColor *navigationTitleArrowColor;
    if ([HXPhotoCommon photoCommon].isDark) {
        themeColor = [UIColor whiteColor];
        navigationTitleColor = [UIColor whiteColor];
        navigationTitleArrowColor = self.manager.configuration.navigationTitleArrowDarkColor;
    }else {
        themeColor = self.manager.configuration.themeColor;
        navigationTitleColor = self.manager.configuration.navigationTitleColor;
        navigationTitleArrowColor = self.manager.configuration.navigationTitleArrowColor;
    }
    if (self.manager.configuration.navigationTitleSynchColor) {
        self.titleLb.textColor = themeColor;
        self.arrowIcon.tintColor = navigationTitleArrowColor ?: themeColor;
    }else {
        self.titleLb.textColor = [UIColor blackColor];
        self.arrowIcon.tintColor = navigationTitleArrowColor ?: [UIColor blackColor];
    }
    if (navigationTitleColor) {
        self.titleLb.textColor = navigationTitleColor;
        self.arrowIcon.tintColor = navigationTitleArrowColor ?: navigationTitleColor;
    }
}
- (void)setModel:(HXAlbumModel *)model {
    _model = model;
    CGFloat maxWidth = [self getTextWidth:140];
    self.titleLb.text = model.albumName ?: [NSBundle hx_localizedStringForKey:@"相册"];
    CGFloat textWidth = self.titleLb.hx_getTextWidth;
    if (textWidth > maxWidth) {
        textWidth = maxWidth;
    }
    [UIView animateWithDuration:0.25 animations:^{
        self.titleLb.hx_w = textWidth;
        [self setTitleFrame];
    }];
}
- (CGFloat)getTextWidth:(CGFloat)margin {
    CGFloat maxWidth = [UIScreen mainScreen].bounds.size.width - margin - 10 - 5 - self.arrowIcon.hx_w - (30 - self.arrowIcon.hx_h) / 2;
//    CGFloat textWidth = self.titleLb.hx_getTextWidth;
//    if (textWidth > maxWidth) {
//        textWidth = maxWidth;
//    }
    return maxWidth;
}
- (void)setSubViewFrame {
    CGFloat width = self.titleLb.hx_w + 5 + self.arrowIcon.hx_w + 10 + (30 - self.arrowIcon.hx_h) / 2;
    self.titleLb.hx_x = 10;
    self.arrowIcon.hx_x = CGRectGetMaxX(self.titleLb.frame) + 5;
    self.contentView.hx_w = width;
    self.contentView.hx_centerX = self.hx_w / 2;
}
- (void)setTitleFrame {
    [self setSubViewFrame];
    if (self.superview) {
        if ([self.superview isKindOfClass:NSClassFromString(@"_UITAMICAdaptorView")]) {
            [self setupContentViewFrame];
        }
    }
}
- (BOOL)selected {
    return self.button.selected;
}
- (void)setupContentViewFrame {
    BOOL canSet = self.superview && [self.superview isKindOfClass:NSClassFromString(@"_UITAMICAdaptorView")];
    if (canSet) {
        // 让按钮在屏幕中间
        CGFloat temp_x = self.superview.hx_x + self.contentView.hx_x;
        CGFloat windowWidth = [UIApplication sharedApplication].keyWindow.hx_w;
        CGFloat w_x = (windowWidth - self.contentView.hx_w) / 2;
        if (temp_x > w_x) {
            CGFloat difference = temp_x - w_x;
            if (self.contentView.hx_x - difference >= 0) {
                self.contentView.hx_x -= difference;
            }else {
                self.contentView.hx_x = 0;
            }
        }else {
            CGFloat difference = w_x - temp_x;
            self.contentView.hx_x += difference;
        }
    }
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.button.frame = self.bounds;
    [self setupContentViewFrame];
    if (HX_IOS11_Earlier) {
        if (self.manager.configuration.type == HXConfigurationTypeWXChat ||
            self.manager.configuration.type == HXConfigurationTypeWXMoment) {
            self.contentView.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.3];
            [self.contentView hx_radiusWithRadius:15 corner:UIRectCornerAllCorners];
        }
    }
}
- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        [_contentView addSubview:self.titleLb];
        [_contentView addSubview:self.arrowIcon];
    }
    return _contentView;
}
- (UILabel *)titleLb {
    if (!_titleLb) {
        _titleLb = [[UILabel alloc] init];
        _titleLb.text = [NSBundle hx_localizedStringForKey:@"相册"];
        CGFloat textWidth = self.titleLb.hx_getTextWidth;
        _titleLb.hx_w = textWidth;
        _titleLb.hx_h = 30;
        _titleLb.font = [UIFont boldSystemFontOfSize:17];
        _titleLb.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLb;
}
- (UIImageView *)arrowIcon {
    if (!_arrowIcon) {
        NSString *imagenamed;
        if (self.manager.configuration.type == HXConfigurationTypeWXChat ||
            self.manager.configuration.type == HXConfigurationTypeWXMoment) {
                imagenamed = @"hx_nav_title_down";
        }else {
            imagenamed = @"hx_nav_arrow_down";
        }
        _arrowIcon = [[UIImageView alloc] initWithImage:[[UIImage hx_imageNamed:imagenamed] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        _arrowIcon.hx_size = _arrowIcon.image.size;
    }
    return _arrowIcon;
}
- (HXAlbumTitleButton *)button {
    if (!_button) {
        _button = [HXAlbumTitleButton buttonWithType:UIButtonTypeCustom];
        [_button addTarget:self action:@selector(didBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        HXWeakSelf
        _button.highlightedBlock = ^(BOOL highlighted) {
            UIColor *color = [UIColor blackColor];
            UIColor *themeColor;
            UIColor *navigationTitleColor;
            UIColor *navigationTitleArrowColor;
            if ([HXPhotoCommon photoCommon].isDark) {
                themeColor = [UIColor whiteColor];
                navigationTitleColor = [UIColor whiteColor];
                navigationTitleArrowColor = weakSelf.manager.configuration.navigationTitleArrowDarkColor;
            }else {
                themeColor = weakSelf.manager.configuration.themeColor;
                navigationTitleColor = weakSelf.manager.configuration.navigationTitleColor;
                navigationTitleArrowColor = weakSelf.manager.configuration.navigationTitleArrowColor;
            }
            if (weakSelf.manager.configuration.navigationTitleSynchColor) {
                color = themeColor;
            }
            if (navigationTitleColor) {
                color = navigationTitleColor;
            }
            UIColor *arrowColor = navigationTitleArrowColor ?: color;
            weakSelf.titleLb.textColor = highlighted ? [color colorWithAlphaComponent:0.5f] : color;
            weakSelf.arrowIcon.tintColor = highlighted ? [arrowColor colorWithAlphaComponent:0.5f] : arrowColor;
        };
    }
    return _button;
} 
- (void)didBtnClick:(UIButton *)button {
    if (!self.canSelect) {
        return;
    }
    if (!self.model) {
        return;
    }
    button.selected = !button.isSelected;
    button.userInteractionEnabled = NO;
    if (button.selected) {
        [UIView animateWithDuration:0.25 animations:^{
            self.arrowIcon.transform = CGAffineTransformMakeRotation(M_PI);
        } completion:^(BOOL finished) {
            button.userInteractionEnabled = YES;
        }];
    }else {
        [UIView animateWithDuration:0.25 animations:^{
            self.arrowIcon.transform = CGAffineTransformMakeRotation(2 * M_PI);
        } completion:^(BOOL finished) {
            button.userInteractionEnabled = YES;
        }];
    }
    if (self.didTitleViewBlock) {
        self.didTitleViewBlock(button.selected);
    }
}
- (void)deSelect {
    [self didBtnClick:self.button];
}
@end

@implementation HXAlbumTitleButton

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    if (self.highlightedBlock) {
        self.highlightedBlock(highlighted);
    }
}
    
@end
