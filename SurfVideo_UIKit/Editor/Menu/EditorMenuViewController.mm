//
//  EditorMenuViewController.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/3/23.
//

#import "EditorMenuViewController.hpp"
#import "UIView+Private.h"
#import "UIAlertController+Private.h"
#import "UIAlertController+SetCustomView.hpp"
#import "EditorMenuViewModel.hpp"
#import "EditorMenuCollectionViewLayout.hpp"
#import "EditorMenuCollectionContentConfiguration.hpp"

#if TARGET_OS_VISION

__attribute__((objc_direct_members))
@interface EditorMenuViewController () <UICollectionViewDelegate, EditorMenuCollectionContentConfigurationDelegate>
@property (retain, readonly, nonatomic) UICollectionView *collectionView;
@property (retain, readonly, nonatomic) UICollectionViewCellRegistration *cellRegistration;
@property (retain, readonly, nonatomic) EditorMenuViewModel *viewModel;
@property (retain, readonly, nonatomic) SVEditorService *editorService;
@end

@implementation EditorMenuViewController

@synthesize collectionView = _collectionView;
@synthesize cellRegistration = _cellRegistration;
@synthesize viewModel = _viewModel;

- (instancetype)initWithEditorService:(SVEditorService *)editorService {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _editorService = [editorService retain];
    }
    
    return self;
}

- (void)dealloc {
    [_collectionView release];
    [_cellRegistration release];
    [_viewModel release];
    [_editorService release];
    [super dealloc];
}

- (void)loadView {
    self.view = self.collectionView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self viewModel];
    [self.view sws_enablePlatter:UIBlurEffectStyleSystemMaterial];
}

- (UICollectionView *)collectionView {
    if (auto collectionView = _collectionView) return collectionView;
    
    EditorMenuCollectionViewLayout *collectionViewLayout = [EditorMenuCollectionViewLayout new];
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectNull collectionViewLayout:collectionViewLayout];
    [collectionViewLayout release];
    
    collectionView.delegate = self;
    
    _collectionView = [collectionView retain];
    return [collectionView autorelease];
}

- (EditorMenuViewModel *)viewModel {
    if (auto viewModel = _viewModel) return viewModel;
    
    EditorMenuViewModel *viewModel = [[EditorMenuViewModel alloc] initWithEditorService:self.editorService dataSource:[self makeDataSource]];
    [viewModel loadDataSourceWithCompletionHandler:nil];
    
    _viewModel = [viewModel retain];
    return [viewModel autorelease];
}

- (UICollectionViewDiffableDataSource<EditorMenuSectionModel *, EditorMenuItemModel *> *)makeDataSource __attribute__((objc_direct)) {
    auto cellRegistration = self.cellRegistration;
    
    auto dataSource = [[UICollectionViewDiffableDataSource<EditorMenuSectionModel *, EditorMenuItemModel *> alloc] initWithCollectionView:self.collectionView cellProvider:^UICollectionViewCell * _Nullable(UICollectionView * _Nonnull collectionView, NSIndexPath * _Nonnull indexPath, id  _Nonnull itemIdentifier) {
        return [collectionView dequeueConfiguredReusableCellWithRegistration:cellRegistration forIndexPath:indexPath item:itemIdentifier];
    }];
    
    return [dataSource autorelease];
}

- (UICollectionViewCellRegistration *)cellRegistration {
    if (auto cellRegistration = _cellRegistration) return cellRegistration;
    
    __weak auto weakSelf = self;
    
    UICollectionViewCellRegistration *cellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:UICollectionViewCell.class configurationHandler:^(__kindof UICollectionViewCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, EditorMenuItemModel * _Nonnull item) {
        EditorMenuCollectionContentConfiguration *contentConfiguration = [[EditorMenuCollectionContentConfiguration alloc] initWithType:item.type];
        contentConfiguration.delegate = weakSelf;
        cell.contentConfiguration = contentConfiguration;
        [contentConfiguration release];
    }];
    
    _cellRegistration = [cellRegistration retain];
    return cellRegistration;
}


#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}


#pragma mark - EditorMenuCollectionContentConfigurationDelegate

- (void)editorMenuCollectionContentConfigurationDidSelectAddCaption:(EditorMenuCollectionContentConfiguration *)contentConfiguration {
    [self.delegate editorMenuViewControllerDidSelectAddCaption:self];
}

- (void)editorMenuCollectionContentConfigurationDidSelectAddVideoClipsWithPhotoPicker:(EditorMenuCollectionContentConfiguration *)contentConfiguration {
    [self.delegate editorMenuViewControllerDidSelectAddVideoClipsWithPhotoPicker:self];
}

- (void)editorMenuCollectionContentConfigurationDidSelectAddVideoClipsWithDocumentBrowser:(EditorMenuCollectionContentConfiguration *)contentConfiguration {
    [self.delegate editorMenuViewControllerDidSelectAddVideoClipsWithDocumentBrowser:self];
}

- (void)editorMenuCollectionContentConfigurationDidSelectAddAudioClipsWithPhotoPicker:(EditorMenuCollectionContentConfiguration *)contentConfiguration {
    [self.delegate editorMenuViewControllerDidSelectAddAudioClipsWithPhotoPicker:self];
}

- (void)editorMenuCollectionContentConfigurationDidSelectAddAudioClipsWithDocumentBrowser:(EditorMenuCollectionContentConfiguration *)contentConfiguration {
    [self.delegate editorMenuViewControllerDidSelectAddAudioClipsWithDocumentBrowser:self];
}

- (void)editorMenuCollectionContentConfigurationDidSelectAddEffect:(EditorMenuCollectionContentConfiguration *)contentConfiguration {
    [self.delegate editorMenuViewControllerDidSelectAddEffect:self];
}

@end

#endif
