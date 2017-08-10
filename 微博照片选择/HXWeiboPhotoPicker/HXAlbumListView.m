//
//  HXAlbumListView.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/8.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXAlbumListView.h"
#import "HXPhotoTools.h"
#import "HXPhotoManager.h"
@interface HXAlbumListView ()<UITableViewDelegate,UITableViewDataSource>
@property (strong, nonatomic) HXPhotoManager *manager;
@end

@implementation HXAlbumListView

- (instancetype)initWithFrame:(CGRect)frame manager:(HXPhotoManager *)manager {
    self = [super initWithFrame:frame];
    if (self) {
        self.manager = manager;
        self.currentIndex = 0;
        [self setup];
    }
    return self;
}

- (void)setup {
    self.backgroundColor = self.manager.UIManager.albumViewBgColor;
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, width, height) style:UITableViewStylePlain];
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.backgroundColor = self.backgroundColor = self.manager.UIManager.albumViewBgColor;
    [tableView registerClass:[HXAlbumListViewCell class] forCellReuseIdentifier:@"cellId"];
    [self addSubview:tableView];
    self.tableView = tableView;
}

- (void)setList:(NSArray *)list {
    _list = list;
    
    [self.tableView reloadData];
    if (self.currentIndex < list.count) {
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:self.currentIndex inSection:0] animated:NO scrollPosition:UITableViewScrollPositionMiddle];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.list.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HXAlbumListViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellId"];
    cell.manager = self.manager;
    cell.model = self.list[indexPath.row];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.currentIndex = indexPath.row;
    if ([self.delegate respondsToSelector:@selector(didTableViewCellClick:animate:)]) {
        [self.delegate didTableViewCellClick:self.list[indexPath.row] animate:YES];
    }
}

@end

@interface HXAlbumListViewCell ()
@property (strong, nonatomic) UIImageView *photoView;
@property (strong, nonatomic) UILabel *photoName;
@property (strong, nonatomic) UILabel *photoNum;
@property (strong, nonatomic) UIImageView *numIcon;
@property (strong, nonatomic) UIView *selectedView;
@end

@implementation HXAlbumListViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setup];
    }
    return self;
}
#pragma mark - < 懒加载 >
- (UIImageView *)photoView {
    if (!_photoView) {
        _photoView = [[UIImageView alloc] init];
        _photoView.contentMode = UIViewContentModeScaleAspectFill;
        _photoView.clipsToBounds = YES;
    }
    return _photoView;
}
- (UILabel *)photoName {
    if (!_photoName) {
        _photoName = [[UILabel alloc] init];
        _photoName.font = [UIFont systemFontOfSize:17];
    }
    return _photoName;
}
- (UILabel *)photoNum {
    if (!_photoNum) {
        _photoNum = [[UILabel alloc] init];
        _photoNum.font = [UIFont systemFontOfSize:12];
    }
    return _photoNum;
}
- (UIImageView *)numIcon {
    if (!_numIcon) {
        _numIcon = [[UIImageView alloc] init];
    }
    return _numIcon;
}
- (UIView *)selectedView {
    if (!_selectedView) {
        _selectedView = [[UIView alloc] init];
    }
    return _selectedView;
}
- (void)setup {
    [self.contentView addSubview:self.photoView];
    [self.contentView addSubview:self.photoName];
    [self.contentView addSubview:self.photoNum];
    [self.photoView addSubview:self.numIcon];
}
- (void)setManager:(HXPhotoManager *)manager {
    _manager = manager;
    if (manager.UIManager.albumViewCellSelectedColor) {
        self.selectedView.backgroundColor = manager.UIManager.albumViewCellSelectedColor;
        self.selectedBackgroundView = self.selectedView;
    }
    self.photoName.textColor = manager.UIManager.albumNameTitleColor;
    self.photoNum.textColor = manager.UIManager.photosNumberTitleColor;
    if (!self.numIcon.image) {
        self.numIcon.image = [HXPhotoTools hx_imageNamed:manager.UIManager.albumViewSelectImageName];
    }
    self.backgroundColor = manager.UIManager.albumViewBgColor;
}
- (void)setModel:(HXAlbumModel *)model {
    _model = model;
    
    __weak typeof(self) weakSelf = self;
    if (!model.asset) {
        model.asset = model.result.lastObject;
        model.albumImage = nil;
    }
    if (model.albumImage) {
        self.photoView.image = model.albumImage;
    }else {
        [HXPhotoTools getPhotoForPHAsset:model.asset size:CGSizeMake(60, 60) completion:^(UIImage *image, NSDictionary *info) {
            weakSelf.photoView.image = image;
            model.albumImage = image;
        }];
    }
    
    self.photoName.text = model.albumName;
    self.photoNum.text = [NSString stringWithFormat:@"%ld",(long)model.count];
    if (model.selectedCount > 0) {
        self.numIcon.hidden = NO;
    }else {
        self.numIcon.hidden = YES;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    
    self.photoView.frame = CGRectMake(10, 5, 50, 50);
    
    CGFloat photoNameX = CGRectGetMaxX(self.photoView.frame) + 10;
    CGFloat photoNameWith = self.model.albumNameWidth;
    if (photoNameWith > width - photoNameX - 50) {
        photoNameWith = width - photoNameX - 50;
    }
    self.photoName.frame = CGRectMake(photoNameX, 0, photoNameWith, 18);
    self.photoName.center = CGPointMake(self.photoName.center.x, height / 2);
    
    CGFloat photoNumX = CGRectGetMaxX(self.photoName.frame) + 5;
    CGFloat photoNumWidth = self.hx_w - CGRectGetMaxX(self.photoName.frame) + 5 - 20;
    self.photoNum.frame = CGRectMake(photoNumX, 0, photoNumWidth, 15);
    self.photoNum.center = CGPointMake(self.photoNum.center.x, height / 2 + 2);
    
    CGFloat numIconX = 50 - 2 - 13;
    CGFloat numIconY = 2;
    CGFloat numIconW = 13;
    CGFloat numIconH = 13;
    self.numIcon.frame = CGRectMake(numIconX, numIconY, numIconW, numIconH);
}

@end
