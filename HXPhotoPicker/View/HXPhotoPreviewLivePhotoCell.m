//
//  HXPhotoPreviewLivePhotoCell.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2019/12/14.
//  Copyright © 2019 Silence. All rights reserved.
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
