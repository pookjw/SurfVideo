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
#import <PhotosUI/PhotosUI.h>
#import <objc/runtime.h>
#import <ranges>

OBJC_EXPORT id objc_loadWeakRetained(id *location) __attribute__((__ns_returns_retained__));

__attribute__((objc_direct_members))
@interface ProjectsViewController () <UICollectionViewDelegate, PHPickerViewControllerDelegate>
@property (retain) UICollectionView *collectionView;
@property (assign, nonatomic) std::shared_ptr<ProjectsViewModel> viewModel;
@end

@implementation ProjectsViewController

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
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupCollectionView];
    [self setupViewModel];
    
    _viewModel.get()->initialize(_viewModel, ^(NSError * _Nullable error) {
        assert(!error);
    });
}

- (void)commonInit_ProjectsViewController __attribute__((objc_direct)) {
    UITabBarItem *tabBarItem = self.tabBarItem;
    tabBarItem.title = @"Projects";
    tabBarItem.image = [UIImage systemImageNamed:@"list.bullet"];
    
    //
    
    UINavigationItem *navigationItem = self.navigationItem;
    navigationItem.title = @"Projects";
    navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    
    auto trailingItemGroups = static_cast<NSMutableArray<UIBarButtonItemGroup *> *>([navigationItem.trailingItemGroups mutableCopy]);
    
    id weakRef = nil;
    objc_storeWeak(&weakRef, self);
    
    UIAction *addAction = [UIAction actionWithTitle:[NSString string] image:[UIImage systemImageNamed:@"plus"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        auto loaded = static_cast<ProjectsViewController * _Nullable>(objc_loadWeakRetained(const_cast<id *>(&weakRef)));
        if (!loaded) return;
        
        PHPickerConfiguration *configuration = [[PHPickerConfiguration alloc] initWithPhotoLibrary:[PHPhotoLibrary sharedPhotoLibrary]];
        configuration.selectionLimit = 0;
        configuration.filter = [PHPickerFilter anyFilterMatchingSubfilters:@[PHPickerFilter.videosFilter]];
        configuration.sv_onlyReturnsIdentifiers = YES;
        
        PHPickerViewController *pickerViewController = [[PHPickerViewController alloc] initWithConfiguration:configuration];
        [configuration release];
        pickerViewController.delegate = loaded;
        
        [loaded presentViewController:pickerViewController animated:YES completion:nil];
        [pickerViewController release];
        
        [loaded release];
    }];
    UIBarButtonItem *addBarButtonItem = [[UIBarButtonItem alloc] initWithPrimaryAction:addAction];
    UIBarButtonItemGroup *trailingItemGroup = [[UIBarButtonItemGroup alloc] initWithBarButtonItems:@[addBarButtonItem] representativeItem:nil];
    [addBarButtonItem release];
    [trailingItemGroups addObject:trailingItemGroup];
    [trailingItemGroup release];
    navigationItem.trailingItemGroups = trailingItemGroups;
    [trailingItemGroups release];
}

- (void)setupCollectionView __attribute__((objc_direct)) {
    UICollectionLayoutListConfiguration *configuration = [[UICollectionLayoutListConfiguration alloc] initWithAppearance:UICollectionLayoutListAppearanceInsetGrouped];
    UICollectionViewCompositionalLayout *collectionViewLayout = [UICollectionViewCompositionalLayout layoutWithListConfiguration:configuration];
    [configuration release];
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:collectionViewLayout];
    collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    collectionView.delegate = self;
    
    [self.view addSubview:collectionView];
    self.collectionView = collectionView;
    [collectionView release];
}

- (void)setupViewModel __attribute__((objc_direct)) {
    _viewModel = std::make_shared<ProjectsViewModel>([self makeDataSource]);
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
    
    id weakRef = nil;
    objc_storeWeak(&weakRef, self);
    
    _viewModel.get()->videoProjectAtIndexPath(_viewModel, indexPath, ^(SVVideoProject * _Nullable videoProject, NSError * _Nullable error) {
        assert(!error);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            auto loaded = static_cast<ProjectsViewController * _Nullable>(objc_loadWeakRetained(const_cast<id *>(&weakRef)));
            if (!loaded) return;
            
            [loaded showEditorViewControllerWithVideoProject:videoProject];
            [loaded release];
        });
    });
}

#pragma mark - PHPickerViewControllerDelegate

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    if (results.count == 0) return;
    
    id weakRef = nil;
    objc_storeWeak(&weakRef, self);
    
    _viewModel.get()->createNewVideoProject(results, ^(SVVideoProject * _Nullable videoProject, NSError * _Nullable error) {
        assert(!error);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            auto loaded = static_cast<ProjectsViewController * _Nullable>(objc_loadWeakRetained(const_cast<id *>(&weakRef)));
            if (!loaded) return;
            
            [loaded showEditorViewControllerWithVideoProject:videoProject];
            [loaded release];
        });
    });
}

@end
