//
//  LaNSStringMacro.h
//  student
//
//  Created by taomingyan on 2020/11/8.
//  Copyright © 2020 pplingo. All rights reserved.
//

#ifndef LaNSStringMacro_h
#define LaNSStringMacro_h

#define M_VerifyString(string) ((NSString *)(([[(string) class] isSubclassOfClass:[NSString class]])?(string):(([[(string) class] isSubclassOfClass:[NSNumber class]])?[NSString stringWithFormat:@"%@",string]:@"")))

#endif /* LaNSStringMacro_h */
