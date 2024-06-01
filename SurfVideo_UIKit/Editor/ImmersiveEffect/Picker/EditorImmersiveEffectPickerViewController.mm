//
//  EditorImmersiveEffectPickerViewController.mm
//  SurfVideo_UIKit
//
//  Created by Jinwoo Kim on 6/1/24.
//

#import "EditorImmersiveEffectPickerViewController.hpp"

#if TARGET_OS_VISION
#import "EditorImmersiveEffectPickerItemModel.hpp"
#import "EditorImmersiveEffectPickerViewModel.hpp"
#import "UIApplication+mrui_requestSceneWrapper.hpp"
#import <SurfVideoCore/constants.hpp>
#import <objc/runtime.h>

__attribute__((objc_direct_members))
@interface EditorImmersiveEffectPickerViewController ()
@property (retain, readonly, nonatomic) UICollectionViewCellRegistration *cellRegistration;
@property (retain, readonly, nonatomic) UIBarButtonItem *dismissBarButtonItem;
@property (retain, readonly, nonatomic) UIBarButtonItem *addBarButtonItem;
@property (retain, readonly, nonatomic) EditorImmersiveEffectPickerViewModel *viewModel;
@end

@implementation EditorImmersiveEffectPickerViewController
@synthesize cellRegistration = _cellRegistration;
@synthesize dismissBarButtonItem = _dismissBarButtonItem;
@synthesize addBarButtonItem = _addBarButtonItem;
@synthesize viewModel = _viewModel;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    UICollectionLayoutListConfiguration *listConfiguration = [[UICollectionLayoutListConfiguration alloc] initWithAppearance:UICollectionLayoutListAppearanceInsetGrouped];
    UICollectionViewCompositionalLayout *collectionViewLayout = [UICollectionViewCompositionalLayout layoutWithListConfiguration:listConfiguration];
    [listConfiguration release];
    
    if (self = [super initWithCollectionViewLayout:collectionViewLayout]) {
        [self commonInit_ImmersiveEffectsViewController];
    }
    
    return self;
}

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout {
    if (self = [super initWithCollectionViewLayout:layout]) {
        [self commonInit_ImmersiveEffectsViewController];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self commonInit_ImmersiveEffectsViewController];
    }
    
    return self;
}

- (void)dealloc {
    [_cellRegistration release];
    [_viewModel release];
    [_dismissBarButtonItem release];
    [_addBarButtonItem release];
    [super dealloc];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    unsigned int count;
    
    //
    
    objc_method_description *dataSourceRequiredMethodDescs = protocol_copyMethodDescriptionList(@protocol(UICollectionViewDataSource), YES, YES, &count);
    
    for (unsigned int i = 0; i < count; i++) {
        if (sel_isEqual(dataSourceRequiredMethodDescs[i].name, aSelector)) {
            free(dataSourceRequiredMethodDescs);
            return self.viewModel.dataSource;
        }
    }
    
    free(dataSourceRequiredMethodDescs);
    
    //
    
    objc_method_description *dataSourceOptionalMethodDescs = protocol_copyMethodDescriptionList(@protocol(UICollectionViewDataSource), NO, YES, &count);
    
    for (unsigned int i = 0; i < count; i++) {
        if (sel_isEqual(dataSourceOptionalMethodDescs[i].name, aSelector)) {
            free(dataSourceOptionalMethodDescs);
            return self.viewModel.dataSource;
        }
    }
    
    free(dataSourceOptionalMethodDescs);
    
    //
    
    return self;
}

- (void)commonInit_ImmersiveEffectsViewController __attribute__((objc_direct)) {
    UINavigationItem *navigationItem = self.navigationItem;
    navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    navigationItem.title = @"Effects";
    
    navigationItem.leftBarButtonItems = @[
        self.dismissBarButtonItem
    ];
    
    navigationItem.rightBarButtonItems = @[
        self.addBarButtonItem
    ];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.viewModel loadWithCompletionHandler:^{
        [self updateAddBarButtonItem];
    }];
}

- (UICollectionViewCellRegistration *)cellRegistration {
    if (auto cellRegistration = _cellRegistration) return cellRegistration;
    
    UICollectionViewCellRegistration *cellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:UICollectionViewListCell.class configurationHandler:^(__kindof UICollectionViewListCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, EditorImmersiveEffectPickerItemModel * _Nonnull item) {
        UIListContentConfiguration *contentConfiguration = [cell defaultContentConfiguration];
        contentConfiguration.text = item.title;
        cell.contentConfiguration = contentConfiguration;
    }];
    
    _cellRegistration = [cellRegistration retain];
    return cellRegistration;
}

- (UIBarButtonItem *)dismissBarButtonItem {
    if (auto dismissBarButtonItem = _dismissBarButtonItem) return dismissBarButtonItem;
    
    __weak auto weakSelf = self;
    
    UIAction *primaryAction = [UIAction actionWithTitle:@"Done" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
    }];
    
    UIBarButtonItem *dismissBarButtonItem = [[UIBarButtonItem alloc] initWithPrimaryAction:primaryAction];
    
    _dismissBarButtonItem = [dismissBarButtonItem retain];
    return [dismissBarButtonItem autorelease];
}

- (UIBarButtonItem *)addBarButtonItem {
    if (auto addBarButtonItem = _addBarButtonItem) return addBarButtonItem;
    
    __weak auto weakSelf = self;
    
    UIAction *primaryAction = [UIAction actionWithTitle:@"Add" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        auto _self = weakSelf;
        if (_self == nil) return;
        
        NSIndexPath *indexPath = _self.collectionView.indexPathsForSelectedItems.firstObject;
        if (indexPath == nil) return;
        
        EditorImmersiveEffectPickerItemModel *itemModel = [_self.viewModel itemModelAtIndexPath:indexPath];
        [_self.delegate editorImmersiveEffectPickerViewController:_self didAddImmersiveEffect:itemModel.effect];
    }];
    
    UIBarButtonItem *addBarButtonItem = [[UIBarButtonItem alloc] initWithPrimaryAction:primaryAction];
    addBarButtonItem.enabled = NO;
    
    _addBarButtonItem = [addBarButtonItem retain];
    return [addBarButtonItem autorelease];
}

- (EditorImmersiveEffectPickerViewModel *)viewModel {
    if (auto viewModel = _viewModel) return viewModel;
    
    EditorImmersiveEffectPickerViewModel *viewModel = [[EditorImmersiveEffectPickerViewModel alloc] initWithDataSource:[self makeDataSource]];
    
    _viewModel = [viewModel retain];
    return [viewModel autorelease];
}

- (UICollectionViewDiffableDataSource<NSNull *, EditorImmersiveEffectPickerItemModel *> *)makeDataSource __attribute__((objc_direct)) {
    UICollectionViewCellRegistration *cellRegistration = self.cellRegistration;
    
    UICollectionViewDiffableDataSource<NSNull *, EditorImmersiveEffectPickerItemModel *> *dataSource = [[UICollectionViewDiffableDataSource alloc] initWithCollectionView:self.collectionView cellProvider:^UICollectionViewCell * _Nullable(UICollectionView * _Nonnull collectionView, NSIndexPath * _Nonnull indexPath, EditorImmersiveEffectPickerItemModel * _Nonnull itemIdentifier) {
        return [collectionView dequeueConfiguredReusableCellWithRegistration:cellRegistration forIndexPath:indexPath item:itemIdentifier];
    }];
    
    return [dataSource autorelease];
}

- (void)updateAddBarButtonItem __attribute__((objc_direct)) {
    NSArray<NSIndexPath *> *indexPathsForSelectedItems = self.collectionView.indexPathsForSelectedItems;
    self.addBarButtonItem.enabled = (indexPathsForSelectedItems.count > 0);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self updateAddBarButtonItem];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self updateAddBarButtonItem];
}

@end

#endif
