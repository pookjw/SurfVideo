//
//  ProjectsViewController.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import "ProjectsViewController.hpp"
#import "ProjectsViewModel.hpp"
#import "EditorViewController.hpp"
#import "constants.hpp"
#import "UIApplication+mrui_requestSceneWrapper.hpp"
#import "PHPickerConfiguration+onlyReturnsIdentifiers.hpp"
#import "SVProjectsManager.hpp"
#import "UIAlertController+Private.h"
#import <PhotosUI/PhotosUI.h>
#import <objc/runtime.h>
#import <ranges>

__attribute__((objc_direct_members))
@interface ProjectsViewController () <UICollectionViewDelegate, PHPickerViewControllerDelegate>
@property (retain, readonly, nonatomic) UICollectionView *collectionView;
@property (retain, readonly, nonatomic) ProjectsViewModel *viewModel;
@property (retain, readonly, nonatomic) UIBarButtonItem *addBarButtonItem;
@property (retain, readonly, nonatomic) UIBarButtonItem *cleanupFootagesBarButtonItem;
@end

@implementation ProjectsViewController

@synthesize collectionView = _collectionView;
@synthesize viewModel = _viewModel;
@synthesize addBarButtonItem = _addBarButtonItem;
@synthesize cleanupFootagesBarButtonItem = _cleanupFootagesBarButtonItem;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self commonInit_ProjectsViewController];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self commonInit_ProjectsViewController];
    }
    
    return self;
}

- (void)dealloc {
    [_collectionView release];
    [_viewModel release];
    [_addBarButtonItem release];
    [_cleanupFootagesBarButtonItem release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupCollectionView];
    [self setupViewModel];
}

- (void)commonInit_ProjectsViewController __attribute__((objc_direct)) {
    UITabBarItem *tabBarItem = self.tabBarItem;
    tabBarItem.title = @"Projects";
    tabBarItem.image = [UIImage systemImageNamed:@"list.bullet"];
    
    UINavigationItem *navigationItem = self.navigationItem;
    navigationItem.title = @"Projects";
    navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    navigationItem.rightBarButtonItems = @[self.addBarButtonItem, self.cleanupFootagesBarButtonItem];
}

- (void)setupCollectionView __attribute__((objc_direct)) {
    UICollectionView *collectionView = self.collectionView;
    collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:collectionView];
}

- (void)setupViewModel __attribute__((objc_direct)) {
    [self.viewModel initializeWithCompletionHandler:^(NSError * _Nullable error) {
        assert(!error);
    }];
}

- (UICollectionView *)collectionView {
    if (auto collectionView = _collectionView) return collectionView;
    
    UICollectionLayoutListConfiguration *configuration = [[UICollectionLayoutListConfiguration alloc] initWithAppearance:UICollectionLayoutListAppearanceInsetGrouped];
    configuration.trailingSwipeActionsConfigurationProvider = [self makeTrailingSwipeActionsConfigurationProvider];
    
    UICollectionViewCompositionalLayout *collectionViewLayout = [UICollectionViewCompositionalLayout layoutWithListConfiguration:configuration];
    [configuration release];
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:collectionViewLayout];
    collectionView.delegate = self;
    
    _collectionView = [collectionView retain];
    
    return [collectionView autorelease];
}

- (ProjectsViewModel *)viewModel {
    if (auto viewModel = _viewModel) return viewModel;
    
    ProjectsViewModel *viewModel = [[ProjectsViewModel alloc] initWithDataSource:[self makeDataSource]];
    
    _viewModel = [viewModel retain];
    return [viewModel autorelease];
}

- (UIBarButtonItem *)addBarButtonItem {
    if (auto addBarButtonItem = _addBarButtonItem) return addBarButtonItem;
    
    __weak auto weakSelf = self;
    
    UIAction *addAction = [UIAction actionWithTitle:[NSString string] image:[UIImage systemImageNamed:@"plus"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        PHPickerConfiguration *configuration = [[PHPickerConfiguration alloc] initWithPhotoLibrary:[PHPhotoLibrary sharedPhotoLibrary]];
        configuration.selectionLimit = 0;
        configuration.sv_onlyReturnsIdentifiers = YES;
        
        PHPickerViewController *pickerViewController = [[PHPickerViewController alloc] initWithConfiguration:configuration];
        [configuration release];
        pickerViewController.delegate = weakSelf;
        
        [weakSelf presentViewController:pickerViewController animated:YES completion:nil];
        [pickerViewController release];
    }];
    
    UIBarButtonItem *addBarButtonItem = [[UIBarButtonItem alloc] initWithPrimaryAction:addAction];
    
    _addBarButtonItem = [addBarButtonItem retain];
    return [addBarButtonItem autorelease];
}

- (UIBarButtonItem *)cleanupFootagesBarButtonItem {
    if (auto cleanupFootagesBarButtonItem = _cleanupFootagesBarButtonItem) return cleanupFootagesBarButtonItem;
    
    __weak auto weakSelf = self;
    
    UIAction *cleanupFootagesAction = [UIAction actionWithTitle:[NSString string] image:[UIImage systemImageNamed:@"xmark.bin"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [SVProjectsManager.sharedInstance cleanupFootagesWithCompletionHandler:^(NSInteger cleanedUpFootagesCount, NSError * _Nullable error) {
            assert(!error);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *message = [NSString stringWithFormat:@"Clenaed footages count: %ld", cleanedUpFootagesCount];
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Done" message:message preferredStyle:UIAlertControllerStyleAlert];
                
                alert.image = [UIImage systemImageNamed:@"xmark.bin.fill"];
                
                UIAlertAction *doneAction = [UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    
                }];
                
                [alert addAction:doneAction];
                [weakSelf presentViewController:alert animated:YES completion:nil];
            });
        }];
    }];
    
    UIBarButtonItem *cleanupFootagesBarButtonItem = [[UIBarButtonItem alloc] initWithPrimaryAction:cleanupFootagesAction];
    
    _cleanupFootagesBarButtonItem = [cleanupFootagesBarButtonItem retain];
    return [cleanupFootagesBarButtonItem autorelease];
}

- (UICollectionViewDiffableDataSource<NSString *, NSManagedObjectID *> *)makeDataSource __attribute__((objc_direct)) {
    auto cellRegistration = [self makeCellRegistration];
    
    auto dataSource = [[UICollectionViewDiffableDataSource<NSString *, NSManagedObjectID *> alloc] initWithCollectionView:self.collectionView cellProvider:^UICollectionViewCell * _Nullable(UICollectionView * _Nonnull collectionView, NSIndexPath * _Nonnull indexPath, NSManagedObjectID * _Nonnull itemIdentifier) {
        return [collectionView dequeueConfiguredReusableCellWithRegistration:cellRegistration forIndexPath:indexPath item:itemIdentifier];
    }];
    
    return [dataSource autorelease];
}

- (UICollectionViewCellRegistration *)makeCellRegistration __attribute__((objc_direct)) {
    __block id weakRef;
    objc_storeWeak(&weakRef, self);
    
    return [UICollectionViewCellRegistration registrationWithCellClass:UICollectionViewListCell.class configurationHandler:^(__kindof UICollectionViewListCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, NSManagedObjectID * _Nonnull item) {
        id _Nullable loaded = objc_loadWeak(&weakRef);
        if (!loaded) return;
        
        UIListContentConfiguration *contentConfiguration = [cell defaultContentConfiguration];
        contentConfiguration.text = item.URIRepresentation.absoluteString;
        cell.contentConfiguration = contentConfiguration;
    }];
}

- (UICollectionLayoutListSwipeActionsConfigurationProvider)makeTrailingSwipeActionsConfigurationProvider __attribute__((objc_direct)) {
    __weak auto weakSelf = self;
    
    auto provider = ^UISwipeActionsConfiguration * _Nullable(NSIndexPath * _Nonnull indexPath) {
        UIContextualAction *removeAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            [weakSelf.viewModel removeAtIndexPath:indexPath completionHandler:^(NSError * _Nullable error) {
                assert(!error);
            }];
        }];
        
        removeAction.image = [UIImage systemImageNamed:@"trash"];
        
        UISwipeActionsConfiguration *configiration = [UISwipeActionsConfiguration configurationWithActions:@[removeAction]];
        configiration.performsFirstActionWithFullSwipe = NO;
        
        return configiration;
    };
    
    return [[provider copy] autorelease];
}

- (void)showEditorViewControllerWithVideoProject:(SVVideoProject *)videoProject __attribute__((objc_direct)) {
    if (UIApplication.sharedApplication.supportsMultipleScenes) {
        NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:kEditorWindowSceneUserActivityType];
        userActivity.userInfo = @{EditorWindowUserActivityVideoProjectURIRepresentationKey: videoProject.objectID.URIRepresentation};
        
        UISceneSessionActivationRequest *request = [UISceneSessionActivationRequest requestWithRole:UIWindowSceneSessionRoleApplication];
        request.userActivity = userActivity;
        [userActivity release];
        [UIApplication.sharedApplication activateSceneSessionForRequest:request errorHandler:^(NSError * _Nonnull error) {
            NSLog(@"%@", error);
        }];
    } else {
        EditorViewController *editorViewController = [[EditorViewController alloc] initWithVideoProject:videoProject];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:editorViewController];
        [editorViewController release];
        navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
        navigationController.navigationBar.prefersLargeTitles = YES;
        [self presentViewController:navigationController animated:YES completion:nil];
        [navigationController release];
    }
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    __weak auto weakSelf = self;
    
    [self.viewModel videoProjectAtIndexPath:indexPath completionHandler:^(SVVideoProject * _Nullable videoProject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf showEditorViewControllerWithVideoProject:videoProject];
        });
    }];
}

#pragma mark - PHPickerViewControllerDelegate

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    if (results.count == 0) return;
    
    __weak auto weakSelf = self;
    
    [self.viewModel createVideoProject:results completionHandler:^(SVVideoProject * _Nullable videoProject, NSError * _Nullable error) {
        assert(!error);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf showEditorViewControllerWithVideoProject:videoProject];
        });
    }];
}

@end
