//
//  EditorRealityMenuViewController.mm
//  SurfVideo_UIKit
//
//  Created by Jinwoo Kim on 6/8/24.
//

#import "EditorRealityMenuViewController.hpp"

#if TARGET_OS_VISION

#import "EditorRealityMenuViewModel.hpp"
#import "EditorRealityMenuCollectionViewLayout.hpp"
#import "EditorRealityMenuContentConfiguration.hpp"
#import "UIView+Private.h"
#import "UICollectionReusableView+Private.h"
#import "UICollectionView+Private.h"
#import "UIApplication+mrui_requestSceneWrapper.hpp"
#import <SurfVideoCore/constants.hpp>

@interface EditorRealityMenuCollectionView : UICollectionView
@end

@implementation EditorRealityMenuCollectionView

- (BOOL)_shouldDeselectItemsOnTouchesBegan {
    return YES;
}

@end

__attribute__((objc_direct_members))
@interface EditorRealityMenuViewController () <UICollectionViewDelegate>
@property (retain, readonly, nonatomic) UICollectionView *collectionView;
@property (retain, readonly, nonatomic) UICollectionViewCellRegistration *cellRegistration;
@property (retain, readonly, nonatomic) EditorRealityMenuViewModel *viewModel;
@property (readonly, assign) UIScene * _Nullable immersiveSpaceScene;
@property (readonly, nonatomic) BOOL isScrollingTrackViewWithHandTrackingEnabled;
@property (assign, nonatomic) BOOL prev_isScrollingTrackViewWithHandTrackingEnabled;
@end

@implementation EditorRealityMenuViewController

@synthesize collectionView = _collectionView;
@synthesize viewModel = _viewModel;
@synthesize cellRegistration = _cellRegistration;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self commonInit_EditorRealityMenuViewController];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self commonInit_EditorRealityMenuViewController];
    }
    
    return self;
}

- (void)dealloc {
    [_collectionView release];
    [_viewModel release];
    [_cellRegistration release];
    [super dealloc];
}

- (void)loadView {
    self.view = self.collectionView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.viewModel loadDataSourceWithCompletionHandler:nil];
}

- (void)commonInit_EditorRealityMenuViewController __attribute__((objc_direct)) {
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(receivedSceneWillConnectNotificaiton:)
                                               name:UISceneWillConnectNotification
                                             object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(receivedSceneDidDisconnectNotificaiton:)
                                               name:UISceneDidDisconnectNotification
                                             object:nil];
}

- (UICollectionView *)collectionView {
    if (auto collectionView = _collectionView) return collectionView;
    
    EditorRealityMenuCollectionViewLayout *collectionViewLayout = [EditorRealityMenuCollectionViewLayout new];
    UICollectionView *collectionView = [[EditorRealityMenuCollectionView alloc] initWithFrame:CGRectNull collectionViewLayout:collectionViewLayout];
    [collectionViewLayout release];
    
    collectionView.allowsMultipleSelection = YES;
    collectionView.delegate = self;
    
    [collectionView sws_enablePlatter:UIBlurEffectStyleSystemMaterial];
    
    _collectionView = [collectionView retain];
    return [collectionView autorelease];
}

- (EditorRealityMenuViewModel *)viewModel {
    if (auto viewModel = _viewModel) return viewModel;
    
    EditorRealityMenuViewModel *viewModel = [[EditorRealityMenuViewModel alloc] initWithDataSource:[self makeDataSource]];
    
    _viewModel = [viewModel retain];
    return [viewModel autorelease];
}

- (UICollectionViewDiffableDataSource<NSNull *, EditorRealityMenuItemModel *> *)makeDataSource __attribute__((objc_direct)) {
    UICollectionViewCellRegistration *cellRegistration = self.cellRegistration;
    
    UICollectionViewDiffableDataSource<NSNull *, EditorRealityMenuItemModel *> *dataSource = [[UICollectionViewDiffableDataSource alloc] initWithCollectionView:self.collectionView cellProvider:^UICollectionViewCell * _Nullable(UICollectionView * _Nonnull collectionView, NSIndexPath * _Nonnull indexPath, id  _Nonnull itemIdentifier) {
        return [collectionView dequeueConfiguredReusableCellWithRegistration:cellRegistration forIndexPath:indexPath item:itemIdentifier];
    }];
    
    return [dataSource autorelease];
}

- (UICollectionViewCellRegistration *)cellRegistration {
    if (auto cellRegistration = _cellRegistration) return cellRegistration;
    
    UICollectionViewCellRegistration *cellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:UICollectionViewCell.class configurationHandler:^(__kindof UICollectionViewCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, EditorRealityMenuItemModel * _Nonnull itemModel) {
        EditorRealityMenuContentConfiguration *contentConfiguration = [[EditorRealityMenuContentConfiguration alloc] initWithItemModel:itemModel selected:[cell._collectionView.indexPathsForSelectedItems containsObject:indexPath]];
        cell.contentConfiguration = contentConfiguration;
        [contentConfiguration release];
    }];
    
    _cellRegistration = [cellRegistration retain];
    return cellRegistration;
}

- (UIScene *)immersiveSpaceScene {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (scene.session.role == UISceneSessionRoleImmersiveSpaceApplication) {
            return scene;
        }
    }
    
    return nil;
}

- (BOOL)isScrollingTrackViewWithHandTrackingEnabled {
    for (NSIndexPath *indexPath in self.collectionView.indexPathsForSelectedItems) {
        if ([self.viewModel itemModelForIndexPath:indexPath].type == EditorRealityMenuItemModelTypeScrollTrackViewWithHandTracking) {
            return YES;
        }
    }
    
    return NO;
}

- (void)receivedSceneWillConnectNotificaiton:(NSNotification *)notification {
    __kindof UIScene *scene = notification.object;
    if (scene == nil) return;
    
    if (scene.session.role == UISceneSessionRoleImmersiveSpaceApplication) {
        UICollectionView *collectionView = self.collectionView;
        
        [collectionView selectItemAtIndexPath:[self.viewModel indexPathForItemType:EditorRealityMenuItemModelTypeImmersiveSpace] animated:YES scrollPosition:0];
        [self.viewModel didChangeSelectedItemsForIndexPaths:collectionView.indexPathsForSelectedItems];
        [self notifyDidToggleScrollingTrackViewWithHandTrackingDelegate];
    }
}

- (void)receivedSceneDidDisconnectNotificaiton:(NSNotification *)notification {
    __kindof UIScene *scene = notification.object;
    if (scene == nil) return;
    
    if (scene.session.role == UISceneSessionRoleImmersiveSpaceApplication) {
        UICollectionView *collectionView = self.collectionView;
        
        [collectionView deselectItemAtIndexPath:[self.viewModel indexPathForItemType:EditorRealityMenuItemModelTypeImmersiveSpace] animated:YES];
        [self.viewModel didChangeSelectedItemsForIndexPaths:collectionView.indexPathsForSelectedItems];
        [self notifyDidToggleScrollingTrackViewWithHandTrackingDelegate];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    EditorRealityMenuItemModel *itemModel = [self.viewModel itemModelForIndexPath:indexPath];
    EditorRealityMenuItemModelType type = itemModel.type;
    
    switch (type) {
        case EditorRealityMenuItemModelTypeImmersiveSpace:
            [self requestImmsersiveSpaceScene];
            break;
        default:
            break;
    }
    
    [self.viewModel didChangeSelectedItemsForIndexPaths:self.collectionView.indexPathsForSelectedItems];
    [self notifyDidToggleScrollingTrackViewWithHandTrackingDelegate];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    EditorRealityMenuItemModel *itemModel = [self.viewModel itemModelForIndexPath:indexPath];
    EditorRealityMenuItemModelType type = itemModel.type;
    
    switch (type) {
        case EditorRealityMenuItemModelTypeImmersiveSpace:
            [self destructImmsersiveSpaceScene];
            break;
        default:
            break;
    }
    
    [self.viewModel didChangeSelectedItemsForIndexPaths:self.collectionView.indexPathsForSelectedItems];
    [self notifyDidToggleScrollingTrackViewWithHandTrackingDelegate];
}

- (BOOL)requestImmsersiveSpaceScene __attribute__((objc_direct)) {
    if (self.immersiveSpaceScene != nil) return NO;
    
    NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:ImmersiveEffectSceneUserActivityType];
    
    [UIApplication.sharedApplication mruiw_requestMixedImmersiveSceneWithUserActivity:userActivity completionHandler:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    }];
    
    [userActivity release];
    
    return YES;
}

- (BOOL)destructImmsersiveSpaceScene __attribute__((objc_direct)) {
    if (UIScene *scene = self.immersiveSpaceScene) {
        [UIApplication.sharedApplication requestSceneSessionDestruction:scene.session options:nil errorHandler:^(NSError * _Nonnull error) {
            NSLog(@"%@", error);
        }];
        
        return YES;
    }
    
    return NO;
}

- (void)notifyDidToggleScrollingTrackViewWithHandTrackingDelegate __attribute__((objc_direct)) {
    BOOL isScrollingTrackViewWithHandTrackingEnabled = self.isScrollingTrackViewWithHandTrackingEnabled;
    
    if (self.prev_isScrollingTrackViewWithHandTrackingEnabled != isScrollingTrackViewWithHandTrackingEnabled) {
        [self.delegate editorRealityMenuViewController:self didToggleScrollingTrackViewWithHandTracking:isScrollingTrackViewWithHandTrackingEnabled];
        
        self.prev_isScrollingTrackViewWithHandTrackingEnabled = isScrollingTrackViewWithHandTrackingEnabled;
    }
}

@end

#endif
