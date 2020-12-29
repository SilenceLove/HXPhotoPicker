//
//  HXPhotoPreviewVideoViewCell.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2019/12/5.
//  Copyright © 2019 Silence. All rights reserved.
//

#import "HXPhotoPreviewViewCell.h"
#import "HXPreviewContentView.h"
NS_ASSUME_NONNULL_BEGIN

@interface HXPhotoPreviewVideoViewCell : HXPhotoPreviewViewCell
@property (strong, nonatomic) HXPreviewVideoSliderView *bottomSliderView;
@property (assign, nonatomic) BOOL didAddBottomPageControl;
@end

NS_ASSUME_NONNULL_END
