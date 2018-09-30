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
@property (strong, nonatomic) UITableView *tableView;
@end

@implementation HXAlbumlistView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.tableView];
    }
    return self;
}
- (void)setAlbumModelArray:(NSMutableArray *)albumModelArray {
    _albumModelArray = albumModelArray;
    [self.tableView reloadData];
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES scrollPosition:0];
}
- (void)setManager:(HXPhotoManager *)manager {
    _manager = manager;
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
    
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
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
@end

@implementation HXAlbumlistViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self.contentView addSubview:self.coverView];
        [self.contentView addSubview:self.albumNameLb];
        [self.contentView addSubview:self.countLb];
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
- (void)cancelRequest {
    if (self.requestId) {
        [[PHImageManager defaultManager] cancelImageRequest:self.requestId];
        self.requestId = -1;
    }
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.coverView.frame = CGRectMake(12, 5, self.hx_h - 10, self.hx_h - 10);
    self.albumNameLb.hx_x = CGRectGetMaxX(self.coverView.frame) + 12;
    self.albumNameLb.hx_w = self.hx_w - self.albumNameLb.hx_x - 10;
    self.albumNameLb.hx_h = 15;
    
    self.countLb.hx_x = CGRectGetMaxX(self.coverView.frame) + 12;
    self.countLb.hx_w = self.hx_w - self.countLb.hx_x - 10;
    self.countLb.hx_h = 14;
    
    self.albumNameLb.hx_y = self.hx_h / 2 - self.albumNameLb.hx_h - 2;
    self.countLb.hx_y = self.hx_h / 2 + 2;
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
@end


@interface HXAlbumTitleView ()
@property (strong, nonatomic) UIImageView *arrowIcon;
@property (strong, nonatomic) UILabel *titleLb;
@end

@implementation HXAlbumTitleView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.titleLb];
        [self addSubview:self.arrowIcon];
    }
    return self;
}
- (void)setManager:(HXPhotoManager *)manager {
    _manager = manager;
    if (manager.configuration.navigationTitleColor) {
        self.titleLb.textColor = manager.configuration.navigationTitleColor;
        self.arrowIcon.tintColor = manager.configuration.navigationTitleColor;
    }
}
- (void)setModel:(HXAlbumModel *)model {
    _model = model;
    self.titleLb.text = model.albumName;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.titleLb.hx_h = 20;
    self.titleLb.hx_w = [HXPhotoTools getTextWidth:self.titleLb.text height:20 fontSize:17];
    self.titleLb.center = CGPointMake(self.hx_w / 2, self.hx_h / 2);
    
    self.arrowIcon.center = CGPointMake(0, self.hx_h / 2);
    self.arrowIcon.hx_x = CGRectGetMaxX(self.titleLb.frame) + 5;
}
- (UILabel *)titleLb {
    if (!_titleLb) {
        _titleLb = [[UILabel alloc] init];
        _titleLb.font = [UIFont systemFontOfSize:17];
        _titleLb.textAlignment = NSTextAlignmentCenter;
        _titleLb.textColor = [UIColor blackColor];
    }
    return _titleLb;
}
- (UIImageView *)arrowIcon {
    if (!_arrowIcon) {
        _arrowIcon = [[UIImageView alloc] initWithImage:[[HXPhotoTools hx_imageNamed:@"hx_nav_arrow_down@2x.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        _arrowIcon.hx_size = _arrowIcon.image.size;
        _arrowIcon.tintColor = [UIColor blackColor];
    }
    return _arrowIcon;
}

@end
