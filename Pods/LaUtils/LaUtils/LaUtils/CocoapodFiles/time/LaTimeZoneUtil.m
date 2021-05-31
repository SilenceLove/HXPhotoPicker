//
//  LaTimeZoneUtil.m
//  student
//
//  Created by taomingyan on 2020/12/1.
//  Copyright © 2020 pplingo. All rights reserved.
//

#import "LaTimeZoneUtil.h"
#import "LaNSStringMacro.h"
@implementation LaTimeZoneUtil


+(NSString *)currentZone{
    NSTimeZone *zone = [NSTimeZone systemTimeZone];
    NSString *zoneAbbre = zone.abbreviation;
    NSString *zoneOffset = [[[zoneAbbre stringByReplacingOccurrencesOfString:@"GMT" withString:@""] stringByReplacingOccurrencesOfString:@"+" withString:@""]stringByReplacingOccurrencesOfString:@"-" withString:@""];
    if([M_VerifyString(zoneOffset) length] < 2){
        zoneOffset =[NSString stringWithFormat:@"0%@", zoneOffset];
    }
    
    if([M_VerifyString(zoneAbbre) length] > 4){
        return [NSString stringWithFormat:@"GMT %@%@00", [zoneAbbre substringWithRange:NSMakeRange(3, 1)], zoneOffset];
    }else{
        return zoneAbbre;
    }
}
@end
