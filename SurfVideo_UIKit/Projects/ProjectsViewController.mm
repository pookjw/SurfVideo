//
//  ProjectsViewController.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import "ProjectsViewController.hpp"
#import <SurfVideoCore/SVProjectsViewModel.hpp>
#import "ProjectsCollectionViewLayout.hpp"
#import "ProjectsCollectionContentConfiguration.hpp"
#import "EditorViewController.hpp"
#import <SurfVideoCore/constants.hpp>
#import "UIApplication+mrui_requestSceneWrapper.hpp"
#import <SurfVideoCore/PHPickerConfiguration+onlyReturnsIdentifiers.hpp>
#import "UIAlertController+Private.h"
#import "ImmersiveEffectPickerViewController.hpp"
#import <PhotosUI/PhotosUI.h>
#import <objc/runtime.h>
#import <ranges>
#import <TargetConditionals.h>

__attribute__((objc_direct_members))
@interface ProjectsViewController () <UICollectionViewDelegate, PHPickerViewControllerDelegate>
@property (retain, readonly, nonatomic) UICollectionView *collectionView;
@property (retain, readonly, nonatomic) UICollectionViewCellRegistration *cellRegistration;
@property (retain, readonly, nonatomic) SVProjectsViewModel *viewModel;
@property (retain, readonly, nonatomic) UIBarButtonItem *addBarButtonItem;
#if TARGET_OS_VISION
@property (retain, readonly, nonatomic) UIBarButtonItem *effectsBarButtonItem;
#endif
@end

@implementation ProjectsViewController

@synthesize collectionView = _collectionView;
@synthesize cellRegistration = _cellRegistration;
@synthesize viewModel = _viewModel;
@synthesize addBarButtonItem = _addBarButtonItem;
#if TARGET_OS_VISION
@synthesize effectsBarButtonItem = _effectsBarButtonItem;
#endif

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
    [_cellRegistration release];
    [_viewModel release];
    [_addBarButtonItem release];
#if TARGET_OS_VISION
    [_effectsBarButtonItem release];
#endif
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
    navigationItem.rightBarButtonItems = @[
#if TARGET_OS_VISION
        self.effectsBarButtonItem,
#endif
        self.addBarButtonItem
    ];
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
    
    ProjectsCollectionViewLayout *collectionViewLayout = [ProjectsCollectionViewLayout new];
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:collectionViewLayout];
    [collectionViewLayout release];
    collectionView.delegate = self;
    
    _collectionView = [collectionView retain];
    
    return [collectionView autorelease];
}

- (SVProjectsViewModel *)viewModel {
    if (auto viewModel = _viewModel) return viewModel;
    
    SVProjectsViewModel *viewModel = [[SVProjectsViewModel alloc] initWithDataSource:[self makeDataSource]];
    
    _viewModel = [viewModel retain];
    return [viewModel autorelease];
}

- (UIBarButtonItem *)addBarButtonItem {
    if (auto addBarButtonItem = _addBarButtonItem) return addBarButtonItem;
    
    __weak auto weakSelf = self;
    
    UIAction *addAction = [UIAction actionWithTitle:[NSString string] image:[UIImage systemImageNamed:@"plus"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        PHAuthorizationStatus authorizationStatus = [PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite];
        if (authorizationStatus == PHAuthorizationStatusRestricted || authorizationStatus == PHAuthorizationStatusDenied) {
            [weakSelf presentNoPhotoLibraryAuthorizationAlert];
            return;
        }
        
        PHPickerConfiguration *configuration = [[PHPickerConfiguration alloc] initWithPhotoLibrary:[PHPhotoLibrary sharedPhotoLibrary]];
        configuration.filter = [PHPickerFilter videosFilter];
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

#if TARGET_OS_VISION
- (UIBarButtonItem *)effectsBarButtonItem {
    if (auto effectsBarButtonItem = _effectsBarButtonItem) return effectsBarButtonItem;
    
    __weak auto weakSelf = self;
    
    UIAction *action = [UIAction actionWithTitle:[NSString string] image:[UIImage systemImageNamed:@"visionpro"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        ImmersiveEffectPickerViewController *viewController = [ImmersiveEffectPickerViewController new];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
        [viewController release];
        [weakSelf presentViewController:navigationController animated:YES completion:nil];
        [navigationController release];
    }];
    
    UIBarButtonItem *effectsBarButtonItem = [[UIBarButtonItem alloc] initWithPrimaryAction:action];
    
    _effectsBarButtonItem = [effectsBarButtonItem retain];
    return [effectsBarButtonItem autorelease];
}
#endif

- (UICollectionViewDiffableDataSource<NSString *, NSManagedObjectID *> *)makeDataSource __attribute__((objc_direct)) {
    auto cellRegistration = self.cellRegistration;
    
    auto dataSource = [[UICollectionViewDiffableDataSource<NSString *, NSManagedObjectID *> alloc] initWithCollectionView:self.collectionView cellProvider:^UICollectionViewCell * _Nullable(UICollectionView * _Nonnull collectionView, NSIndexPath * _Nonnull indexPath, NSManagedObjectID * _Nonnull itemIdentifier) {
        return [collectionView dequeueConfiguredReusableCellWithRegistration:cellRegistration forIndexPath:indexPath item:itemIdentifier];
    }];
    
    return [dataSource autorelease];
}

- (UICollectionViewCellRegistration *)cellRegistration {
    if (auto cellRegistration = _cellRegistration) return cellRegistration;
    
    UICollectionViewCellRegistration *cellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:UICollectionViewCell.class configurationHandler:^(__kindof UICollectionViewCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, NSManagedObjectID * _Nonnull item) {
        ProjectsCollectionContentConfiguration *contentConfiguration = [[ProjectsCollectionContentConfiguration alloc] initWithVideoProjectObjectID:item];
        cell.contentConfiguration = contentConfiguration;
        [contentConfiguration release];
    }];
    
    _cellRegistration = [cellRegistration retain];
    return [cellRegistration autorelease];
}

- (void)showEditorViewControllerWithVideoProject:(SVVideoProject *)videoProject __attribute__((objc_direct)) {
    if (UIApplication.sharedApplication.supportsMultipleScenes) {
        NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:EditorSceneUserActivityType];
        userActivity.userInfo = @{EditorSceneUserActivityVideoProjectURIRepresentationKey: videoProject.objectID.URIRepresentation};
        
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

- (void)presentNoPhotoLibraryAuthorizationAlert __attribute__((objc_direct)) {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Authorization needed"
                                                                             message:@"Authorization to access the photos library is needed."
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    alertController.image = [UIImage systemImageNamed:@"exclamationmark.triangle.fill"];
    
    __weak auto weakSelf = self;
    UIAlertAction *openSettingsAction = [UIAlertAction actionWithTitle:@"Open Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        
        [weakSelf.view.window.windowScene openURL:url options:nil completionHandler:^(BOOL success) {
            assert(success);
        }];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    [alertController addAction:openSettingsAction];
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}


#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    __weak auto weakSelf = self;
    
    [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelReadWrite handler:^(PHAuthorizationStatus status) {
        if ((status != PHAuthorizationStatusAuthorized) && (status != PHAuthorizationStatusLimited)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf presentNoPhotoLibraryAuthorizationAlert];
            });
            return;
        }
        
        [self.viewModel videoProjectsAtIndexPaths:[NSSet setWithObject:indexPath] completionHandler:^(NSDictionary<NSIndexPath *, SVVideoProject *> * _Nonnull videoProjects) {
            SVVideoProject * _Nullable videoProject = videoProjects[indexPath];
            
            if (videoProject) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf showEditorViewControllerWithVideoProject:videoProject];
                });
            }
        }];
    }];
}

- (UIContextMenuConfiguration *)collectionView:(UICollectionView *)collectionView contextMenuConfigurationForItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths point:(CGPoint)point {
    __weak auto weakSelf = self;
    
    UIContextMenuConfiguration *contextMenuConfiguration = [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:nil actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
        NSMutableArray<UIMenuElement *> *actions = [suggestedActions mutableCopy];
        
        UIAction *openEditorAction = [UIAction actionWithTitle:@"Open Editor" image:[UIImage systemImageNamed:@"macwindow.badge.plus"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            auto retainedSelf = weakSelf;
            if (retainedSelf == nil) return;
            
            [retainedSelf.viewModel videoProjectsAtIndexPaths:[NSSet setWithArray:indexPaths] completionHandler:^(NSDictionary<NSIndexPath *, SVVideoProject *> * _Nonnull videoProjects) {
                NSArray<SVVideoProject *> *values = videoProjects.allValues;
                if (values.count == 0) return;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    auto retainedSelf = weakSelf;
                    if (retainedSelf == nil) return;
                    
                    for (SVVideoProject *videoProject in values) {
                        [retainedSelf showEditorViewControllerWithVideoProject:videoProject];
                    }
                });
            }];
        }];
        
        UIAction *deleteAction = [UIAction actionWithTitle:@"Delete" image:[UIImage systemImageNamed:@"trash"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            auto retainedSelf = weakSelf;
            if (retainedSelf == nil) return;
            
            [retainedSelf.viewModel deleteAtIndexPaths:[NSSet setWithArray:indexPaths] completionHandler:^(NSError * _Nullable error) {
                assert(!error);
            }];
        }];
        
        deleteAction.attributes = UIMenuOptionsDestructive;
        
        [actions addObjectsFromArray:@[openEditorAction, deleteAction]];
        
        UIMenu *menu = [UIMenu menuWithChildren:actions];
        [actions release];
        
        return menu;
    }];
    
    return contextMenuConfiguration;
}

#pragma mark - PHPickerViewControllerDelegate

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    if (results.count == 0) return;
    
    __weak auto weakSelf = self;
    
    [self.viewModel createVideoProject:results completionHandler:^(SVVideoProject * _Nullable videoProject, NSError * _Nullable error) {
        if (error) {
            if (error.domain == SurfVideoErrorDomain && error.code == SurfVideoNoPhotoLibraryAuthorization) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf presentNoPhotoLibraryAuthorizationAlert];
                });
                return;
            }
            
            abort();
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf showEditorViewControllerWithVideoProject:videoProject];
        });
    }];
}

@end
