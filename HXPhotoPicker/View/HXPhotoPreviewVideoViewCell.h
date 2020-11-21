//
//  HXPhotoPreviewVideoViewCell.h
//  HXPhotoPickerExample
//
//  Created by 洪欣 on 2019/12/5.
//  Copyright © 2019 洪欣. All rights reserved.
//

#import "HXPhotoPreviewViewCell.h"
#import "HXPreviewContentView.h"
NS_ASSUME_NONNULL_BEGIN

@interface HXPhotoPreviewVideoViewCell : HXPhotoPreviewViewCell
@property (strong, nonatomic) HXPreviewVideoSliderView *bottomSliderView;
@property (assign, nonatomic) BOOL didAddBottomPageControl;
@end

NS_ASSUME_NONNULL_END
