//
//  HXCollectionView.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/17.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXCollectionView.h"
#import "HXPhotoSubViewCell.h"
#import "HXPhotoModel.h"
@interface HXCollectionView ()
@property (weak, nonatomic) UILongPressGestureRecognizer *longPgr;
@property (strong, nonatomic) NSIndexPath *originalIndexPath;
@property (strong, nonatomic) UIView *tempMoveCell;
@property (assign, nonatomic) CGPoint lastPoint;
@property (nonatomic, strong) UICollectionViewCell *dragCell;
@property (nonatomic, strong) NSIndexPath *moveIndexPath;
@property (nonatomic, assign) BOOL isDeleteItem;
@property (assign, nonatomic) BOOL isAddBtn;
@end

@implementation HXCollectionView

@dynamic delegate;
@dynamic dataSource;

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout
{
    if (self = [super initWithFrame:frame collectionViewLayout:layout]) {
        self.layer.masksToBounds = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.editEnabled = YES;
        [self addGesture];
    }
    return self;
}

- (void)addGesture
{
    UILongPressGestureRecognizer *longPgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPrgEvent:)];
    longPgr.minimumPressDuration = 0.25f;
    longPgr.enabled = self.editEnabled;
    [self addGestureRecognizer:longPgr];
    self.longPgr = longPgr;
}

- (void)setEditEnabled:(BOOL)editEnabled {
    _editEnabled = editEnabled;
    self.longPgr.enabled = editEnabled;
}

- (void)longPrgEvent:(UILongPressGestureRecognizer *)longPgr
{
    if (longPgr.state == UIGestureRecognizerStateBegan) {
        self.isDeleteItem = NO;
        [self gestureRecognizerBegan:longPgr];
    }
    if (longPgr.state == UIGestureRecognizerStateChanged) {
        if (_originalIndexPath.section != 0 || self.isAddBtn) {
            return;
        }
        [self gestureRecognizerChange:longPgr];
        [self moveCell];
    }
    if (longPgr.state == UIGestureRecognizerStateCancelled ||
        longPgr.state == UIGestureRecognizerStateEnded){
        if (self.isAddBtn) {
            self.isAddBtn = NO;
            return;
        }
        [self handelItemInSpace];
        if (!self.isDeleteItem) {
            [self gestureRecognizerCancelOrEnd:longPgr];
        }
    }
}

- (void)gestureRecognizerBegan:(UILongPressGestureRecognizer *)longPgr
{
    self.originalIndexPath = [self indexPathForItemAtPoint:[longPgr locationOfTouch:0 inView:longPgr.view]];
    HXPhotoSubViewCell *cell = (HXPhotoSubViewCell *)[self cellForItemAtIndexPath:self.originalIndexPath];
    if (cell.model.type == HXPhotoModelMediaTypeCamera) {
        self.isAddBtn = YES;
        return;
    }
    UIView *tempMoveCell = [cell snapshotViewAfterScreenUpdates:NO];
    self.dragCell = cell;
    cell.hidden = YES;
    self.tempMoveCell = tempMoveCell;
    self.tempMoveCell.frame = cell.frame;
    [UIView animateWithDuration:0.2 animations:^{
        self.tempMoveCell.alpha = 0.8;
        self.tempMoveCell.transform = CGAffineTransformMakeScale(1.15, 1.15);
    }];
    [self addSubview:self.tempMoveCell];
    
    self.lastPoint = [longPgr locationOfTouch:0 inView:self];
}

- (void)gestureRecognizerChange:(UILongPressGestureRecognizer *)longPgr
{
    CGFloat tranX = [longPgr locationOfTouch:0 inView:longPgr.view].x - self.lastPoint.x;
    CGFloat tranY = [longPgr locationOfTouch:0 inView:longPgr.view].y - self.lastPoint.y;
    self.tempMoveCell.center = CGPointApplyAffineTransform(_tempMoveCell.center, CGAffineTransformMakeTranslation(tranX, tranY));
    self.lastPoint = [longPgr locationOfTouch:0 inView:longPgr.view];
}

- (void)gestureRecognizerCancelOrEnd:(UILongPressGestureRecognizer *)longPgr
{
    if ([self.delegate respondsToSelector:@selector(dragCellCollectionViewCellEndMoving:)]) {
        [self.delegate dragCellCollectionViewCellEndMoving:self];
    }
    self.userInteractionEnabled = NO;
    [UIView animateWithDuration:0.25 animations:^{
        self.tempMoveCell.center = self.dragCell.center;
        self.tempMoveCell.transform = CGAffineTransformIdentity;
        self.tempMoveCell.alpha = 1;
    } completion:^(BOOL finished) {
        [self.tempMoveCell removeFromSuperview];
        self.dragCell.hidden = NO;
        self.userInteractionEnabled = YES;
    }];
}

- (NSArray *)findAllLastIndexPathInVisibleSection {
    
    NSArray *array = [self indexPathsForVisibleItems];
    array = [array sortedArrayUsingComparator:^NSComparisonResult(NSIndexPath *  _Nonnull obj1, NSIndexPath *  _Nonnull obj2) {
        return obj1.section > obj2.section;
    }];
    NSMutableArray *totalArray = [NSMutableArray arrayWithCapacity:0];
    NSInteger tempSection = -1;
    NSMutableArray *tempArray = nil;
    
    for (NSIndexPath *indexPath in array) {
        if (tempSection != indexPath.section) {
            tempSection = indexPath.section;
            if (tempArray) {
                NSArray *temp = [tempArray sortedArrayUsingComparator:^NSComparisonResult(NSIndexPath *  _Nonnull obj1, NSIndexPath *  _Nonnull obj2) {
                    return obj1.row > obj2.row;
                }];
                [totalArray addObject:temp.lastObject];
            }
            tempArray = [NSMutableArray arrayWithCapacity:0];
        }
        [tempArray addObject:indexPath];
    }
    
    NSArray *temp = [tempArray sortedArrayUsingComparator:^NSComparisonResult(NSIndexPath *  _Nonnull obj1, NSIndexPath *  _Nonnull obj2) {
        return obj1.row > obj2.row;
    }];
    [totalArray addObject:temp.lastObject];
    return totalArray.copy;
}


- (void)handelItemInSpace {
    
    NSArray *totalArray = [self findAllLastIndexPathInVisibleSection];
    //找到目标空白区域
    CGRect rect;
    _moveIndexPath = nil;
    
    NSMutableArray *sourceArray = nil;
    //获取数据源
    if ([self.dataSource respondsToSelector:@selector(dataSourceArrayOfCollectionView:)]) {
        sourceArray = [NSMutableArray arrayWithArray:[self.dataSource dataSourceArrayOfCollectionView:self]];
    }
    
    for (NSIndexPath *indexPath in totalArray) {
        HXPhotoSubViewCell *sectionLastCell = (HXPhotoSubViewCell *)[self cellForItemAtIndexPath:indexPath];
        
        CGRect tempRect = CGRectMake(CGRectGetMaxX(sectionLastCell.frame),
                                     CGRectGetMinY(sectionLastCell.frame),
                                     self.frame.size.width - CGRectGetMaxX(sectionLastCell.frame),
                                     CGRectGetHeight(sectionLastCell.frame));
        //空白区域小于item款度(实际是item的列间隙)
        if (CGRectGetWidth(tempRect) < CGRectGetWidth(sectionLastCell.frame)) {
            continue;
        }

        if (sectionLastCell.model.type == HXPhotoModelMediaTypeCamera) {
            continue;
        }
        
        if (CGRectContainsPoint(tempRect, _tempMoveCell.center)) {
            rect = tempRect;
            _moveIndexPath = indexPath;
            break;
        }
    }
    
    if (_moveIndexPath != nil) {
        [self moveItemToIndexPath:_moveIndexPath withSource:sourceArray];
    }else{
        _moveIndexPath = _originalIndexPath;
        UICollectionViewCell *sectionLastCell = [self cellForItemAtIndexPath:_moveIndexPath];
        float spaceHeight =    (self.frame.size.height - CGRectGetMaxY(sectionLastCell.frame)) > CGRectGetHeight(sectionLastCell.frame)?
        (self.frame.size.height - CGRectGetMaxY(sectionLastCell.frame)):0;
        
        CGRect spaceRect = CGRectMake(0,
                                      CGRectGetMaxY(sectionLastCell.frame),
                                      self.frame.size.width,
                                      spaceHeight);
        
        if (spaceHeight != 0 && CGRectContainsPoint(spaceRect, _tempMoveCell.center)) {
            [self moveItemToIndexPath:_moveIndexPath withSource:sourceArray];
        }
    }
}


- (void)moveItemToIndexPath:(NSIndexPath *)indexPath withSource:(NSMutableArray *)array
{
    if (_originalIndexPath.section == indexPath.section ){
        //同一分组
        if (_originalIndexPath.row != indexPath.row) {
            
            [self exchangeItemInSection:indexPath withSource:array];
        }else if (_originalIndexPath.row == indexPath.row){
            return;
        }
    }
}

- (void)moveCell{
    
    for (HXPhotoSubViewCell *cell in [self visibleCells]) {
        if ([self indexPathForCell:cell] == _originalIndexPath) {
            continue;
        }
        if (cell.model.type == HXPhotoModelMediaTypeCamera) {
            continue;
        }
        //计算中心距
        CGFloat spacingX = fabs(_tempMoveCell.center.x - cell.center.x);
        CGFloat spacingY = fabs(_tempMoveCell.center.y - cell.center.y);
        if (spacingX <= _tempMoveCell.bounds.size.width / 2.0f && spacingY <= _tempMoveCell.bounds.size.height / 2.0f) {
            _moveIndexPath = [self indexPathForCell:cell];
            if (_moveIndexPath.section != 0) {
                return;
            }
            
            //更新数据源
            [self updateDataSource];
            //移动
            [self moveItemAtIndexPath:_originalIndexPath toIndexPath:_moveIndexPath];
            //通知代理
            if ([self.delegate respondsToSelector:@selector(dragCellCollectionView:moveCellFromIndexPath:toIndexPath:)]) {
                [self.delegate dragCellCollectionView:self moveCellFromIndexPath:_originalIndexPath toIndexPath:_moveIndexPath];
            }
            //设置移动后的起始indexPath
            _originalIndexPath = _moveIndexPath;
        }
    }
}

- (void)exchangeItemInSection:(NSIndexPath *)indexPath withSource:(NSMutableArray *)sourceArray{
    
    NSMutableArray *orignalSection = [NSMutableArray arrayWithArray:sourceArray];
    NSInteger currentRow = _originalIndexPath.row;
    NSInteger toRow = indexPath.row;
    [orignalSection exchangeObjectAtIndex:currentRow withObjectAtIndex:toRow];
    //将重排好的数据传递给外部
    if ([self.delegate respondsToSelector:@selector(dragCellCollectionView:newDataArrayAfterMove:)]) {
        [self.delegate dragCellCollectionView:self newDataArrayAfterMove:sourceArray.copy];
    }
    [self moveItemAtIndexPath:_originalIndexPath toIndexPath:indexPath];
}


- (void)updateDataSource{
    NSMutableArray *temp = @[].mutableCopy;
    //获取数据源
    if ([self.dataSource respondsToSelector:@selector(dataSourceArrayOfCollectionView:)]) {
        [temp addObjectsFromArray:[self.dataSource dataSourceArrayOfCollectionView:self]];
    }
    //判断数据源是单个数组还是数组套数组的多section形式，YES表示数组套数组
    BOOL dataTypeCheck = ([self numberOfSections] != 1 || ([self numberOfSections] == 1 && [temp.firstObject isKindOfClass:[NSArray class]]));
    if (dataTypeCheck) {
        for (int i = 0; i < temp.count; i ++) {
            [temp replaceObjectAtIndex:i withObject:[temp[i] mutableCopy]];
        }
    }
    if (_moveIndexPath.section == _originalIndexPath.section) {
        NSMutableArray *orignalSection = dataTypeCheck ? temp[_originalIndexPath.section] : temp;
        if (_moveIndexPath.item > _originalIndexPath.item) {
            for (NSUInteger i = _originalIndexPath.item; i < _moveIndexPath.item ; i ++) {
                [orignalSection exchangeObjectAtIndex:i withObjectAtIndex:i + 1];
            }
        }else{
            for (NSUInteger i = _originalIndexPath.item; i > _moveIndexPath.item ; i --) {
                [orignalSection exchangeObjectAtIndex:i withObjectAtIndex:i - 1];
            }
        }
        
    }else{
        NSMutableArray *orignalSection = temp[_originalIndexPath.section];
        NSMutableArray *currentSection = temp[_moveIndexPath.section];
        [currentSection insertObject:orignalSection[_originalIndexPath.item] atIndex:_moveIndexPath.item];
        [orignalSection removeObject:orignalSection[_originalIndexPath.item]];
    }
    //将重排好的数据传递给外部
    if ([self.delegate respondsToSelector:@selector(dragCellCollectionView:newDataArrayAfterMove:)]) {
        [self.delegate dragCellCollectionView:self newDataArrayAfterMove:temp.copy];
    }
}


@end
