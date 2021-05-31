//
//  LaCGPointOper.h
//  student
//
//  Created by taomingyan on 2020/11/8.
//  Copyright © 2020 pplingo. All rights reserved.
//

#ifndef LaCGPointOper_h
#define LaCGPointOper_h

//判断point是否包含无效数据
#define M_IsCGPointValid(point) (Is_Float_Valid(point.x)&&Is_Float_Valid(point.y))
//判断frame是否包含无效数据
#define M_IsFrameValid(frame) (Is_Float_Valid(frame.origin.x)&&Is_Float_Valid(frame.origin.x)&&Is_Float_Valid(frame.size.width)&&Is_Float_Valid(frame.size.height))

#endif /* LaCGPointOper_h */
