//
//  EditorTrackViewController.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/13/23.
//

#import "EditorTrackViewController.hpp"
#import "EditorTrackViewModel.hpp"
#import "EditorTrackCollectionViewLayout.hpp"
#import "EditorTrackMainVideoTrackContentConfiguration.hpp"

__attribute__((objc_direct_members))
@interface EditorTrackViewController () <UICollectionViewDelegate, EditorTrackCollectionViewLayoutDelegate>
@property (retain, nonatomic, readonly) UICollectionView *collectionView;
@property (retain, nonatomic, readonly) EditorTrackViewModel *viewModel;
@end

@implementation EditorTrackViewController
@synthesize collectionView = _collectionView;

- (instancetype)initWithEditorViewModel:(EditorService *)editorViewModel {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _viewModel = [[EditorTrackViewModel alloc] initWithEditorViewModel:editorViewModel dataSource:[self makeDataSource]];
    }
    
    return self;
}

- (void)dealloc {
    [_collectionView release];
    [_viewModel release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupCollectionView];
}

- (void)setupCollectionView __attribute__((objc_direct)) {
    UICollectionView *collectionView = self.collectionView;
    collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:collectionView];
    
    [NSLayoutConstraint activateConstraints:@[
        [collectionView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (UICollectionView *)collectionView {
    if (auto collectionView = _collectionView) return collectionView;
    
    EditorTrackCollectionViewLayout *collectionViewLayout = [EditorTrackCollectionViewLayout new];
    collectionViewLayout.delegate = self;
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectNull collectionViewLayout:collectionViewLayout];
    [collectionViewLayout release];
    collectionView.delegate = self;
    collectionView.allowsMultipleSelection = NO;
    
    _collectionView = [collectionView retain];
    return [collectionView autorelease];
}

- (UICollectionViewDiffableDataSource<EditorTrackSectionModel *, EditorTrackItemModel *> *)makeDataSource __attribute__((objc_direct)) {
    auto cellRegistration = [self makeCellRegistration];
    
    auto dataSource = [[UICollectionViewDiffableDataSource<EditorTrackSectionModel *, EditorTrackItemModel *> alloc] initWithCollectionView:self.collectionView cellProvider:^UICollectionViewCell * _Nullable(UICollectionView * _Nonnull collectionView, NSIndexPath * _Nonnull indexPath, EditorTrackItemModel * _Nonnull itemIdentifier) {
        return [collectionView dequeueConfiguredReusableCellWithRegistration:cellRegistration forIndexPath:indexPath item:itemIdentifier];
    }];
    
    return [dataSource autorelease];
}

- (UICollectionViewCellRegistration *)makeCellRegistration __attribute__((objc_direct)) {
    return [UICollectionViewCellRegistration registrationWithCellClass:UICollectionViewCell.class configurationHandler:^(__kindof UICollectionViewCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, EditorTrackItemModel * _Nonnull item) {
        EditorTrackMainVideoTrackContentConfiguration *contentConfiguration = [[EditorTrackMainVideoTrackContentConfiguration alloc] initWithItemModel:item];
        cell.contentConfiguration = contentConfiguration;
        [contentConfiguration release];
    }];
}


#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

- (UIContextMenuConfiguration *)collectionView:(UICollectionView *)collectionView contextMenuConfigurationForItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths point:(CGPoint)point {
    __weak auto weakSelf = self;
    
    UIContextMenuConfiguration *configuration = [UIContextMenuConfiguration configurationWithIdentifier:nil
                                                                                        previewProvider:nil
                                                                                         actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
        auto actions = static_cast<NSMutableArray<UIMenuElement *> *>([suggestedActions mutableCopy]);
        
        UIAction *deleteAction = [UIAction actionWithTitle:@"Delete" image:[UIImage systemImageNamed:@"trash"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            [weakSelf.viewModel removeAtIndexPath:indexPaths.firstObject completionHandler:nil];
        }];
        deleteAction.attributes = UIMenuElementAttributesDestructive;
        
        [actions addObject:deleteAction];
        
        UIMenu *menu = [UIMenu menuWithChildren:actions];
        [actions release];
        
        return menu;
    }];
    
    return configuration;
}

#pragma mark - EditorTrackCollectionViewLayoutDelegate

- (EditorTrackSectionModel *)editorTrackCollectionViewLayout:(EditorTrackCollectionViewLayout *)collectionViewLayout sectionModelForIndex:(NSInteger)index {
    return [self.viewModel unsafe_sectionModelAtIndex:index];
}

- (EditorTrackItemModel *)editorTrackCollectionViewLayout:(EditorTrackCollectionViewLayout *)collectionViewLayout itemModelForIndexPath:(NSIndexPath *)indexPath {
    return [self.viewModel unsafe_itemModelAtIndexPath:indexPath];
}

@end
