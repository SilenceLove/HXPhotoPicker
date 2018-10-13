//
//  LFVideoEdit.m
//  LFMediaEditingController
//
//  Created by LamTsanFeng on 2017/7/17.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFVideoEdit.h"
#import <AVFoundation/AVFoundation.h>
#import "UIImage+LFMECommon.h"

@implementation LFVideoEdit

- (instancetype)initWithEditAsset:(AVAsset *)editAsset editFinalURL:(NSURL *)editFinalURL data:(NSDictionary *)data
{
    self = [super init];
    if (self) {
        _editAsset = editAsset;
        _editFinalURL = editFinalURL;
        _editData = data;
        [self createfirstImage];
    }
    return self;
}

- (void)createfirstImage
{
    AVAsset *asset = nil;
    if (self.editFinalURL) {
        asset = [[AVURLAsset alloc] initWithURL:self.editFinalURL options:nil];
    } else {
        asset = self.editAsset;
    }
    
    _duration = CMTimeGetSeconds(asset.duration);
    
    NSParameterAssert(asset);
    AVAssetImageGenerator *assetImageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetImageGenerator.appliesPreferredTrackTransform = YES;
    assetImageGenerator.apertureMode =AVAssetImageGeneratorApertureModeEncodedPixels;
    assetImageGenerator.maximumSize = CGSizeMake([UIScreen mainScreen].bounds.size.width * [UIScreen mainScreen].scale, [UIScreen mainScreen].bounds.size.height * [UIScreen mainScreen].scale);
    
    CGImageRef thumbnailImageRef = NULL;
    CFTimeInterval thumbnailImageTime = 1;
    NSError *thumbnailImageGenerationError = nil;
    thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:CMTimeMake(thumbnailImageTime, asset.duration.timescale) actualTime:NULL error:&thumbnailImageGenerationError];
    
    if(!thumbnailImageRef)
        NSLog(@"thumbnailImageGenerationError %@",thumbnailImageGenerationError);
    
    _editPreviewImage = thumbnailImageRef ? [[UIImage alloc]initWithCGImage:thumbnailImageRef] : nil;
    CGFloat width = 80.f * 2.f;
    CGSize size = [UIImage LFME_scaleImageSizeBySize:_editPreviewImage.size targetSize:CGSizeMake(width, width) isBoth:NO];
    _editPosterImage = [_editPreviewImage LFME_scaleToSize:size];
    
}
@end
