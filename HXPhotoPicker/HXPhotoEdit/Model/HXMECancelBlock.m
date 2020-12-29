//
//  HXMECancelBlock.m
//  photoEditDemo
//
//  Created by Silence on 2020/6/29.
//  Copyright © 2020 Silence. All rights reserved.
//

#import "HXMECancelBlock.h"
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/UTCoreTypes.h>

 hx_me_dispatch_cancelable_block_t hx_dispatch_block_t(NSTimeInterval delay, void(^block)(void))
 {
     __block hx_me_dispatch_cancelable_block_t cancelBlock = nil;
     hx_me_dispatch_cancelable_block_t delayBlcok = ^(BOOL cancel){
         if (!cancel) {
             if ([NSThread isMainThread]) {
                 block();
             } else {
                 dispatch_async(dispatch_get_main_queue(), block);
             }
         }
         if (cancelBlock) {
             cancelBlock = nil;
         }
     };
     cancelBlock = delayBlcok;
     dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
         if (cancelBlock) {
             cancelBlock(NO);
         }
     });
     return delayBlcok;
 }

 void hx_me_dispatch_cancel(hx_me_dispatch_cancelable_block_t block)
 {
     if (block) {
         block(YES);
     }
 }


double const HXMediaEditMinRate = 0.5f;
double const HXMediaEditMaxRate = 2.f;

CGRect HXMediaEditProundRect(CGRect rect)
{
    rect.origin.x = ((int)(rect.origin.x + 0.5) * 1.f);
    rect.origin.y = ((int)(rect.origin.y + 0.5) * 1.f);
    rect.size.width = ((int)(rect.size.width + 0.5) * 1.f);
    rect.size.height = ((int)(rect.size.height + 0.5) * 1.f);
    return rect;
}


__attribute__((overloadable)) NSData * HX_UIImagePNGRepresentation(UIImage *image) {
    return HX_UIImageRepresentation(image, kUTTypePNG, nil);
}

__attribute__((overloadable)) NSData * HX_UIImageJPEGRepresentation(UIImage *image) {
    return HX_UIImageRepresentation(image, kUTTypeJPEG, nil);
}

__attribute__((overloadable)) NSData * HX_UIImageRepresentation(UIImage *image, CFStringRef __nonnull type, NSError * __autoreleasing *error) {
    
    if (!image) {
        return nil;
    }
    NSDictionary *userInfo = nil;
    {
        NSMutableData *mutableData = [NSMutableData data];
        
        CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)mutableData, type, 1, NULL);
        
        CGImageDestinationAddImage(destination, [image CGImage], NULL);
        
        BOOL success = CGImageDestinationFinalize(destination);
        CFRelease(destination);
        
        if (!success) {
            userInfo = @{
                         NSLocalizedDescriptionKey: NSLocalizedString(@"Could not finalize image destination", nil)
                         };
            
            goto _error;
        }
        
        return [NSData dataWithData:mutableData];
    }
    _error: {
        if (error) {
            *error = [[NSError alloc] initWithDomain:@"com.compuserve.image.error" code:-1 userInfo:userInfo];
        }
        return nil;
    }
}

inline static CGAffineTransform HX_CGAffineTransformExchangeOrientation(UIImageOrientation imageOrientation, CGSize size)
{
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
            
        default:
            break;
    }
    
    switch (imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        default:
            break;
    }
    
    return transform;
}
CGImageRef HX_CGImageScaleDecodedFromCopy(CGImageRef imageRef, CGSize size, UIViewContentMode contentMode, UIImageOrientation orientation)
{
    CGImageRef newImage = NULL;
    @autoreleasepool {
        if (!imageRef) return NULL;
        size_t width = CGImageGetWidth(imageRef);
        size_t height = CGImageGetHeight(imageRef);
        if (width == 0 || height == 0) return NULL;
        
        switch (orientation) {
            case UIImageOrientationLeft:
            case UIImageOrientationLeftMirrored:
            case UIImageOrientationRight:
            case UIImageOrientationRightMirrored:
                // Grr...
            {
                CGFloat tmpWidth = width;
                width = height;
                height = tmpWidth;
            }
                break;
            default:
                break;
        }
        
        if (size.width > 0 && size.height > 0) {
            float verticalRadio = size.height*1.0/height;
            float horizontalRadio = size.width*1.0/width;
            
            
            float radio = 1;
            if (contentMode == UIViewContentModeScaleAspectFill) {
                if(verticalRadio > horizontalRadio)
                {
                    radio = verticalRadio;
                }
                else
                {
                    radio = horizontalRadio;
                }
            } else if (contentMode == UIViewContentModeScaleAspectFit) {
                if(verticalRadio < horizontalRadio)
                {
                    radio = verticalRadio;
                }
                else
                {
                    radio = horizontalRadio;
                }
            } else {
                if(verticalRadio>1 && horizontalRadio>1)
                {
                    radio = verticalRadio > horizontalRadio ? horizontalRadio : verticalRadio;
                }
                else
                {
                    radio = verticalRadio < horizontalRadio ? verticalRadio : horizontalRadio;
                }
                
            }
            
            width = roundf(width*radio);
            height = roundf(height*radio);
        }
        
        CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef) & kCGBitmapAlphaInfoMask;
        BOOL hasAlpha = NO;
        if (alphaInfo == kCGImageAlphaPremultipliedLast ||
            alphaInfo == kCGImageAlphaPremultipliedFirst ||
            alphaInfo == kCGImageAlphaLast ||
            alphaInfo == kCGImageAlphaFirst) {
            hasAlpha = YES;
        }
        
        CGAffineTransform transform = HX_CGAffineTransformExchangeOrientation(orientation, CGSizeMake(width, height));
        // BGRA8888 (premultiplied) or BGRX8888
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
        bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, colorSpace, bitmapInfo);
        CGColorSpaceRelease(colorSpace);
        if (!context) return NULL;
        CGContextConcatCTM(context, transform);
        switch (orientation) {
            case UIImageOrientationLeft:
            case UIImageOrientationLeftMirrored:
            case UIImageOrientationRight:
            case UIImageOrientationRightMirrored:
                // Grr...
                CGContextDrawImage(context, CGRectMake(0, 0, height, width), imageRef); // decode
                break;
            default:
                CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef); // decode
                break;
        }
        newImage = CGBitmapContextCreateImage(context);
        CGContextRelease(context);
    }
    return newImage;
}

CGImageRef HX_CGImageDecodedFromCopy(CGImageRef imageRef)
{
    return HX_CGImageScaleDecodedFromCopy(imageRef, CGSizeZero, UIViewContentModeScaleAspectFit, UIImageOrientationUp);
}


CGImageRef HX_CGImageDecodedCopy(UIImage *image)
{
    if (!image) return NULL;
    if (image.images.count > 1) {
        return NULL;
    }
    CGImageRef imageRef = image.CGImage;
    if (!imageRef) return NULL;
    CGImageRef newImageRef = HX_CGImageDecodedFromCopy(imageRef);
    
    return newImageRef;
}

UIImage *HX_UIImageDecodedCopy(UIImage *image)
{
    CGImageRef imageRef = HX_CGImageDecodedCopy(image);
    if (!imageRef) return image;
    UIImage *newImage = [UIImage imageWithCGImage:imageRef scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(imageRef);
    
    return newImage;
}
