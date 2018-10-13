//
//  RootViewController.h
//  pictureProcess
//
//  Created by Ibokan on 12-9-7.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

/** LOMO */
const float lf_colormatrix_lomo[] = {
    1.7f,  0.1f, 0.1f, 0, -73.1f,
    0,  1.7f, 0.1f, 0, -73.1f,
    0,  0.1f, 1.6f, 0, -73.1f,
    0,  0, 0, 1.0f, 0 };

/** 黑白 */
const float lf_colormatrix_heibai[] = {
    0.8f,  1.6f, 0.2f, 0, -163.9f,
    0.8f,  1.6f, 0.2f, 0, -163.9f,
    0.8f,  1.6f, 0.2f, 0, -163.9f,
    0,  0, 0, 1.0f, 0 };

/** 复古 */
const float lf_colormatrix_fugu[] = {
    0.2f,0.5f, 0.1f, 0, 40.8f,
    0.2f, 0.5f, 0.1f, 0, 40.8f, 
    0.2f,0.5f, 0.1f, 0, 40.8f, 
    0, 0, 0, 1, 0 };

/** 哥特 */
const float lf_colormatrix_gete[] = {
    1.9f,-0.3f, -0.2f, 0,-87.0f,
    -0.2f, 1.7f, -0.1f, 0, -87.0f, 
    -0.1f,-0.6f, 2.0f, 0, -87.0f, 
    0, 0, 0, 1.0f, 0 };

/** 锐化 */
const float lf_colormatrix_ruise[] = {
    4.8f,-1.0f, -0.1f, 0,-388.4f,
    -0.5f,4.4f, -0.1f, 0,-388.4f, 
    -0.5f,-1.0f, 5.2f, 0,-388.4f,
    0, 0, 0, 1.0f, 0 };


/** 淡雅 */
const float lf_colormatrix_danya[] = {
    0.6f,0.3f, 0.1f, 0,73.3f,
    0.2f,0.7f, 0.1f, 0,73.3f, 
    0.2f,0.3f, 0.4f, 0,73.3f,
    0, 0, 0, 1.0f, 0 };

/** 酒红 */
const float lf_colormatrix_jiuhong[] = {
    1.2f,0.0f, 0.0f, 0.0f,0.0f,
    0.0f,0.9f, 0.0f, 0.0f,0.0f, 
    0.0f,0.0f, 0.8f, 0.0f,0.0f,
    0, 0, 0, 1.0f, 0 };

/** 清宁 */
const float lf_colormatrix_qingning[] = {
    0.9f, 0, 0, 0, 0, 
    0, 1.1f,0, 0, 0, 
    0, 0, 0.9f, 0, 0, 
    0, 0, 0, 1.0f, 0 };

/** 浪漫 */
const float lf_colormatrix_langman[] = {
    0.9f, 0, 0, 0, 63.0f, 
    0, 0.9f,0, 0, 63.0f, 
    0, 0, 0.9f, 0, 63.0f, 
    0, 0, 0, 1.0f, 0 };

/** 蓝调 */
const float lf_colormatrix_landiao[] = {
    2.1f, -1.4f, 0.6f, 0.0f, -31.0f, 
    -0.3f, 2.0f, -0.3f, 0.0f, -31.0f,
    -1.1f, -0.2f, 2.6f, 0.0f, -31.0f, 
    0.0f, 0.0f, 0.0f, 1.0f, 0.0f
};

/** 梦幻 */
const float lf_colormatrix_menghuan[] = {
    0.8f, 0.3f, 0.1f, 0.0f, 46.5f, 
    0.1f, 0.9f, 0.0f, 0.0f, 46.5f, 
    0.1f, 0.3f, 0.7f, 0.0f, 46.5f, 
    0.0f, 0.0f, 0.0f, 1.0f, 0.0f
};

/** 夜色 */
const float lf_colormatrix_yese[] = {
    1.0f, 0.0f, 0.0f, 0.0f, -66.6f,
    0.0f, 1.1f, 0.0f, 0.0f, -66.6f, 
    0.0f, 0.0f, 1.0f, 0.0f, -66.6f, 
    0.0f, 0.0f, 0.0f, 1.0f, 0.0f
};

/** 图像翻转 */
const float lf_colormatrix_imagerevolve[] = {
    -1.f, 0.f, 0.f, 1.f, 1.f,
    0.f, -1.f, 0.f, 1.f, 1.f,
    0.f, 0.f, -1.f, 1.f, 1.f,
    0.f, 0.f, 0.f, 1.f, 0.f
};

/** 高饱和度 */
const float lf_colormatrix_heighsaturatedcolour[] = {
    1.438f, -0.122f, -0.016f, 0.f, -0.03f,
    -0.062f, 1.378f, -0.016f, 0.f, 0.05f,
    -0.062f, -0.122f, 1.483f, 0.f, -0.02f,
    0.f, 0.f, 0.f, 1.f, 0.f
};
/** 去色效果 */
const float lf_colormatrix_cleancolor[] = {
    1.5f, 1.5f, 1.5f, 0.f, -1.f,
    1.5f, 1.5f, 1.5f, 0.f, -1.f,
    1.5f, 1.5f, 1.5f, 0.f, -1.f,
    1.5f, 1.5f, 1.5f, 1.f, 0.f
};

/** 怀旧效果 */
const float lf_colormatrix_huaijiu[] = {
    0.394f, 0.769f, 0.189f, 0.f, 0.f,
    0.349f, 0.6856f, 0.168f, 0.f, 0.f,
    0.272f, 0.534f, 0.131f, 0.f, 0.f,
    0.f, 0.f, 0.f, 1.f, 0.f
};

/** 灰度效果 */
const float lf_colormatrix_huidu[] = {
    0.33f ,0.59f ,0.11f ,0.f ,0.f,
    0.33f ,0.59f ,0.11f ,0.f, 0.f,
    0.33f ,0.59f ,0.11f ,0.f, 0.f,
    0.f, 0.f, 0.f, 1.f, 0.f
};
