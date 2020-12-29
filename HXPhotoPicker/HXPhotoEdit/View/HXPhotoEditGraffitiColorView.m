//
//  HXPhotoEditGraffitiColorView.m
//  photoEditDemo
//
//  Created by Silence on 2020/6/20.
//  Copyright © 2020 Silence. All rights reserved.
//

#import "HXPhotoEditGraffitiColorView.h"
#import "HXPhotoEditGraffitiColorViewCell.h"
#import "UIImage+HXExtension.h"
#import "NSBundle+HXPhotoPicker.h"

@interface HXPhotoEditGraffitiColorView ()<UICollectionViewDataSource, UICollectionViewDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *flowLayout;
@property (weak, nonatomic) IBOutlet UIButton *repealBtn;
@property (strong, nonatomic) NSMutableArray *colorModels;
@property (strong, nonatomic) HXPhotoEditGraffitiColorModel *currentSelectModel;
@end

@implementation HXPhotoEditGraffitiColorView

+ (instancetype)initView {
    return [[[NSBundle hx_photoPickerBundle] loadNibNamed:NSStringFromClass(self) owner:nil options:nil] lastObject];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.repealBtn.enabled = NO;
    
    self.flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.flowLayout.sectionInset = UIEdgeInsetsMake(0, 15, 0, 0);
    self.flowLayout.minimumInteritemSpacing = 5;
    self.flowLayout.itemSize = CGSizeMake(37.f, 37.f);
    
    [self.repealBtn setImage:[UIImage hx_imageContentsOfFile:@"hx_photo_edit_repeal"] forState:UIControlStateNormal];
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([HXPhotoEditGraffitiColorViewCell class]) bundle:[NSBundle hx_photoPickerBundle]] forCellWithReuseIdentifier:NSStringFromClass([HXPhotoEditGraffitiColorViewCell class])];
}
- (void)setUndo:(BOOL)undo {
    _undo = undo;
    self.repealBtn.enabled = undo;
}
- (void)setDrawColors:(NSArray<UIColor *> *)drawColors {
    _drawColors = drawColors;
    self.colorModels = @[].mutableCopy;
    for (UIColor *color in drawColors) {
        HXPhotoEditGraffitiColorModel *model = [[HXPhotoEditGraffitiColorModel alloc] init];
        model.color = color;
        [self.colorModels addObject:model];
        if (self.colorModels.count == self.defaultDarwColorIndex + 1) {
            model.selected = YES;
            self.currentSelectModel = model;
        }
    }
    [self.collectionView reloadData];
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.colorModels.count;
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HXPhotoEditGraffitiColorViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([HXPhotoEditGraffitiColorViewCell class]) forIndexPath:indexPath];
    cell.model = self.colorModels[indexPath.item];
    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    HXPhotoEditGraffitiColorModel *model = self.colorModels[indexPath.item];
    if (self.currentSelectModel == model) {
        return;
    }
    if (self.currentSelectModel.selected) {
        self.currentSelectModel.selected = NO;
        HXPhotoEditGraffitiColorViewCell *beforeCell = (HXPhotoEditGraffitiColorViewCell *)[collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:[self.colorModels indexOfObject:self.currentSelectModel] inSection:0]];
        [beforeCell setSelected:NO];
    }
    model.selected = YES;
    self.currentSelectModel = model;
    if (self.selectColorBlock) {
        self.selectColorBlock(model.color);
    }
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
}
- (IBAction)didRepealBtnClick:(id)sender {
    if (self.undoBlock) {
        self.undoBlock();
    }
}

@end
