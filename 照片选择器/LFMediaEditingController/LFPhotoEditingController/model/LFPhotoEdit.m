//
//  LFPhotoEdit.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/23.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFPhotoEdit.h"
#import "UIImage+LFMECommon.h"
#import "LFMEGIFImageSerialization.h"

@interface LFPhotoEdit ()
@end

@implementation LFPhotoEdit

- (void)setEditingImage:(UIImage *)editPreviewImage
{
    _editPreviewImage = editPreviewImage;
    /** 设置编辑封面 */
    CGFloat width = 80.f * 2.f;
    CGSize size = [UIImage LFME_scaleImageSizeBySize:editPreviewImage.size targetSize:CGSizeMake(width, width) isBoth:NO];
    if (editPreviewImage.images.count) {
        _editPosterImage = [editPreviewImage.images.firstObject LFME_scaleToSize:size];
        _editPreviewData = LFME_UIImageGIFRepresentation(editPreviewImage);
    } else {
        _editPosterImage = [editPreviewImage LFME_scaleToSize:size];
        _editPreviewData = LFME_UIImageJPEGRepresentation(editPreviewImage);
    }
    
    
}

/** 初始化 */
- (instancetype)initWithEditImage:(UIImage *)image previewImage:(UIImage *)previewImage data:(NSDictionary *)data
{
    self = [super init];
    if (self) {
        [self setEditingImage:previewImage];
        _editImage = image;
        _editData = data;
    }
    return self;
}
@end
