//
//  WxMomentHeaderView.m
//  HXPhotoPickerExample
//
//  Created by 洪欣 on 2020/8/4.
//  Copyright © 2020 洪欣. All rights reserved.
//

#import "WxMomentHeaderView.h"
#import "HXPhotoPicker.h"

@interface WxMomentHeaderView ()
@property (weak, nonatomic) IBOutlet UIImageView *backgroudView;
@property (weak, nonatomic) IBOutlet UIImageView *headView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bgViewHeightConstraint;
@end

@implementation WxMomentHeaderView

+ (instancetype)initView {
    return [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil] lastObject];
}
- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.bgViewHeightConstraint.constant = [UIScreen mainScreen].bounds.size.width;
    [self.headView hx_radiusWithRadius:5 corner:UIRectCornerAllCorners];
    
    self.backgroudView.userInteractionEnabled = YES;
    [self.backgroudView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didBgClick:)]];
    
    self.headView.userInteractionEnabled = YES;
    [self.headView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didBgClick:)]];
}
- (void)didBgClick:(UITapGestureRecognizer *)tap {
    BOOL isBg = (tap.view == self.backgroudView);
    HXPhotoBottomViewModel *model1 = [[HXPhotoBottomViewModel alloc] init];
    model1.title = isBg ? @"更换相册封面" : @"更换头像";
    model1.titleColor = [UIColor hx_colorWithHexStr:@"#999999"];
    model1.cellHeight = 40.f;
    model1.titleFont = [UIFont systemFontOfSize:13];
    model1.canSelect = NO;
    
    HXPhotoBottomViewModel *model2 = [[HXPhotoBottomViewModel alloc] init];
    model2.title = @"拍一张";
    
    HXPhotoBottomViewModel *model3 = [[HXPhotoBottomViewModel alloc] init];
    model3.title = @"从手机相册选择";
    
    HXWeakSelf
    [HXPhotoBottomSelectView showSelectViewWithModels:@[model1, model2, model3] selectCompletion:^(NSInteger index, HXPhotoBottomViewModel * _Nonnull model) {
        // 因为公用的同一个manager所以这些需要在跳转前设置一下
        weakSelf.photoManager.selectPhotoFinishDismissAnimated = YES;
        weakSelf.photoManager.cameraFinishDismissAnimated = YES;
        weakSelf.photoManager.type = HXPhotoManagerSelectedTypePhoto;
        weakSelf.photoManager.configuration.singleJumpEdit = YES;
        weakSelf.photoManager.configuration.singleSelected = YES;
        weakSelf.photoManager.configuration.lookGifPhoto = NO;
        weakSelf.photoManager.configuration.lookLivePhoto = NO;
        weakSelf.photoManager.configuration.photoEditConfigur.aspectRatio = HXPhotoEditAspectRatioType_1x1;
        weakSelf.photoManager.configuration.photoEditConfigur.onlyCliping = YES;
        if (index ==1) {
            [weakSelf.hx_viewController hx_presentCustomCameraViewControllerWithManager:weakSelf.photoManager done:^(HXPhotoModel *model, HXCustomCameraViewController *viewController) {
                
                CGSize size = isBg ? weakSelf.backgroudView.hx_size : weakSelf.headView.hx_size;
                // 获取一张图片临时展示用
                [model requestThumbImageWithWidth:size.width completion:^(UIImage * _Nullable image, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info) {
                    if (isBg) {
                        weakSelf.backgroudView.image = image;
                    }else {
                        weakSelf.headView.image = image;
                    }
                }];
                // 上传可以获取imageURL / imageData
//                [model getAssetURLWithSuccess:^(NSURL * _Nullable URL, HXPhotoModelMediaSubType mediaType, BOOL isNetwork, HXPhotoModel * _Nullable model) {
//
//                } failed:nil];
            } cancel:nil];
        }else if (index == 2) {
            [weakSelf.hx_viewController hx_presentSelectPhotoControllerWithManager:weakSelf.photoManager didDone:^(NSArray<HXPhotoModel *> * _Nullable allList, NSArray<HXPhotoModel *> * _Nullable photoList, NSArray<HXPhotoModel *> * _Nullable videoList, BOOL isOriginal, UIViewController * _Nullable viewController, HXPhotoManager * _Nullable manager) {
                HXPhotoModel *photoModel = allList.firstObject;
                // 因为是编辑过的照片所以直接取
                if (isBg) {
                    weakSelf.backgroudView.image = photoModel.photoEdit.editPreviewImage;
                }else {
                    weakSelf.headView.image = photoModel.photoEdit.editPreviewImage;
                }
            } cancel:nil];
        }
    } cancelClick:nil];
}

@end
