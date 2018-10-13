//
//  LFColorMatrixType.m
//  LFMediaEditingController
//
//  Created by TsanFeng Lam on 2018/8/7.
//  Copyright © 2018年 LamTsanFeng. All rights reserved.
//

#import "LFColorMatrixType.h"
#import "LFImageUtil.h"
#import "LFColorMatrix.h"

NSString *lf_colorMatrixName(LFColorMatrixType type)
{
    NSString *colorStr = @"原图";
    switch (type) {
        case LFColorMatrixType_None:
            break;
        case LFColorMatrixType_LOMO:
            colorStr = @"LOMO";
            break;
        case LFColorMatrixType_Heibai:
            colorStr = @"黑白";
            break;
        case LFColorMatrixType_Fugu:
            colorStr = @"复古";
            break;
        case LFColorMatrixType_Gete:
            colorStr = @"哥特";
            break;
        case LFColorMatrixType_Ruise:
            colorStr = @"锐化";
            break;
        case LFColorMatrixType_Danya:
            colorStr = @"淡雅";
            break;
        case LFColorMatrixType_Jiuhong:
            colorStr = @"酒红";
            break;
        case LFColorMatrixType_Qingning:
            colorStr = @"清宁";
            break;
        case LFColorMatrixType_Langman:
            colorStr = @"浪漫";
            break;
        case LFColorMatrixType_Huaijiu:
            colorStr = @"怀旧";
            break;
        case LFColorMatrixType_Landiao:
            colorStr = @"蓝调";
            break;
        case LFColorMatrixType_Menghuan:
            colorStr = @"梦幻";
            break;
        case LFColorMatrixType_Yese:
            colorStr = @"夜色";
            break;
        case LFColorMatrixType_Huidu:
            colorStr = @"灰度";
            break;
        case LFColorMatrixType_Imagerevolve:
            colorStr = @"高冷";
            break;
        case LFColorMatrixType_Heighsaturatedcolour:
            colorStr = @"饱和";
            break;
        case LFColorMatrixType_Cleancolor:
            colorStr = @"去色";
            break;
    }
    return colorStr;
}

UIImage * lf_colorMatrixImage(UIImage *image, LFColorMatrixType type)
{
    UIImage *cmImage = image;
    switch (type) {
        case LFColorMatrixType_None:
            break;
        case LFColorMatrixType_LOMO:
            cmImage = [LFImageUtil lf_imageWithImage:image withColorMatrix:lf_colormatrix_lomo];
            break;
        case LFColorMatrixType_Heibai:
            cmImage = [LFImageUtil lf_imageWithImage:image withColorMatrix:lf_colormatrix_heibai];
            break;
        case LFColorMatrixType_Fugu:
            cmImage = [LFImageUtil lf_imageWithImage:image withColorMatrix:lf_colormatrix_fugu];
            break;
        case LFColorMatrixType_Gete:
            cmImage = [LFImageUtil lf_imageWithImage:image withColorMatrix:lf_colormatrix_gete];
            break;
        case LFColorMatrixType_Ruise:
            cmImage = [LFImageUtil lf_imageWithImage:image withColorMatrix:lf_colormatrix_ruise];
            break;
        case LFColorMatrixType_Danya:
            cmImage = [LFImageUtil lf_imageWithImage:image withColorMatrix:lf_colormatrix_danya];
            break;
        case LFColorMatrixType_Jiuhong:
            cmImage = [LFImageUtil lf_imageWithImage:image withColorMatrix:lf_colormatrix_jiuhong];
            break;
        case LFColorMatrixType_Qingning:
            cmImage = [LFImageUtil lf_imageWithImage:image withColorMatrix:lf_colormatrix_qingning];
            break;
        case LFColorMatrixType_Langman:
            cmImage = [LFImageUtil lf_imageWithImage:image withColorMatrix:lf_colormatrix_langman];
            break;
        case LFColorMatrixType_Huaijiu:
            cmImage = [LFImageUtil lf_imageWithImage:image withColorMatrix:lf_colormatrix_huaijiu];
            break;
        case LFColorMatrixType_Landiao:
            cmImage = [LFImageUtil lf_imageWithImage:image withColorMatrix:lf_colormatrix_landiao];
            break;
        case LFColorMatrixType_Menghuan:
            cmImage = [LFImageUtil lf_imageWithImage:image withColorMatrix:lf_colormatrix_menghuan];
            break;
        case LFColorMatrixType_Yese:
            cmImage = [LFImageUtil lf_imageWithImage:image withColorMatrix:lf_colormatrix_yese];
            break;
        case LFColorMatrixType_Huidu:
            cmImage = [LFImageUtil lf_imageWithImage:image withColorMatrix:lf_colormatrix_huidu];
            break;
        case LFColorMatrixType_Imagerevolve:
            cmImage = [LFImageUtil lf_imageWithImage:image withColorMatrix:lf_colormatrix_imagerevolve];
            break;
        case LFColorMatrixType_Heighsaturatedcolour:
            cmImage = [LFImageUtil lf_imageWithImage:image withColorMatrix:lf_colormatrix_heighsaturatedcolour];
            break;
        case LFColorMatrixType_Cleancolor:
            cmImage = [LFImageUtil lf_imageWithImage:image withColorMatrix:lf_colormatrix_cleancolor];
            break;
    }
    return cmImage;
}
