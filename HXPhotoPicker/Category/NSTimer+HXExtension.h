//
//  NSTimer+HXExtension.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2019/1/3.
//  Copyright © 2019年 Silence. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSTimer (HXExtension)
+ (id)hx_scheduledTimerWithTimeInterval:(NSTimeInterval)inTimeInterval block:(void (^)(void))inBlock repeats:(BOOL)inRepeats;
+ (id)hx_timerWithTimeInterval:(NSTimeInterval)inTimeInterval block:(void (^)(void))inBlock repeats:(BOOL)inRepeats;
@end

NS_ASSUME_NONNULL_END
