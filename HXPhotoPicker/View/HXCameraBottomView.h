//
//  HXCameraBottomView.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2020/7/17.
//  Copyright © 2020 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class HXPhotoManager;
@interface HXCameraBottomView : UIView
@property (copy, nonatomic) void (^ takePictures)(void);
@property (copy, nonatomic) void (^ startTranscribe)(void);
@property (copy, nonatomic) void (^ changedTranscribe)(CGFloat margin);
@property (copy, nonatomic) void (^ endTranscribe)(BOOL isAnimation);
@property (copy, nonatomic) void (^ backClick)(void);
@property (assign, nonatomic) BOOL isOutside;
@property (assign, nonatomic) BOOL inTakePictures;
@property (assign, nonatomic) BOOL inTranscribe;
@property (strong, nonatomic) HXPhotoManager *manager;
+ (instancetype)initView;
- (void)hiddenTitle;
- (void)startRecord;
- (void)stopRecord;

- (void)videoRecordEnd;
@end

NS_ASSUME_NONNULL_END
