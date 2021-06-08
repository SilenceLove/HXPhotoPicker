//
//  PHAsset+HXExtension.m
//  HXPhotoPickerExample
//
//  Created by Slience on 2021/6/8.
//  Copyright © 2021 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PHAsset+HXExtension.h"
#import "HXPhotoDefine.h"

@implementation PHAsset (HXExtension)

- (void)hx_checkForModificationsWithAssetPathMethodCompletion:(void (^)(BOOL))completion {
    [self requestContentEditingInputWithOptions:nil completionHandler:^(PHContentEditingInput *contentEditingInput, NSDictionary *info) {
        AVAsset *avAsset;
        if HX_IOS9Later {
            avAsset = contentEditingInput.audiovisualAsset;
        }else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
            avAsset = contentEditingInput.avAsset;
#pragma clang diagnostic pop
        }
        NSString *path = avAsset ? [avAsset description] : contentEditingInput.fullSizeImageURL.path;
        completion([path containsString:@"/Mutations/"]);
    }];
}
@end
