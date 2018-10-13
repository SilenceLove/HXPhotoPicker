//
//  LFMEGIFImageSerialization.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/5/17.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

extern __attribute__((overloadable)) NSData * LFME_UIImageGIFRepresentation(UIImage *image);

extern __attribute__((overloadable)) NSData * LFME_UIImageGIFRepresentation(UIImage *image, NSTimeInterval duration, NSUInteger loopCount, NSError * __autoreleasing *error);

extern __attribute__((overloadable)) NSData * LFME_UIImagePNGRepresentation(UIImage *image);

extern __attribute__((overloadable)) NSData * LFME_UIImageJPEGRepresentation(UIImage *image);

extern __attribute__((overloadable)) NSData * LFME_UIImageRepresentation(UIImage *image, CFStringRef __nonnull type, NSError * __autoreleasing *error);
