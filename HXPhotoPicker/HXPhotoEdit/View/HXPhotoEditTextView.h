//
//  HXPhotoEditTextView.h
//  photoEditDemo
//
//  Created by 洪欣 on 2020/6/22.
//  Copyright © 2020 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class HXPhotoEditTextModel, HXPhotoEditConfiguration;
@interface HXPhotoEditTextView : UIView
@property (strong, nonatomic) HXPhotoEditConfiguration *configuration;
@property (copy, nonatomic) NSArray<UIColor *> *textColors;
+ (instancetype)showEitdTextViewWithConfiguration:(HXPhotoEditConfiguration *)configuration
                                       completion:(void (^ _Nullable)(HXPhotoEditTextModel *textModel))completion;

+ (instancetype)showEitdTextViewWithConfiguration:(HXPhotoEditConfiguration *)configuration
                                        textModel:(HXPhotoEditTextModel * _Nullable)textModel
                                       completion:(void (^ _Nullable)(HXPhotoEditTextModel *textModel))completion;
@end

@interface HXPhotoEditTextModel : NSObject<NSCoding>
@property (strong, nonatomic) UIImage *image;
@property (copy, nonatomic) NSString *text;
@property (strong, nonatomic) UIColor *textColor;
@property (assign, nonatomic) BOOL showBackgroud;
@end

@interface HXPhotoEditTextLayer : CAShapeLayer

@end

NS_ASSUME_NONNULL_END
