//
//  LFCancelBlock.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/3/17.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#ifndef LFMECancelBlock_h
#define LFMECancelBlock_h

typedef void(^lf_me_dispatch_cancelable_block_t)(BOOL cancel);

lf_me_dispatch_cancelable_block_t lf_dispatch_block_t(NSTimeInterval delay, void(^block)(void))
{
    __block lf_me_dispatch_cancelable_block_t cancelBlock = nil;
    lf_me_dispatch_cancelable_block_t delayBlcok = ^(BOOL cancel){
        if (!cancel) {
            if ([NSThread isMainThread]) {
                block();
            } else {
                dispatch_async(dispatch_get_main_queue(), block);
            }
        }
        cancelBlock = nil;
    };
    cancelBlock = delayBlcok;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (cancelBlock) {
            cancelBlock(NO);
        }
    });
    return delayBlcok;
}

void lf_me_dispatch_cancel(lf_me_dispatch_cancelable_block_t block)
{
    if (block) {
        block(YES);
    }
}

#endif /* LFMECancelBlock_h */
