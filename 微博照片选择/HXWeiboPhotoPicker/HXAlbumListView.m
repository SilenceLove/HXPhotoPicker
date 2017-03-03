//
//  HXAlbumListView.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/8.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXAlbumListView.h"
#import "HXPhotoTools.h"
@interface HXAlbumListView ()<UITableViewDelegate,UITableViewDataSource>
@property (weak, nonatomic) UITableView *tableView;
@end

@implementation HXAlbumListView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, width, height) style:UITableViewStylePlain];
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.backgroundColor = [UIColor colorWithRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:1];
    [tableView registerClass:[HXAlbumListViewCell class] forCellReuseIdentifier:@"cellId"];
    [self addSubview:tableView];
    self.tableView = tableView;
}

- (void)setList:(NSArray *)list
{
    _list = list;
    
    [self.tableView reloadData];
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.list.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HXAlbumListViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellId"];
    cell.model = self.list[indexPath.row];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(didTableViewCellClick:animate:)]) {
        [self.delegate didTableViewCellClick:self.list[indexPath.row] animate:YES];
    }
}

@end

@interface HXAlbumListViewCell ()
@property (weak, nonatomic) UIImageView *photoView;
@property (weak, nonatomic) UILabel *photoName;
@property (weak, nonatomic) UILabel *photoNum;
@property (weak, nonatomic) UIImageView *numIcon;
@end

@implementation HXAlbumListViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = [UIColor colorWithRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:1];
        [self setup];
    }
    return self;
}

- (void)setup
{
    UIImageView *photoView = [[UIImageView alloc] init];
    photoView.contentMode = UIViewContentModeScaleAspectFill;
    photoView.clipsToBounds = YES;
    [self.contentView addSubview:photoView];
    self.photoView = photoView;

    UILabel *photoName = [[UILabel alloc] init];
    photoName.textColor = [UIColor blackColor];
    photoName.font = [UIFont systemFontOfSize:17];
    [self.contentView addSubview:photoName];
    self.photoName = photoName;
    
    UILabel *photoNum = [[UILabel alloc] init];
    photoNum.textColor = [UIColor darkGrayColor];
    photoNum.font = [UIFont systemFontOfSize:12];
    [self.contentView addSubview:photoNum];
    self.photoNum = photoNum;
    
    UIImageView *numIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"compose_photo_filter_checkbox_checked@2x.png"]];
    [photoView addSubview:numIcon];
    self.numIcon = numIcon;
}

- (void)setModel:(HXAlbumModel *)model
{
    _model = model;
    
    __weak typeof(self) weakSelf = self;
    [HXPhotoTools FetchPhotoForPHAsset:model.asset Size:CGSizeMake(60, 60) resizeMode:PHImageRequestOptionsResizeModeFast completion:^(UIImage *image, NSDictionary *info) {
        weakSelf.photoView.image = image;
    }];
    
    self.photoName.text = model.albumName;
    self.photoNum.text = [NSString stringWithFormat:@"%ld",model.count];
    if (model.selectedCount > 0) {
        self.numIcon.hidden = NO;
    }else {
        self.numIcon.hidden = YES;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    
    self.photoView.frame = CGRectMake(10, 5, 50, 50);
    
    CGFloat photoNameX = CGRectGetMaxX(self.photoView.frame) + 10;
    CGFloat photoNameWith = [HXPhotoTools getTextWidth:self.photoName.text withHeight:18 fontSize:17];
    if (photoNameWith > width - photoNameX - 50) {
        photoNameWith = width - photoNameX - 50;
    }
    self.photoName.frame = CGRectMake(photoNameX, 0, photoNameWith, 18);
    self.photoName.center = CGPointMake(self.photoName.center.x, height / 2);
    
    CGFloat photoNumX = CGRectGetMaxX(self.photoName.frame) + 5;
    CGFloat photoNumWidth = [HXPhotoTools getTextWidth:self.photoNum.text withHeight:15 fontSize:12];
    self.photoNum.frame = CGRectMake(photoNumX, 0, photoNumWidth, 15);
    self.photoNum.center = CGPointMake(self.photoNum.center.x, height / 2 + 2);
    
    CGFloat numIconX = 50 - 2 - self.numIcon.image.size.width;
    CGFloat numIconY = 2;
    CGFloat numIconW = self.numIcon.image.size.width;
    CGFloat numIconH = self.numIcon.image.size.height;
    self.numIcon.frame = CGRectMake(numIconX, numIconY, numIconW, numIconH);
}

@end
