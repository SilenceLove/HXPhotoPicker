//
//  LaFontMacrh.h
//  LaUtils
//
//  Created by 孙程雷 on 2020/11/27.
//  Copyright © 2020 pplingo. All rights reserved.
//

#import "LaUIViewMacro.h"

#ifndef LaFontMacrh_h
#define LaFontMacrh_h


// 字体大小
#define M_FONTSIZE(value)          [UIFont systemFontOfSize:AdaptSize(value)]

#define M_FONTSIZE_LIGHT(value)    [UIFont systemFontOfSize:AdaptSize(value) weight:UIFontWeightLight]
#define M_FONTSIZE_BLOD(value)     [UIFont systemFontOfSize:AdaptSize(value) weight:UIFontWeightBold]
#define M_FONTSIZE_REGULAR(value)  [UIFont systemFontOfSize:AdaptSize(value) weight:UIFontWeightRegular]
#define M_FONTSIZE_MEDIUM(value)   [UIFont systemFontOfSize:AdaptSize(value) weight:UIFontWeightMedium]
#define M_FONTSIZE_SEMIBOLD(value)   [UIFont systemFontOfSize:AdaptSize(value) weight:UIFontWeightSemibold]

/**
 *  字体适配
 */
static inline CGFloat AdaptSize(CGFloat fontSize){
   if (M_iPhoneWidth==375){
        return fontSize;
    } else if (M_iPhoneWidth == 414){
        return fontSize*1.1;
    } else if (M_iPhoneWidth < 375) {
        return fontSize*0.9;
    }
    return fontSize*1.2;
}


#endif /* LaFontMacrh_h */
