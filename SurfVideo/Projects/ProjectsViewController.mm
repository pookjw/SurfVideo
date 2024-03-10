//
//  ProjectsViewController.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import "ProjectsViewController.hpp"
#import "ProjectsViewModel.hpp"
#import "ProjectsCollectionViewLayout.hpp"
#import "ProjectsCollectionContentConfiguration.hpp"
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
@property (retain, readonly, nonatomic) UICollectionViewCellRegistration *cellRegistration;
@property (retain, readonly, nonatomic) ProjectsViewModel *viewModel;
@property (retain, readonly, nonatomic) UIBarButtonItem *addBarButtonItem;
@property (retain, readonly, nonatomic) UIBarButtonItem *cleanupFootagesBarButtonItem;
@end

@implementation ProjectsViewController

@synthesize collectionView = _collectionView;
@synthesize cellRegistration = _cellRegistration;
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
    [_cellRegistration release];
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
    
    ProjectsCollectionViewLayout *collectionViewLayout = [ProjectsCollectionViewLayout new];
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:collectionViewLayout];
    [collectionViewLayout release];
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
    
    [self.viewModel videoProjectsAtIndexPaths:[NSSet setWithObject:indexPath] completionHandler:^(NSDictionary<NSIndexPath *, SVVideoProject *> * _Nonnull videoProjects) {
        SVVideoProject * _Nullable videoProject = videoProjects[indexPath];
        
        if (videoProject) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf showEditorViewControllerWithVideoProject:videoProject];
            });
        }
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
        assert(!error);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf showEditorViewControllerWithVideoProject:videoProject];
        });
    }];
}

@end
