//
//  HXPhotoCommon.m
//  照片选择器
//
//  Created by 洪欣 on 2019/1/8.
//  Copyright © 2019年 洪欣. All rights reserved.
//

#import "HXPhotoCommon.h"
#import "HXPhotoTools.h"

static dispatch_once_t once;
static dispatch_once_t once1;
static id instance;

@interface HXPhotoCommon () 

@end

@implementation HXPhotoCommon


+ (instancetype)photoCommon {
    if (instance == nil) {
        dispatch_once(&once, ^{
            instance = [[HXPhotoCommon alloc] init];
        });
    }
    return instance;
}
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    if (instance == nil) {
        dispatch_once(&once1, ^{
            instance = [super allocWithZone:zone];
        });
    }
    return instance;
}
- (instancetype)init {
    self = [super init];
    if (self) {
        NSData *imageData = [[NSUserDefaults standardUserDefaults] objectForKey:HXCameraImageKey];
        if (imageData) {
            self.cameraImage = [NSKeyedUnarchiver unarchiveObjectWithData:imageData];
        }
    }
    return self;
}
- (BOOL)isDark {
    if (self.photoStyle == HXPhotoStyleDark) {
        return YES;
    }
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        if (UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return YES;
        }
    }
#endif
    return NO;
}
- (void)saveCamerImage {
    if (self.cameraImage) {
        NSData *imageData = [NSKeyedArchiver archivedDataWithRootObject:self.cameraImage];
        [[NSUserDefaults standardUserDefaults] setObject:imageData forKey:HXCameraImageKey];
    }
}
- (void)setCameraImage:(UIImage *)cameraImage {
    _cameraImage = cameraImage;
}

+ (void)deallocPhotoCommon {
    once = 0;
    once1 = 0;
    instance = nil; 
}
- (void)dealloc {
    NSSLog(@"dealloc");
}
@end
