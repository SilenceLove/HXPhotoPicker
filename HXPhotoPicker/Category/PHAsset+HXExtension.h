//
//  PHAsset+HXExtension.h
//  HXPhotoPickerExample
//
//  Created by Slience on 2021/6/8.
//  Copyright © 2021 洪欣. All rights reserved.
//

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface PHAsset (HXExtension)

- (void)hx_checkForModificationsWithAssetPathMethodCompletion:(void (^)(BOOL))completion;
@end

NS_ASSUME_NONNULL_END
