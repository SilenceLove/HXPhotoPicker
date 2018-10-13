//
//  LFColorMatrixType.h
//  LFMediaEditingController
//
//  Created by TsanFeng Lam on 2018/8/7.
//  Copyright © 2018年 LamTsanFeng. All rights reserved.
//
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, LFColorMatrixType) {
    /** 原图 */
    LFColorMatrixType_None = 0,
    /** LOMO */
    LFColorMatrixType_LOMO,
    /** 黑白 */
    LFColorMatrixType_Heibai,
    /** 复古 */
    LFColorMatrixType_Fugu,
    /** 哥特 */
    LFColorMatrixType_Gete,
    /** 锐化 */
    LFColorMatrixType_Ruise,
    /** 淡雅 */
    LFColorMatrixType_Danya,
    /** 酒红 */
    LFColorMatrixType_Jiuhong,
    /** 清宁 */
    LFColorMatrixType_Qingning,
    /** 浪漫 */
    LFColorMatrixType_Langman,
    /** 怀旧 */
    LFColorMatrixType_Huaijiu,
    /** 蓝调 */
    LFColorMatrixType_Landiao,
    /** 梦幻 */
    LFColorMatrixType_Menghuan,
    /** 夜色 */
    LFColorMatrixType_Yese,
    /** 灰度 */
    LFColorMatrixType_Huidu,
    /** 图片旋转 */
    LFColorMatrixType_Imagerevolve,
    /** 高饱和度 */
    LFColorMatrixType_Heighsaturatedcolour,
    /** 去色 */
    LFColorMatrixType_Cleancolor,
};

OBJC_EXTERN NSString *lf_colorMatrixName(LFColorMatrixType type);
OBJC_EXTERN UIImage * lf_colorMatrixImage(UIImage *image, LFColorMatrixType type);

