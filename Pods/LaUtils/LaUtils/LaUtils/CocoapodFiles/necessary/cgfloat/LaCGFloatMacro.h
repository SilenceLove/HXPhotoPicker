//
//  LaCGFloatOper.h
//  student
//
//  Created by taomingyan on 2020/11/8.
//  Copyright © 2020 pplingo. All rights reserved.
//

#ifndef LaCGFloatOper_h
#define LaCGFloatOper_h


//判断cgfloat数据是否是有效的,无效抓换成0
#define M_ValidFloat(x)  (isnan(x)||isinf(x)||(x>2000)||(x<-2000))?0.00001:(x)
//判断float是否是有效的
#define M_IsFloatValid(x)  ((!isnan(x))&&(!isinf(x)&&(x<2000)&&(x>-2000)))

#endif /* LaFloatOper_h */
