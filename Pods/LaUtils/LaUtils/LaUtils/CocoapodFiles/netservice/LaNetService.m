//
//  LaNetService.m

#import "LaNetService.h"
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "Reachability.h"

@implementation LaNetService

+(NSString *)getCellerType{
    CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
    NSString *currentStatus = nil;
    if (@available(iOS 12.0, *)) {
        NSDictionary *dic = info.serviceCurrentRadioAccessTechnology;
        currentStatus  = [[dic allValues] firstObject];
      
    } else {
        currentStatus  = info.currentRadioAccessTechnology;
        // Fallback on earlier versions
    }
    
    NSString *netconnType = @"UNKNOWN";
    if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyGPRS"]) {
        netconnType = @"WWANGPRS";
    }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyEdge"]) {
        netconnType = @"WWAN2.75G EDGE";
    }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyWCDMA"]){
        netconnType = @"WWAN3G";
    }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyHSDPA"]){
        netconnType = @"WWAN3.5G HSDPA";
    }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyHSUPA"]){
        netconnType = @"WWAN3.5G HSUPA";
    }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMA1x"]){
        netconnType = @"WWAN2G";
    }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORev0"]){
        netconnType = @"WWAN3G";
    }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORevA"]){
        netconnType = @"WWAN3G";
    }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORevB"]){
        netconnType = @"WWAN3G";
    }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyeHRPD"]){
        netconnType = @"WWANHRPD";
    }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyLTE"]){
        netconnType = @"WWAN4G";
    }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyNRNSA"]){
        netconnType = @"WWAN5G";
    }
    else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyNR"]){
        netconnType = @"WWAN5G";
    }
    return netconnType;
}

// 获取网络环境的方法
+ (NSString *)networkType{
    
    Reachability *reachability   = [Reachability reachabilityWithHostName:@"www.apple.com"];
        NetworkStatus internetStatus = [reachability currentReachabilityStatus];
        switch (internetStatus) {
            case ReachableViaWiFi:
                return @"WIFI";
                break;
                
            case ReachableViaWWAN:
                return [[self class] getCellerType];
                //net = [self getNetType ];   //判断具体类型
                break;
                
            case NotReachable:
                return @"UNKNOWN";
                
            default:
                break;
        }
}

+(NSString *)serviceProvider{
    CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc]init];
    CTCarrier *carrier = [info subscriberCellularProvider];
    NSString *mobile;
    if (!carrier.isoCountryCode) {
        mobile = @"UNKNOWN";
    }else{
        mobile = [carrier carrierName];
    }
    return mobile;
}

@end
