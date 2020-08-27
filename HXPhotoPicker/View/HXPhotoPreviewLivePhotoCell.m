//
//  HXPhotoPreviewLivePhotoCell.m
//  HXPhotoPicker-Demo
//
//  Created by 洪欣 on 2019/12/14.
//  Copyright © 2019 洪欣. All rights reserved.
//

#import "HXPhotoPreviewLivePhotoCell.h"

@implementation HXPhotoPreviewLivePhotoCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.previewContentView = [[HXPreviewContentView alloc] initWithType:HXPreviewContentViewTypeLivePhoto];
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
- (void)setModel:(HXPhotoModel *)model {
    [super setModel:model];
}
@end
