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
#import <objc/runtime.h>
#import <memory>

OBJC_EXPORT id objc_loadWeakRetained(id *location) __attribute__((__ns_returns_retained__));

__attribute__((objc_direct_members))
@interface ProjectsViewController () <UICollectionViewDelegate>
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

- (void)commonInit_ProjectsViewController {
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
        
        loaded->_viewModel.get()->createNewVideoProject(^(SVVideoProject * _Nullable videoProject, NSError * _Nullable error) {
            assert(!error);
        });
        
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

- (void)setupCollectionView {
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

- (void)setupViewModel {
    _viewModel = std::make_shared<ProjectsViewModel>([self makeDataSource]);
}

- (UICollectionViewDiffableDataSource<NSString *, NSManagedObjectID *> *)makeDataSource {
    auto cellRegistration = [self makeCellRegistration];
    
    auto dataSource = [[UICollectionViewDiffableDataSource<NSString *, NSManagedObjectID *> alloc] initWithCollectionView:self.collectionView cellProvider:^UICollectionViewCell * _Nullable(UICollectionView * _Nonnull collectionView, NSIndexPath * _Nonnull indexPath, NSManagedObjectID * _Nonnull itemIdentifier) {
        return [collectionView dequeueConfiguredReusableCellWithRegistration:cellRegistration forIndexPath:indexPath item:itemIdentifier];
    }];
    
    return [dataSource autorelease];
}

- (UICollectionViewCellRegistration *)makeCellRegistration {
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

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    _viewModel.get()->videoProjectAtIndexPath(_viewModel, indexPath, ^(SVVideoProject * _Nullable result, NSError * _Nullable error) {
        assert(!error);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (UIApplication.sharedApplication.supportsMultipleScenes) {
                NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:kEditorWindowSceneUserActivityType];
                userActivity.userInfo = @{EditorWindowUserActivityVideoProjectURIRepresentationKey: result.objectID.URIRepresentation};
                
                UISceneSessionActivationRequest *request = [UISceneSessionActivationRequest requestWithRole:UIWindowSceneSessionRoleApplication];
                request.userActivity = userActivity;
                [userActivity release];
                [UIApplication.sharedApplication activateSceneSessionForRequest:request errorHandler:^(NSError * _Nonnull error) {
                    NSLog(@"%@", error);
                }];
            } else {
                EditorViewController *editorViewController = [[EditorViewController alloc] initWithVideoProject:result];
                UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:editorViewController];
                [editorViewController release];
                navigationController.modalPresentationStyle = UIModalPresentationFullScreen;
                navigationController.navigationBar.prefersLargeTitles = YES;
                [self presentViewController:navigationController animated:YES completion:nil];
                [navigationController release];
            }
        });
    });
}

@end
