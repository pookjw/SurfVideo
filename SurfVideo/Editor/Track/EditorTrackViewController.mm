//
//  EditorTrackViewController.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/13/23.
//

#import "EditorTrackViewController.hpp"
#import "EditorTrackViewModel.hpp"

__attribute__((objc_direct_members))
@interface EditorTrackViewController () <UICollectionViewDelegate>
@property (retain, nonatomic, readonly) UICollectionView *collectionView;
@property (assign, nonatomic) std::shared_ptr<EditorTrackViewModel> viewModel;
@end

@implementation EditorTrackViewController
@synthesize collectionView = _collectionView;

- (instancetype)initWithEditorViewModel:(std::shared_ptr<EditorViewModel>)editorViewModel {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _viewModel = std::make_shared<EditorTrackViewModel>(editorViewModel, [self makeDataSource]);
    }
    
    return self;
}

- (void)dealloc {
    [_collectionView release];
    [super dealloc];
}

- (void)updateComposition:(AVComposition *)composition {
    _viewModel.get()->updateComposition(_viewModel, composition, nil);
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
    if (_collectionView) return _collectionView;
    
    UICollectionLayoutListConfiguration *configuration = [[UICollectionLayoutListConfiguration alloc] initWithAppearance:UICollectionLayoutListAppearanceInsetGrouped];
    configuration.trailingSwipeActionsConfigurationProvider = [self makeTrailingSwipeActionsConfigurationProvider];
    UICollectionViewCompositionalLayout *collectionViewLayout = [UICollectionViewCompositionalLayout layoutWithListConfiguration:configuration];
    [configuration release];
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectNull collectionViewLayout:collectionViewLayout];
    collectionView.delegate = self;
    
    [_collectionView release];
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
    return [UICollectionViewCellRegistration registrationWithCellClass:UICollectionViewListCell.class configurationHandler:^(__kindof UICollectionViewListCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, EditorTrackItemModel * _Nonnull item) {
        UIListContentConfiguration *contentConfiguration = [cell defaultContentConfiguration];
        contentConfiguration.text = [NSString stringWithFormat:@"%@", item.userInfo[EditorTrackItemModelCompositionTrackSegmentKey]];
        contentConfiguration.textProperties.numberOfLines = 1;
        cell.contentConfiguration = contentConfiguration;
    }];
}

- (UICollectionLayoutListSwipeActionsConfigurationProvider)makeTrailingSwipeActionsConfigurationProvider __attribute__((objc_direct)) {
    auto provider = ^UISwipeActionsConfiguration * _Nullable(NSIndexPath * _Nonnull indexPath) {
        UIContextualAction *removeAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            
        }];
        
        removeAction.image = [UIImage systemImageNamed:@"trash"];
        
        UISwipeActionsConfiguration *configiration = [UISwipeActionsConfiguration configurationWithActions:@[removeAction]];
        configiration.performsFirstActionWithFullSwipe = NO;
        
        return configiration;
    };
    
    return [[provider copy] autorelease];
}


#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

@end
