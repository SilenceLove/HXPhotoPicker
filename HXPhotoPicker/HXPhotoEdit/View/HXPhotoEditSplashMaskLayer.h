//
//  HXPhotoEditSplashMaskLayer.h
//  photoEditDemo
//
//  Created by Silence on 2020/7/1.
//  Copyright © 2020 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface HXPhotoEditSplashBlur : NSObject

@property (nonatomic, assign) CGRect rect;
@property (nonatomic, strong, nullable) UIColor *color;

@end

@interface HXPhotoEditSplashImageBlur : HXPhotoEditSplashBlur

@property (nonatomic, copy) NSString *imageName;

@end

@interface HXPhotoEditSplashMaskLayer : CALayer
@property (nonatomic, strong) NSMutableArray <HXPhotoEditSplashBlur *>*lineArray;;
@end

NS_ASSUME_NONNULL_END
