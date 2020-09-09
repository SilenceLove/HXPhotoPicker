//
//  HXPhotoEdit.m
//  photoEditDemo
//
//  Created by 洪欣 on 2020/7/1.
//  Copyright © 2020 洪欣. All rights reserved.
//

#import "HXPhotoEdit.h"
#import "UIImage+HXExtension.h"
#import "HXMECancelBlock.h"

@interface HXPhotoEdit ()
/// 编辑封面
@property (nonatomic, strong) UIImage *editPosterImage;
/// 编辑预览图片
@property (nonatomic, strong) UIImage *editPreviewImage;
/// 编辑图片数据
@property (nonatomic, strong) NSData *editPreviewData;
/// 编辑原图片
@property (nonatomic, strong) UIImage *editImage;
/// 编辑数据
@property (nonatomic, copy) NSDictionary *editData;
@end

@implementation HXPhotoEdit

- (instancetype)initWithEditImage:(UIImage *)image previewImage:(UIImage *)previewImage data:(NSDictionary *)data {
    self = [super init];
    if (self) {
        if (!previewImage) {
            previewImage = image;
        }
        [self setEditingImage:previewImage];
        _editImage = image;
        _editData = data;
    }
    return self;
}

#pragma mark - private
- (void)clearData {
    self.editPreviewImage = nil;
    self.editPosterImage = nil;
    self.editImage = nil;
    self.editData = nil;
}
- (void)setEditingImage:(UIImage *)editPreviewImage {
    _editPreviewImage = editPreviewImage;
    /** 设置编辑封面 */
    CGFloat width = MIN(80.f * 2.f, MIN(editPreviewImage.size.width, editPreviewImage.size.height));
    CGSize size = [UIImage hx_scaleImageSizeBySize:editPreviewImage.size targetSize:CGSizeMake(width, width) isBoth:YES];
    _editPosterImage = [editPreviewImage hx_scaleToFitSize:size];
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.editPosterImage = [aDecoder decodeObjectForKey:@"editPosterImage"];
        self.editPreviewImage = [aDecoder decodeObjectForKey:@"editPreviewImage"];
        self.editPreviewData = [aDecoder decodeObjectForKey:@"editPreviewData"];
        self.editImage = [aDecoder decodeObjectForKey:@"editImage"];
        self.editData = [aDecoder decodeObjectForKey:@"editData"];
        
    }
    return self;
}
- (NSData *)editPreviewData {
    if (!_editPreviewData) {
        _editPreviewData = HX_UIImageJPEGRepresentation(self.editPreviewImage);
    }
    return _editPreviewData;
}
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.editPosterImage forKey:@"editPosterImage"];
    [aCoder encodeObject:self.editPreviewImage forKey:@"editPreviewImage"];
    [aCoder encodeObject:self.editPreviewData forKey:@"editPreviewData"];
    [aCoder encodeObject:self.editImage forKey:@"editImage"];
    [aCoder encodeObject:self.editData forKey:@"editData"];
}
@end
