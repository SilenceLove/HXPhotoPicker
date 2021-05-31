//
//  NSDictionary+Ref.m
//  LaUtils
//
//  Created by taomingyan on 2020/12/26.
//

#import "NSDictionary+Ref.h"

@implementation NSDictionary (Ref)

-(id)s_objectForKey:(id)key{
    if (key != nil) {
        return [self objectForKey:key];
    }else{
        return nil;
    }
}
@end
