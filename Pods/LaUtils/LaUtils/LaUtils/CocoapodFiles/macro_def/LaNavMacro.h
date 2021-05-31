//
//  LaNavMacro.h
//  LaUtils
//
//  Created by 孙程雷 on 2020/11/27.
//  Copyright © 2020 pplingo. All rights reserved.
//

#ifndef LaNavMacro_h
#define LaNavMacro_h


//iPhone X适配
#define M_StatusBarHeight [[UIApplication sharedApplication] statusBarFrame].size.height        //获取状态栏的高度
#define M_NavBarHeight 44.0      //导航栏的高度
#define M_TopHeitht (M_StatusBarHeight + M_NavBarHeight)    //顶部状态栏加导航栏高度
#define M_TabBarHeight  ([[UIApplication sharedApplication] statusBarFrame].size.height > 20?83:49)  //根据状态栏的高度判断tabBar的高度
#define M_TabSpace  ([[UIApplication sharedApplication] statusBarFrame].size.height > 20?34:0)      //底部距安全区距离

// 横屏时距离左侧的距离
#define M_LeftWidth  (M_StatusBarHeight > 20 ? M_StatusBarHeight : 0)

#endif /* LaNavMacro_h */
