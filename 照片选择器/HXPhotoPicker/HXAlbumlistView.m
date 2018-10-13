//
//  HXAlbumlistView.m
//  照片选择器
//
//  Created by 洪欣 on 2018/9/26.
//  Copyright © 2018年 洪欣. All rights reserved.
//

#import "HXAlbumlistView.h"
#import "HXPhotoManager.h"
#import "HXPhotoTools.h"

@interface HXAlbumlistView ()<UITableViewDataSource, UITableViewDelegate>
@end

@implementation HXAlbumlistView

- (instancetype)initWithManager:(HXPhotoManager *)manager {
    self = [super init];
    if (self) {
        self.manager = manager;
        [self addSubview:self.tableView];
    }
    return self;
}
- (void)setAlbumModelArray:(NSMutableArray *)albumModelArray {
    _albumModelArray = albumModelArray;
    [self.tableView reloadData];
    self.currentSelectModel = albumModelArray.firstObject;
    [self refreshCamearCount];
}
- (void)refreshCamearCount {
    NSInteger i = 0;
    for (HXAlbumModel *albumMd in self.albumModelArray) {
        albumMd.cameraCount = [self.manager cameraCount];
        if (i == 0 && !albumMd.result) {
            albumMd.tempImage = [self.manager firstCameraModel].thumbPhoto;
        }
        i++;
    }
    [self.tableView reloadData];
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:self.currentSelectModel.index inSection:0] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.albumModelArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HXAlbumlistViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([HXAlbumlistViewCell class])];
    cell.model = self.albumModelArray[indexPath.row];
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
@end

@implementation HXAlbumlistViewCell

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
- (void)setModel:(HXAlbumModel *)model {
    _model = model;
    NSInteger photoCount = model.result.count;
    if (!model.asset) {
        model.asset = model.result.lastObject;
    }
    __weak typeof(self) weakSelf = self;
    self.requestId = [HXPhotoTools getImageWithAlbumModel:model size:CGSizeMake(self.hx_h * 1.6, self.hx_h * 1.6) completion:^(UIImage *image, HXAlbumModel *model) {
        if (weakSelf.model == model) {
            weakSelf.coverView.image = image;
        }
    }];
    self.albumNameLb.text = model.albumName;
    self.countLb.text = @(photoCount + model.cameraCount).stringValue;
    if (!model.result) {
        self.coverView.image = model.tempImage ?: [HXPhotoTools hx_imageNamed:@"hx_yundian_tupian@3x.png"]; 
    }
}
- (void)setManager:(HXPhotoManager *)manager {
    _manager = manager;
    if (manager.configuration.popupTableViewCellSelectColor) {
        self.selectedBgView.backgroundColor = manager.configuration.popupTableViewCellSelectColor;
    }
    if (manager.configuration.popupTableViewCellLineColor) {
        self.lineView.backgroundColor = manager.configuration.popupTableViewCellLineColor;
    }
    if (manager.configuration.popupTableViewCellBgColor) {
        self.backgroundColor = manager.configuration.popupTableViewCellBgColor;
    }
    if (manager.configuration.popupTableViewCellAlbumNameColor) {
        self.albumNameLb.textColor = manager.configuration.popupTableViewCellAlbumNameColor;
    }
    if (manager.configuration.popupTableViewCellAlbumNameFont) {
        self.albumNameLb.font = manager.configuration.popupTableViewCellAlbumNameFont;
    }
    if (manager.configuration.popupTableViewCellPhotoCountColor) {
        self.countLb.textColor = manager.configuration.popupTableViewCellPhotoCountColor;
    }
    if (manager.configuration.popupTableViewCellPhotoCountFont) {
        self.countLb.font = manager.configuration.popupTableViewCellPhotoCountFont;
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
    self.coverView.frame = CGRectMake(12, 5, self.hx_h - 10, self.hx_h - 10);
    self.albumNameLb.hx_x = CGRectGetMaxX(self.coverView.frame) + 12;
    self.albumNameLb.hx_w = self.hx_w - self.albumNameLb.hx_x - 10;
    self.albumNameLb.hx_h = [HXPhotoTools getTextHeight:self.albumNameLb.text width:self.albumNameLb.hx_w font:self.albumNameLb.font];
    
    self.countLb.hx_x = CGRectGetMaxX(self.coverView.frame) + 12;
    self.countLb.hx_w = self.hx_w - self.countLb.hx_x - 10;
    self.countLb.hx_h = [HXPhotoTools getTextHeight:self.countLb.text width:self.countLb.hx_w font:self.countLb.font];
    
    self.albumNameLb.hx_y = self.hx_h / 2 - self.albumNameLb.hx_h - 2;
    self.countLb.hx_y = self.hx_h / 2 + 2;
    
    self.lineView.frame = CGRectMake(12, self.hx_h - 0.5f, self.hx_w - 12, 0.5f);
}
- (UIView *)selectedBgView {
    if (!_selectedBgView) {
        _selectedBgView = [[UIView alloc] init];
        _selectedBgView.backgroundColor = [UIColor colorWithRed:0.93 green:0.93 blue:0.93 alpha:1.f];
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
        _albumNameLb.textColor = [UIColor blackColor];
        _albumNameLb.font = [UIFont systemFontOfSize:14];
    }
    return _albumNameLb;
}
- (UILabel *)countLb {
    if (!_countLb) {
        _countLb = [[UILabel alloc] init];
        _countLb.textColor = [UIColor blackColor];
        _countLb.font = [UIFont systemFontOfSize:13];
    }
    return _countLb;
}
- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc] init];
        _lineView.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.f];
    }
    return _lineView;
}
@end


@interface HXAlbumTitleView ()
@property (strong, nonatomic) UIImageView *arrowIcon;
@property (strong, nonatomic) UILabel *titleLb;
@property (strong, nonatomic) UIButton *button;
@end

@implementation HXAlbumTitleView
- (instancetype)initWithManager:(HXPhotoManager *)manager {
    self = [super init];
    if (self) {
        self.manager = manager;
        if (manager.configuration.navigationTitleSynchColor) {
            self.titleLb.textColor = manager.configuration.themeColor;
            self.arrowIcon.tintColor = manager.configuration.themeColor;
        }else {
            if (manager.configuration.navigationTitleColor) {
                self.titleLb.textColor = manager.configuration.navigationTitleColor;
                self.arrowIcon.tintColor = manager.configuration.navigationTitleColor;
            }
        }
        if (manager.configuration.navigationTitleColor) {
            self.titleLb.textColor = manager.configuration.navigationTitleColor;
            self.arrowIcon.tintColor = manager.configuration.navigationTitleColor;
        }
        [self addSubview:self.titleLb];
        [self addSubview:self.arrowIcon];
        [self addSubview:self.button];
    }
    return self;
}
- (void)setModel:(HXAlbumModel *)model {
    _model = model;
    self.titleLb.text = model.albumName;
    CGFloat textWidth = [HXPhotoTools getTextWidth:self.titleLb.text height:20 font:[UIFont boldSystemFontOfSize:17]];
    if (textWidth > [UIScreen mainScreen].bounds.size.width - 120) {
        textWidth = [UIScreen mainScreen].bounds.size.width - 120;
    }
    self.titleLb.hx_w = textWidth;
    self.frame = CGRectMake(0, 0, self.titleLb.hx_w + (3 + self.arrowIcon.hx_w) * 2, 30);
} 
- (BOOL)selected {
    return self.button.selected;
}
- (void)setupAlpha:(BOOL)anima {
    if (anima) {
        [UIView animateWithDuration:0.1 animations:^{
            self.titleLb.alpha = 1;
            self.arrowIcon.alpha = 1;
        }];
    }else {
        self.titleLb.alpha = 1;
        self.arrowIcon.alpha = 1;
    }
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.titleLb.hx_h = 20;
    self.titleLb.center = CGPointMake(self.hx_w / 2, self.hx_h / 2);
    self.arrowIcon.center = CGPointMake(0, self.hx_h / 2);
    self.arrowIcon.hx_x = CGRectGetMaxX(self.titleLb.frame) + 3;
    self.button.frame = self.bounds;
}
- (UILabel *)titleLb {
    if (!_titleLb) {
        _titleLb = [[UILabel alloc] init];
        _titleLb.font = [UIFont boldSystemFontOfSize:17];
        _titleLb.textAlignment = NSTextAlignmentCenter;
        _titleLb.textColor = [UIColor blackColor];
        _titleLb.alpha = 0;
    }
    return _titleLb;
}
- (UIImageView *)arrowIcon {
    if (!_arrowIcon) {
        _arrowIcon = [[UIImageView alloc] initWithImage:[[HXPhotoTools hx_imageNamed:@"hx_nav_arrow_down@2x.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        _arrowIcon.hx_size = _arrowIcon.image.size;
        _arrowIcon.tintColor = [UIColor blackColor];
        _arrowIcon.alpha = 0;
    }
    return _arrowIcon;
}
- (UIButton *)button {
    if (!_button) {
        _button = [UIButton buttonWithType:UIButtonTypeCustom];
        [_button addTarget:self action:@selector(didBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _button;
} 
- (void)didBtnClick:(UIButton *)button {
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
