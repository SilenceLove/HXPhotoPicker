//
//  Demo9ViewCell.m
//  微博照片选择
//
//  Created by 洪欣 on 2018/2/14.
//  Copyright © 2018年 洪欣. All rights reserved.
//

#import "Demo9ViewCell.h"
#import "HXPhotoPicker.h"

@interface Demo9ViewCell ()<HXPhotoViewDelegate>
/**  照片管理  */
@property (nonatomic, strong) HXPhotoManager *manager;
/**  照片视图  */
@property (nonatomic, strong) HXPhotoView *photoView;
@end

@implementation Demo9ViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}
- (void)setupUI {
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self.contentView addSubview:self.photoView];
}
- (void)setModel:(Demo9Model *)model {
    _model = model;
    [self.manager changeAfterCameraArray:model.endCameraList];
    [self.manager changeAfterCameraPhotoArray:model.endCameraPhotos];
    [self.manager changeAfterCameraVideoArray:model.endCameraVideos];
    [self.manager changeAfterSelectedCameraArray:model.endSelectedCameraList];
    
    [self.manager changeAfterSelectedCameraPhotoArray:model.endSelectedCameraPhotos];
    
    [self.manager changeAfterSelectedCameraVideoArray:model.endSelectedCameraVideos];
    [self.manager changeAfterSelectedArray:model.endSelectedList];
    [self.manager changeAfterSelectedPhotoArray:model.endSelectedPhotos];
    [self.manager changeAfterSelectedVideoArray:model.endSelectedVideos];
    [self.manager changeICloudUploadArray:model.iCloudUploadArray]; 
    
    [self.photoView refreshView];
}
- (void)photoView:(HXPhotoView *)photoView changeComplete:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photos videos:(NSArray<HXPhotoModel *> *)videos original:(BOOL)isOriginal {
    
    self.model.endCameraList = self.manager.afterCameraArray.mutableCopy;
    self.model.endCameraPhotos = self.manager.afterCameraPhotoArray.mutableCopy;
    self.model.endCameraVideos = self.manager.afterCameraVideoArray.mutableCopy;
    self.model.endSelectedCameraList = self.manager.afterSelectedCameraArray.mutableCopy;
    self.model.endSelectedCameraPhotos = self.manager.afterSelectedCameraPhotoArray.mutableCopy;
    self.model.endSelectedCameraVideos = self.manager.afterSelectedCameraVideoArray.mutableCopy;
    self.model.endSelectedList = self.manager.afterSelectedArray.mutableCopy;
    self.model.endSelectedPhotos = self.manager.afterSelectedPhotoArray.mutableCopy;
    self.model.endSelectedVideos = self.manager.afterSelectedVideoArray.mutableCopy;
    self.model.iCloudUploadArray = self.manager.afterICloudUploadArray.mutableCopy;
    
}
- (void)photoView:(HXPhotoView *)photoView updateFrame:(CGRect)frame {
    if (frame.size.height == self.model.photoViewHeight) {
        return;
    }
    self.model.photoViewHeight = frame.size.height;
    if (self.photoViewChangeHeightBlock) {
        self.photoViewChangeHeightBlock(self);
    }
}
- (HXPhotoManager *)manager {
    if (!_manager) {
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo]; 
    }
    return _manager;
}
- (HXPhotoView *)photoView {
    if (!_photoView) {
        _photoView = [[HXPhotoView alloc] initWithFrame:CGRectMake(12, 0, [UIScreen mainScreen].bounds.size.width - 24, 0) WithManager:self.manager];
        _photoView.backgroundColor = [UIColor whiteColor];
        _photoView.delegate = self;
    }
    return _photoView;
}
@end
