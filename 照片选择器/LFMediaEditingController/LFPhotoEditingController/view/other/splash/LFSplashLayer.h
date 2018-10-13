//
//  LFSplashLayer.h
//  LFMediaEditingController
//
//  Created by LamTsanFeng on 2017/6/7.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface LFSplashBlur : NSObject

//@property (nonatomic, assign) CGPoint point;
@property (nonatomic, assign) CGRect rect;
@property (nonatomic, strong) UIColor *color;

@end

@interface LFSplashImageBlur : LFSplashBlur

@property (nonatomic, copy) NSString *imageName;

@end

@interface LFSplashLayer : CALayer

@property (nonatomic, strong) NSMutableArray <LFSplashBlur *>*lineArray;

@end
