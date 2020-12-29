//
//  HXPhotoPreviewImageViewCell.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2019/12/5.
//  Copyright © 2019 Silence. All rights reserved.
//

#import "HXPhotoPreviewImageViewCell.h"
#import "UIView+HXExtension.h"
#import "HXPhotoDefine.h"

@implementation HXPhotoPreviewImageViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.previewContentView = [[HXPreviewContentView alloc] initWithType:HXPreviewContentViewTypeImage];
        HXWeakSelf
        self.previewContentView.downloadNetworkImageComplete = ^{
            if (weakSelf.cellDownloadImageComplete) {
                weakSelf.cellDownloadImageComplete(weakSelf);
            }
            [weakSelf refreshImageSize];
        };
        [self.scrollView addSubview:self.previewContentView];
    }
    return self;
}
- (void)setAllowPreviewDirectLoadOriginalImage:(BOOL)allowPreviewDirectLoadOriginalImage {
    self.previewContentView.allowPreviewDirectLoadOriginalImage = allowPreviewDirectLoadOriginalImage;
}
- (void)setModel:(HXPhotoModel *)model {
    [super setModel:model];
}
@end
