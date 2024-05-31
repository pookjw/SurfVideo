//
//  ImmersiveEffectPickerViewController.mm
//  SurfVideo_UIKit
//
//  Created by Jinwoo Kim on 6/1/24.
//

#import "ImmersiveEffectPickerViewController.hpp"

#if TARGET_OS_VISION
#import "ImmersiveEffectPickerItemModel.hpp"
#import "ImmersiveEffectPickerViewModel.hpp"
#import "UIApplication+mrui_requestSceneWrapper.hpp"
#import <SurfVideoCore/constants.hpp>
#import <objc/runtime.h>

__attribute__((objc_direct_members))
@interface ImmersiveEffectPickerViewController ()
@property (retain, readonly, nonatomic) UICollectionViewCellRegistration *cellRegistration;
@property (retain, readonly, nonatomic) UIBarButtonItem *dismissBarButtonItem;
@property (retain, readonly, nonatomic) UIBarButtonItem *toggleImmsersiveSceneBarButtonItem;
@property (retain, readonly, nonatomic) ImmersiveEffectPickerViewModel *viewModel;
@end

@implementation ImmersiveEffectPickerViewController
@synthesize cellRegistration = _cellRegistration;
@synthesize dismissBarButtonItem = _dismissBarButtonItem;
@synthesize toggleImmsersiveSceneBarButtonItem = _toggleImmsersiveSceneBarButtonItem;
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
    [_toggleImmsersiveSceneBarButtonItem release];
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
        self.toggleImmsersiveSceneBarButtonItem
    ];
    
    navigationItem.rightBarButtonItems = @[
        self.dismissBarButtonItem
    ];
    
    //
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(receivedSceneWillConnectNotificaiton:)
                                               name:UISceneWillConnectNotification
                                             object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(receivedSceneDidDisconnectNotificaiton:)
                                               name:UISceneDidDisconnectNotification
                                             object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.viewModel loadWithCompletionHandler:nil];
}

- (UICollectionViewCellRegistration *)cellRegistration {
    if (auto cellRegistration = _cellRegistration) return cellRegistration;
    
    UICollectionViewCellRegistration *cellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:UICollectionViewListCell.class configurationHandler:^(__kindof UICollectionViewListCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, ImmersiveEffectPickerItemModel * _Nonnull item) {
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

- (UIBarButtonItem *)toggleImmsersiveSceneBarButtonItem {
    if (auto toggleImmsersiveSceneBarButtonItem = _toggleImmsersiveSceneBarButtonItem) return toggleImmsersiveSceneBarButtonItem;
    
    UIBarButtonItem *toggleImmsersiveSceneBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"visionpro"] style:UIBarButtonItemStylePlain target:self action:@selector(toggleImmsersiveSceneBarButtonItemDidTrigger:)];
    
    _toggleImmsersiveSceneBarButtonItem = [toggleImmsersiveSceneBarButtonItem retain];
    return [toggleImmsersiveSceneBarButtonItem autorelease];
}

- (ImmersiveEffectPickerViewModel *)viewModel {
    if (auto viewModel = _viewModel) return viewModel;
    
    ImmersiveEffectPickerViewModel *viewModel = [[ImmersiveEffectPickerViewModel alloc] initWithDataSource:[self makeDataSource]];
    
    _viewModel = [viewModel retain];
    return [viewModel autorelease];
}

- (UICollectionViewDiffableDataSource<NSNull *, ImmersiveEffectPickerItemModel *> *)makeDataSource __attribute__((objc_direct)) {
    UICollectionViewCellRegistration *cellRegistration = self.cellRegistration;
    
    UICollectionViewDiffableDataSource<NSNull *, ImmersiveEffectPickerItemModel *> *dataSource = [[UICollectionViewDiffableDataSource alloc] initWithCollectionView:self.collectionView cellProvider:^UICollectionViewCell * _Nullable(UICollectionView * _Nonnull collectionView, NSIndexPath * _Nonnull indexPath, ImmersiveEffectPickerItemModel * _Nonnull itemIdentifier) {
        return [collectionView dequeueConfiguredReusableCellWithRegistration:cellRegistration forIndexPath:indexPath item:itemIdentifier];
    }];
    
    return [dataSource autorelease];
}

- (void)toggleImmsersiveSceneBarButtonItemDidTrigger:(UIBarButtonItem *)sender {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        NSUserActivity *userActivity = scene.session.userInfo[SessionUserActivityKey];
        
        if (userActivity == nil) continue;
        
        if ([userActivity.activityType isEqualToString:ImmersiveEffectSceneUserActivityType]) {
            UISceneDestructionRequestOptions *f;
            [UIApplication.sharedApplication requestSceneSessionDestruction:scene.session options:nil errorHandler:^(NSError * _Nonnull error) {
                NSLog(@"%@", error);
            }];
            
            return;
        }
    }
    
    //
    
    NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:ImmersiveEffectSceneUserActivityType];
    
    [UIApplication.sharedApplication mruiw_requestMixedImmersiveSceneWithUserActivity:userActivity completionHandler:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    }];
    
    [userActivity release];
}

- (void)receivedSceneWillConnectNotificaiton:(NSNotification *)notification {
    __kindof UIScene *scene = notification.object;
    NSUserActivity *userActivity = scene.session.userInfo[SessionUserActivityKey];
    
    if (userActivity == nil) return;
    
    if ([userActivity.activityType isEqualToString:ImmersiveEffectSceneUserActivityType]) {
        self.toggleImmsersiveSceneBarButtonItem.image = [UIImage systemImageNamed:@"visionpro.fill"];
    }
}

- (void)receivedSceneDidDisconnectNotificaiton:(NSNotification *)notification {
    __kindof UIScene *scene = notification.object;
    NSUserActivity *userActivity = scene.session.userInfo[SessionUserActivityKey];
    
    if (userActivity == nil) return;
    
    if ([userActivity.activityType isEqualToString:ImmersiveEffectSceneUserActivityType]) {
        self.toggleImmsersiveSceneBarButtonItem.image = [UIImage systemImageNamed:@"visionpro"];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.viewModel postSelectedEffectNotificationAtIndexPath:indexPath];
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

@end

#endif
