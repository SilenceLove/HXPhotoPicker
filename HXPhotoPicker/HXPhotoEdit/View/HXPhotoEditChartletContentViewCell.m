//
//  HXPhotoEditChartletContentViewCell.m
//  photoEditDemo
//
//  Created by Silence on 2020/7/2.
//  Copyright © 2020 Silence. All rights reserved.
//

#import "HXPhotoEditChartletContentViewCell.h"
#import "HXPhotoEditChartletModel.h"
#import "HXPhotoEditChartletListView.h"
#import "HXPhotoDefine.h"

@interface HXPhotoEditChartletContentViewCell ()<UICollectionViewDataSource, UICollectionViewDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *flowLayout;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionLeftConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionRightConstraint;

@end

@implementation HXPhotoEditChartletContentViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    if (@available(iOS 11.0, *)){
        [self.collectionView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
    }
    CGFloat width;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
        width = (HX_ScreenWidth - 5 * 20) / 4;
        self.flowLayout.sectionInset = UIEdgeInsetsMake(75, 20, 20, 20);
    }else {
        self.flowLayout.sectionInset = UIEdgeInsetsMake(75, 20 + hxTopMargin, 20, 20 + hxTopMargin);
        width = ((HX_ScreenWidth - hxTopMargin * 2) - 9 * 20) / 8;
    }
    self.flowLayout.itemSize = CGSizeMake(width, width);
    self.flowLayout.minimumLineSpacing = 20;
    self.flowLayout.minimumInteritemSpacing = 20;
    
    [self.collectionView registerClass:[HXPhotoEditChartletListViewCell class] forCellWithReuseIdentifier:@"HXPhotoEditChartletListViewCell_Id"];
}
- (void)setModels:(NSArray<HXPhotoEditChartletModel *> *)models {
    _models = models;
    [self.collectionView reloadData];
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.models.count;
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HXPhotoEditChartletListViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"HXPhotoEditChartletListViewCell_Id" forIndexPath:indexPath];
    cell.model = self.models[indexPath.item];
    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.selectCellBlock) {
        HXPhotoEditChartletListViewCell *cell = (HXPhotoEditChartletListViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
        if (!cell.imageView.image) {
            return;
        }
        self.selectCellBlock(cell.imageView.image);
    }
}
@end
