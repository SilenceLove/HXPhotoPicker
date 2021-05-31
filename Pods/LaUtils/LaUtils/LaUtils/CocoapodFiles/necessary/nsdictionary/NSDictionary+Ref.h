//
//  NSDictionary+Ref.h
//  LaUtils
//
//  Created by taomingyan on 2020/12/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
#define M_VerifyDictionary(dictionary) (([[(dictionary) class] isSubclassOfClass:[NSDictionary class]])?(dictionary):@{})

@interface NSDictionary (Ref)

-(id)s_objectForKey:(id)key;
@end

NS_ASSUME_NONNULL_END
