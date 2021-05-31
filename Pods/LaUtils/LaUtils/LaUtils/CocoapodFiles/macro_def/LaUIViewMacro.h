//
//  LaUIViewMacro.h
//  student
//
//  Created by taomingyan on 2020/11/8.
//  Copyright © 2020 pplingo. All rights reserved.
//

#ifndef LaUIViewMacro_h
#define LaUIViewMacro_h

#define M_DeviceSizeLan CGSizeMake(MAX([[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height), MIN([[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height))

#define M_DeviceSizePor CGSizeMake(MIN([[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height), MAX([[UIScr

#define M_View_X(v) (v.frame.origin.x)
#define M_View_Y(v) (v.frame.origin.y)
#define M_View_Width(v) (v.frame.size.width)
#define M_View_Height(v) (v.frame.size.height)
#define M_View_Bottom_Y(v) (v.frame.origin.y+v.frame.size.height)
#define M_View_Right_X(v) (v.frame.origin.x+v.frame.size.width)

#define IsPortrait ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait || [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortraitUpsideDown)

#define M_StandardWidth   (IsPortrait ? 375.0 : 812.0)
#define M_StandardHeight  (IsPortrait ? 812.0 : 375.0)

// 当前设备大小
#define M_iPhoneWidth [UIScreen mainScreen].bounds.size.width
#define M_iPhoneHeight [UIScreen mainScreen].bounds.size.height

//水平方向距离间距
#define M_ResizeLan(space)            M_iPhoneWidth * space / M_StandardWidth
//垂直方向距离间距
#define M_ResizePor(space)            M_iPhoneHeight * space / M_StandardHeight

#define M_SCALESIZE(value)             AdaptSize(value)

#endif /* View_Oper_h */
