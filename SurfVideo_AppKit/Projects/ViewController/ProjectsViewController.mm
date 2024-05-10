//
//  ProjectsViewController.mm
//  SurfVideo_AppKit
//
//  Created by Jinwoo Kim on 5/10/24.
//

#import "ProjectsViewController.hpp"
#import "ProjectsCollectionViewLayout.hpp"
#import "ProjectsCollectionViewItem.hpp"
#import "NSViewController+Private.h"
#import "SVNSApplication.hpp"
#import <objc/message.h>
#import <objc/runtime.h>

__attribute__((objc_direct_members))
@interface ProjectsViewController () <NSCollectionViewDelegate>
@property (retain, readonly, nonatomic) NSScrollView *scrollView;
@property (retain, readonly, nonatomic) NSCollectionView *collectionView;
@end

@implementation ProjectsViewController

@synthesize scrollView = _scrollView;
@synthesize collectionView = _collectionView;
@synthesize viewModel = _viewModel;

- (void)dealloc {
    [_collectionView release];
    [_viewModel release];
    [super dealloc];
}

- (void)loadView {
    self.view = self.scrollView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.viewModel initializeWithCompletionHandler:^(NSError * _Nullable error) {
        assert(error == nil);
    }];
}

- (NSScrollView *)scrollView {
    if (auto scrollView = _scrollView) return scrollView;
    
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0., 0., 600., 400.)];
    scrollView.documentView = self.collectionView;
    
    _scrollView = [scrollView retain];
    return [scrollView autorelease];
}

- (NSCollectionView *)collectionView {
    if (auto collectionView = _collectionView) return collectionView;
    
    NSCollectionView *collectionView = [NSCollectionView new];
    
    ProjectsCollectionViewLayout *collectionViewLayout = [ProjectsCollectionViewLayout new];
    collectionView.collectionViewLayout = collectionViewLayout;
    [collectionViewLayout release];
    
    [collectionView registerClass:[ProjectsCollectionViewItem class] forItemWithIdentifier:[ProjectsCollectionViewItem reuseIdentifier]];
    
    collectionView.selectable = YES;
    collectionView.delegate = self;
    
    _collectionView = [collectionView retain];
    return [collectionView autorelease];
}

- (SVProjectsViewModel *)viewModel {
    if (auto viewModel = _viewModel) return viewModel;
    if (!self.isViewLoaded) return nil;
    
    SVProjectsViewModel *viewModel = [[SVProjectsViewModel alloc] initWithDataSource:[self makeDataSource]];
    
    _viewModel = [viewModel retain];
    return [viewModel autorelease];
}

- (NSCollectionViewDiffableDataSource<NSString *, NSManagedObjectID *> *)makeDataSource __attribute__((objc_direct)) {
    NSCollectionViewDiffableDataSource<NSString *, NSManagedObjectID *> *dataSource = [[NSCollectionViewDiffableDataSource alloc] initWithCollectionView:self.collectionView itemProvider:^NSCollectionViewItem * _Nullable(NSCollectionView * _Nonnull collectionView, NSIndexPath * _Nonnull indexPath, NSManagedObjectID * _Nonnull objectID) {
        ProjectsCollectionViewItem *item = [collectionView makeItemWithIdentifier:[ProjectsCollectionViewItem reuseIdentifier] forIndexPath:indexPath];
        
        return item;
    }];
    
    return [dataSource autorelease];
}


#pragma mark - NSCollectionViewDelegate

- (void)collectionView:(NSCollectionView *)collectionView didSelectItemsAtIndexPaths:(NSSet<NSIndexPath *> *)indexPaths {
    [self.viewModel videoProjectsAtIndexPaths:indexPaths completionHandler:^(NSDictionary<NSIndexPath *,SVVideoProject *> * _Nonnull videoProjects) {
        if (videoProjects.count == 0) return;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            for (SVVideoProject *videoProject in videoProjects.allValues) {
                [SVNSApplication.sharedApplication makeEditorWindowAndMakeKeyWithVideoProject:videoProject];
            }
            
            [collectionView deselectItemsAtIndexPaths:indexPaths];
        });
    }];
}

@end
