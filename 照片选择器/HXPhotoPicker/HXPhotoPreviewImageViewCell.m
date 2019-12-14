//
//  HXPhotoPreviewImageViewCell.m
//  照片选择器
//
//  Created by 洪欣 on 2019/12/5.
//  Copyright © 2019 洪欣. All rights reserved.
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
            [weakSelf refreshImageSize];
        };
        [self.scrollView addSubview:self.previewContentView];
    }
    return self;
}
- (void)setModel:(HXPhotoModel *)model {
    [super setModel:model];
}
@end
