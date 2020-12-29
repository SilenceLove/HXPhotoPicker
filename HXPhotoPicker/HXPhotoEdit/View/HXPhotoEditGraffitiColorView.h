//
//  HXPhotoEditGraffitiColorView.h
//  photoEditDemo
//
//  Created by Silence on 2020/6/20.
//  Copyright © 2020 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HXPhotoEditGraffitiColorView : UIView
@property (copy, nonatomic) NSArray<UIColor *> *drawColors;
@property (assign, nonatomic) NSInteger defaultDarwColorIndex;
@property (copy, nonatomic) void (^ selectColorBlock)(UIColor *color);
@property (copy, nonatomic) void (^ undoBlock)(void);
@property (assign, nonatomic) BOOL undo;
+ (instancetype)initView;
@end

NS_ASSUME_NONNULL_END
