//
//  WIZPhotoCollectionEditorController.m
//
//  Created by WizAlx on 19/08/2019.
//  Copyright © 2019 WizAlx. All rights reserved.
//

#import "WIZPhotoCollectionEditorController.h"


@interface WIZPhotoCollectionEditorController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDragDelegate, UICollectionViewDropDelegate>
{
    NSArray <UIImage*>* photosArray;
    int selectedCell;
    UIButton *selectBtn;
    
    //properties
    BOOL zoomEnabled;
    BOOL dragNDrop;
    BOOL selectEnabled;
    
    //selection
    NSMutableArray <NSNumber *>*selectedCells;
    UIButton *removeBtn;
}

@property (nonatomic) UICollectionView *collectionView;
@end

@implementation WIZPhotoCollectionEditorController

- (void)viewDidLoad {
    [super viewDidLoad];

    selectedCells = [NSMutableArray arrayWithCapacity:0];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:selectedCell inSection:0];
    
    [_collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:YES];
    
    if (self.navigationController) {
        selectBtn = [[UIButton alloc] init];
        [selectBtn setTitle:@"Select  " forState:UIControlStateNormal];
        [selectBtn addTarget:self action:@selector(selectTap) forControlEvents:UIControlEventTouchUpInside];
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:selectBtn];
        
        removeBtn = [[UIButton alloc] init];
        [removeBtn setImage:[UIImage imageNamed:@"delete"] forState:UIControlStateNormal];
        [removeBtn addTarget:self action:@selector(deleteImg) forControlEvents:UIControlEventTouchUpInside];
        
        [removeBtn.widthAnchor constraintEqualToConstant: 33].active = YES;
        [removeBtn.heightAnchor constraintEqualToConstant: 33].active = YES;
        
        removeBtn.enabled = false;
        
        UIBarButtonItem *removeBarItem = [[UIBarButtonItem alloc] initWithCustomView:removeBtn];
        
        
        UIButton *shareBtn = [[UIButton alloc] init];
        [shareBtn setImage:[UIImage imageNamed:@"share"] forState:UIControlStateNormal];
        [shareBtn addTarget:self action:@selector(shareImg) forControlEvents:UIControlEventTouchUpInside];
        
        [shareBtn.widthAnchor constraintEqualToConstant: 33].active = YES;
        [shareBtn.heightAnchor constraintEqualToConstant: 33].active = YES;
        
        UIBarButtonItem *shareBarItem = [[UIBarButtonItem alloc] initWithCustomView:shareBtn];
        
        self.toolbarItems = @[removeBarItem, shareBarItem];
    }
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:YES];

    photosArray = nil;
    [_collectionView removeFromSuperview];
    if (self.navigationController)
        self.navigationController.toolbarHidden = YES;
}

-(void)setPhotos:(NSArray<UIImage *> *)photos
{
    if (_collectionView)
        [_collectionView removeFromSuperview];

    photosArray = photos;

    UICollectionViewFlowLayout* flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.itemSize = CGSizeMake(50, 50);
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];

    CGRect collectionViewFrame = self.view.frame;
    collectionViewFrame.origin.x = 16;
    collectionViewFrame.origin.y = self.view.frame.origin.y;
    collectionViewFrame.size.width = self.view.frame.size.width - 32;
    collectionViewFrame.size.height = self.view.frame.size.height - 60;

    _collectionView = [[UICollectionView alloc] initWithFrame:collectionViewFrame collectionViewLayout:flowLayout];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;

    if (dragNDrop)
        [self setDragNDrop];

    _collectionView.showsHorizontalScrollIndicator = NO;
    _collectionView.showsVerticalScrollIndicator = NO;

    [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];

    _cellBackgroundColor = _cellBackgroundColor ? _cellBackgroundColor : [UIColor clearColor];

    [self.view addSubview:_collectionView];

    [_collectionView reloadData];
}

-(void)setProperties:(NSArray<NSNumber *> *)properties
{
    zoomEnabled = [properties containsObject:@(kEditorPropertyZoom)];
    dragNDrop = [properties containsObject:@(kEditorPropertyDragNDrop)];
    
    if (dragNDrop)
        [self setDragNDrop];
}

-(void)setDragNDrop
{
    _collectionView.dragDelegate = self;
    _collectionView.dropDelegate = self;
    _collectionView.dragInteractionEnabled = YES;
}

-(void)setCellBackgroundColor:(UIColor *)cellBackgroundColor
{
    _cellBackgroundColor = cellBackgroundColor;
    [_collectionView reloadData];
}

-(void)selectImage:(int)selectIndex
{
    selectedCell = selectIndex;
    [_collectionView reloadData];
}

#pragma mark - collectionView dragNdrop delegate

- (NSArray<UIDragItem *> *)collectionView:(UICollectionView *)collectionView itemsForBeginningDragSession:(id<UIDragSession>)session atIndexPath:(NSIndexPath *)indexPath
{
    UIImage *image = photosArray[indexPath.row];
    UIDragItem *dragItem = [[UIDragItem alloc] initWithItemProvider:[NSItemProvider new]];
    dragItem.localObject = image;
    return @[dragItem];
}


- (void)collectionView:(UICollectionView *)collectionView performDropWithCoordinator:(id<UICollectionViewDropCoordinator>)coordinator
{
    NSIndexPath *indexPath = coordinator.destinationIndexPath;
    if (indexPath) {
        [_collectionView performBatchUpdates:^{
            UIImage *tempImg = self->photosArray[coordinator.items.firstObject.sourceIndexPath.row];
            NSMutableArray *tempPhotos = [NSMutableArray arrayWithArray:self->photosArray];
            [tempPhotos removeObjectAtIndex:coordinator.items.firstObject.sourceIndexPath.row];
            [tempPhotos insertObject:tempImg atIndex:indexPath.row];
            self->photosArray = [tempPhotos copy];
            
            [self.collectionView deleteItemsAtIndexPaths:@[coordinator.items.firstObject.sourceIndexPath]];
            [self.collectionView insertItemsAtIndexPaths:@[indexPath]];
        } completion:^(BOOL finished) {
            if (finished && self.dragNDropAction)
                self.dragNDropAction(coordinator.items.firstObject.sourceIndexPath.row, indexPath.row);
        }];
        
        [coordinator dropItem:coordinator.items.firstObject.dragItem toItemAtIndexPath:indexPath];
    }
}


- (UICollectionViewDropProposal *)collectionView:(UICollectionView *)collectionView dropSessionDidUpdate:(id<UIDropSession>)session withDestinationIndexPath:(NSIndexPath *)destinationIndexPath
{
    return [[UICollectionViewDropProposal alloc] initWithDropOperation:UIDropOperationMove intent:UICollectionViewDropIntentInsertAtDestinationIndexPath];
}

#pragma mark - collectionView delegate & dataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return photosArray.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    float widthCell = self.view.frame.size.width / 4;
    return CGSizeMake(widthCell, widthCell);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
     UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    for (UIView *view in cell.subviews) {
        if ([view isKindOfClass:[UIImageView class]]) {
            [view removeFromSuperview];
        }
    }
    
    float widthCell = self.view.frame.size.width / 4;
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, widthCell, widthCell)];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.backgroundColor = _cellBackgroundColor;
    imageView.layer.cornerRadius = 8.0;
    imageView.clipsToBounds = YES;
    
    if (indexPath.row == selectedCell) {
        imageView.layer.borderColor = [UIColor whiteColor].CGColor;
        imageView.layer.borderWidth = 3.0;
    }
    
    if (selectedCells.count > 0 && [selectedCells containsObject:@(indexPath.row)]) {
        imageView.layer.borderColor = [UIColor whiteColor].CGColor;
        imageView.layer.borderWidth = 3.0;
    }
    
    [imageView setImage:photosArray[indexPath.row]];
    
    
    [cell addSubview:imageView];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (!selectEnabled)
        [self selectLonelyCell:indexPath];
    else
        [self selectFriendlyCell:indexPath];
    
}

-(void)selectLonelyCell:(NSIndexPath*)indexPath
{
    if (zoomEnabled && indexPath.row == selectedCell) {
        [self imageZoomerWithImage:photosArray[indexPath.row]];
    } else {
        [self selectImage:(int)indexPath.row];
        
        if (self.selectImage)
            self.selectImage((int)indexPath.row);
    }
    
    [_collectionView reloadData];
}

-(void)selectFriendlyCell:(NSIndexPath*)indexPath
{
    if ([selectedCells containsObject:@(indexPath.row)]) {
        [selectedCells removeObject:@(indexPath.row)];
    } else {
        [selectedCells addObject:@(indexPath.row)];
    }
    
    if (selectedCells.count > 0) {
        removeBtn.enabled = true;
    } else {
        removeBtn.enabled = false;
    }
    
    [_collectionView reloadData];
}

#pragma mark - work with imgs

-(void)imageZoomerWithImage:(UIImage*)image
{
    UIView *bgView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    bgView.backgroundColor = [UIColor clearColor];
    
    CGRect zoomFrame = CGRectMake(32, 64, [UIScreen mainScreen].bounds.size.width - 64, [UIScreen mainScreen].bounds.size.height - 128);
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:zoomFrame];
    [imageView setImage:image];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.userInteractionEnabled = YES;
    imageView.backgroundColor = _cellBackgroundColor;
    imageView.layer.cornerRadius = 32.0;
    imageView.clipsToBounds = YES;
    
    UITapGestureRecognizer *tapOnImage = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideImage:)];
    [bgView addGestureRecognizer:tapOnImage];
    
    [bgView addSubview:imageView];
    
    UILabel *infoLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 70 - 128, [UIScreen mainScreen].bounds.size.width - 64, 40)];
    infoLbl.text = @"Tap to hide";
    infoLbl.textAlignment = NSTextAlignmentCenter;
    infoLbl.font = [UIFont boldSystemFontOfSize:20];
    infoLbl.backgroundColor = [UIColor colorWithWhite:0 alpha:0.75];
    infoLbl.textColor = [UIColor whiteColor];
    
    [imageView addSubview:infoLbl];
    
    if (self.navigationController)
        [self.navigationController.view addSubview:bgView];
    else
        [self.view addSubview:bgView];
}

-(void)hideImage:(UITapGestureRecognizer*)tgr
{
    UIImageView *tapView = (UIImageView*)tgr.view;
    [tapView removeFromSuperview];
}

-(void)selectTap
{
    selectedCells = [NSMutableArray arrayWithCapacity:0];
    
    if (!selectEnabled) {
        self.navigationController.toolbarHidden = NO;
        [selectBtn setTitle:@"Cancel" forState:UIControlStateNormal];
        selectedCell = -1;
    } else {
        self.navigationController.toolbarHidden = YES;
        [selectBtn setTitle:@"Select" forState:UIControlStateNormal];
        selectedCell = 0;
    }
    selectEnabled = !selectEnabled;
    
    [_collectionView reloadData];
}

-(void)deleteImg
{
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"ATTENTION!", @"") message:NSLocalizedString(@"Delete frame?", @"") preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *yes = [UIAlertAction actionWithTitle:NSLocalizedString(@"YES",@"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        if (self.deleteImages && self->selectedCells.count > 0)
            self.deleteImages(self->selectedCells);
        
        NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc] init];
        for (NSNumber *idx in self->selectedCells)
            [indexSet addIndex:[idx integerValue]];
        
        NSMutableArray *chandedPhotosArray = [NSMutableArray arrayWithArray:self->photosArray];
        [chandedPhotosArray removeObjectsAtIndexes:indexSet];
        self->photosArray = chandedPhotosArray;
        
        [self selectTap];
        
        [self.collectionView reloadData];
    }];
    UIAlertAction *no = [UIAlertAction actionWithTitle:NSLocalizedString(@"NO",@"") style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:yes];
    [alert addAction:no];
    
    [self presentViewController:alert animated:YES completion:nil];

}

-(void)shareImg
{
    NSMutableArray *arrayForSharing = [NSMutableArray arrayWithCapacity:0];
    
    for (NSNumber *selectIndex in selectedCells)
        [arrayForSharing addObject:photosArray[[selectIndex intValue]]];

    UIActivityViewController *activityViewController =
    [[UIActivityViewController alloc] initWithActivityItems:arrayForSharing
                                      applicationActivities:nil];
    
    [activityViewController setCompletionWithItemsHandler:^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
        if (completed) {
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Successful", @"") message:NSLocalizedString(@"Images saved successfully", @"") preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
            
            [alert addAction:ok];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
    
    [self presentViewController:activityViewController animated:YES completion:nil];
}
@end
