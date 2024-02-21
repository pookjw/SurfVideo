//
//  EditorTrackViewController.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/13/23.
//

#import "EditorTrackViewController.hpp"
#import "EditorTrackViewModel.hpp"
#import "EditorTrackCollectionViewLayout.hpp"
#import "EditorTrackVideoTrackSegmentContentConfiguration.hpp"

__attribute__((objc_direct_members))
@interface EditorTrackViewController () <UICollectionViewDelegate, EditorTrackCollectionViewLayoutDelegate>
@property (retain, nonatomic, readonly) UICollectionView *collectionView;
@property (retain, nonatomic, readonly) UICollectionViewCellRegistration *videoTrackSegmentCellRegistration;
@property (retain, nonatomic, readonly) UICollectionViewCellRegistration *captionCellRegistration;
@property (retain, nonatomic, readonly) UIPinchGestureRecognizer *collectionViewPinchGestureRecognizer;
@property (retain, nonatomic, readonly) EditorTrackViewModel *viewModel;
@property (assign, nonatomic) CGFloat bak_pixelPerSecond;
@end

@implementation EditorTrackViewController
@synthesize collectionView = _collectionView;
@synthesize videoTrackSegmentCellRegistration = _videoTrackSegmentCellRegistration;
@synthesize captionCellRegistration = _captionCellRegistration;
@synthesize collectionViewPinchGestureRecognizer = _collectionViewPinchGestureRecognizer;

- (instancetype)initWithEditorService:(EditorService *)editorService {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _viewModel = [[EditorTrackViewModel alloc] initWithEditorService:editorService dataSource:[self makeDataSource]];
    }
    
    return self;
}

- (void)dealloc {
    [_collectionView release];
    [_videoTrackSegmentCellRegistration release];
    [_captionCellRegistration release];
    [_collectionViewPinchGestureRecognizer release];
    [_viewModel release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupCollectionView];
}

- (void)setupCollectionView __attribute__((objc_direct)) {
    UICollectionView *collectionView = self.collectionView;
    [collectionView addGestureRecognizer:self.collectionViewPinchGestureRecognizer];
    collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:collectionView];
    
    [NSLayoutConstraint activateConstraints:@[
        [collectionView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)updateCurrentTime:(CMTime)currentTime {
    UICollectionView *collectionView = self.collectionView;
    
    auto collectionViewLayout = static_cast<EditorTrackCollectionViewLayout *>(collectionView.collectionViewLayout);
    
    CGPoint contentOffset = [collectionViewLayout contentOffsetFromTime:currentTime];
    
    [collectionView setContentOffset:contentOffset animated:NO];
}

- (UICollectionView *)collectionView {
    if (auto collectionView = _collectionView) return collectionView;
    
    EditorTrackCollectionViewLayout *collectionViewLayout = [[EditorTrackCollectionViewLayout alloc] initWithDelegate:self];
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectNull collectionViewLayout:collectionViewLayout];
    [collectionViewLayout release];
    collectionView.delegate = self;
    collectionView.allowsMultipleSelection = NO;
    
    _collectionView = [collectionView retain];
    return [collectionView autorelease];
}

- (UICollectionViewCellRegistration *)videoTrackSegmentCellRegistration __attribute__((objc_direct)) {
    if (auto videoTrackSegmentCellRegistration = _videoTrackSegmentCellRegistration) return videoTrackSegmentCellRegistration;
    
    __weak auto weakSelf = self;
    
    UICollectionViewCellRegistration *videoTrackSegmentCellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:UICollectionViewCell.class configurationHandler:^(__kindof UICollectionViewCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, EditorTrackItemModel * _Nonnull itemModel) {
        EditorTrackSectionModel *sectionModel = [weakSelf.viewModel queue_sectionModelAtIndex:indexPath.section];
        
        EditorTrackVideoTrackSegmentContentConfiguration *contentConfiguration = [[EditorTrackVideoTrackSegmentContentConfiguration alloc] initWithSectionModel:sectionModel itemModel:itemModel];
        cell.contentConfiguration = contentConfiguration;
        [contentConfiguration release];
    }];
    
    _videoTrackSegmentCellRegistration = [videoTrackSegmentCellRegistration retain];
    return videoTrackSegmentCellRegistration;
}

- (UICollectionViewCellRegistration *)captionCellRegistration {
    if (auto captionCellRegistration = _captionCellRegistration) return captionCellRegistration;
    
    __weak auto weakSelf = self;
    
    UICollectionViewCellRegistration *captionCellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:UICollectionViewListCell.class configurationHandler:^(__kindof UICollectionViewListCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, EditorTrackItemModel * _Nonnull itemModel) {
        UIListContentConfiguration *contentConfiguration = cell.defaultContentConfiguration;
        contentConfiguration.text = static_cast<EditorRenderCaption *>(itemModel.userInfo[EditorTrackItemModelRenderCaptionKey]).attributedString.string;
        
        cell.contentConfiguration = contentConfiguration;
    }];
    
    _captionCellRegistration = [captionCellRegistration retain];
    return captionCellRegistration;
}

- (UIPinchGestureRecognizer *)collectionViewPinchGestureRecognizer {
    if (auto collectionViewPinchGestureRecognizer = _collectionViewPinchGestureRecognizer) return collectionViewPinchGestureRecognizer;
    
    UIPinchGestureRecognizer *collectionViewPinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(collectionViewPinchGestureRecognizerDidTrigger:)];
    
    _collectionViewPinchGestureRecognizer = [collectionViewPinchGestureRecognizer retain];
    return [collectionViewPinchGestureRecognizer autorelease];
}

- (UICollectionViewDiffableDataSource<EditorTrackSectionModel *, EditorTrackItemModel *> *)makeDataSource __attribute__((objc_direct)) {
    __weak auto weakSelf = self;
    UICollectionViewCellRegistration *videoTrackSegmentCellRegistration = self.videoTrackSegmentCellRegistration;
    UICollectionViewCellRegistration *captionCellRegistration = self.captionCellRegistration;
    
    auto dataSource = [[UICollectionViewDiffableDataSource<EditorTrackSectionModel *, EditorTrackItemModel *> alloc] initWithCollectionView:self.collectionView cellProvider:^UICollectionViewCell * _Nullable(UICollectionView * _Nonnull collectionView, NSIndexPath * _Nonnull indexPath, EditorTrackItemModel * _Nonnull itemIdentifier) {
        EditorTrackSectionModel *sectionModel = [weakSelf.viewModel queue_sectionModelAtIndex:indexPath.section];
        
        switch (sectionModel.type) {
            case EditorTrackSectionModelTypeMainVideoTrack:
                return [collectionView dequeueConfiguredReusableCellWithRegistration:videoTrackSegmentCellRegistration forIndexPath:indexPath item:itemIdentifier];
            case EditorTrackSectionModelTypeCaptionTrack:
                return [collectionView dequeueConfiguredReusableCellWithRegistration:captionCellRegistration forIndexPath:indexPath item:itemIdentifier];
            default:
                return nil;
        }
    }];
    
    return [dataSource autorelease];
}

- (void)collectionViewPinchGestureRecognizerDidTrigger:(UIPinchGestureRecognizer *)sender {
    auto collectionViewLayout = static_cast<EditorTrackCollectionViewLayout *>(self.collectionView.collectionViewLayout);
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            self.bak_pixelPerSecond = collectionViewLayout.pixelPerSecond;
            collectionViewLayout.pixelPerSecond = self.bak_pixelPerSecond * sender.scale;
            break;
        case UIGestureRecognizerStateChanged:
            collectionViewLayout.pixelPerSecond = self.bak_pixelPerSecond * sender.scale;
            break;
        case UIGestureRecognizerStateEnded:
            collectionViewLayout.pixelPerSecond = self.bak_pixelPerSecond * sender.scale;
            break;
        default:
            break;
    }
//    collectionViewLayout.pixelPerSecond = collectionViewLayout.pixelPerSecond * sender.scale;
//    NSLog(@"%f", collectionViewLayout.pixelPerSecond);
}


#pragma mark - UICollectionViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([scrollView isEqual:self.collectionView]) {
        if (!scrollView.isDragging && !scrollView.isDecelerating) return;        
        id<EditorTrackViewControllerDelegate> _delegate = self.delegate;
        if (_delegate == nil) return;
        
        auto collectionViewLayout = static_cast<EditorTrackCollectionViewLayout *>(self.collectionView.collectionViewLayout);
        CMTime currentTime = [collectionViewLayout timeFromContentOffset:scrollView.contentOffset];
        [_delegate editorTrackViewController:self scrollingWithCurrentTime:currentTime];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {  
    if ([scrollView isEqual:self.collectionView]) {       
        id<EditorTrackViewControllerDelegate> _delegate = self.delegate;
        if (_delegate == nil) return;
        
        auto collectionViewLayout = static_cast<EditorTrackCollectionViewLayout *>(self.collectionView.collectionViewLayout);
        CMTime currentTime = [collectionViewLayout timeFromContentOffset:scrollView.contentOffset];
        [_delegate editorTrackViewController:self willBeginScrollingWithCurrentTime:currentTime];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if ([scrollView isEqual:self.collectionView]) {  
        if (decelerate) return;
        id<EditorTrackViewControllerDelegate> _delegate = self.delegate;
        if (_delegate == nil) return;
        
        auto collectionViewLayout = static_cast<EditorTrackCollectionViewLayout *>(self.collectionView.collectionViewLayout);
        CMTime currentTime = [collectionViewLayout timeFromContentOffset:scrollView.contentOffset];
        [_delegate editorTrackViewController:self didEndScrollingWithCurrentTime:currentTime];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if ([scrollView isEqual:self.collectionView]) {  
        id<EditorTrackViewControllerDelegate> _delegate = self.delegate;
        if (_delegate == nil) return;
        
        auto collectionViewLayout = static_cast<EditorTrackCollectionViewLayout *>(self.collectionView);
        CMTime currentTime = [collectionViewLayout timeFromContentOffset:scrollView.contentOffset];
        [_delegate editorTrackViewController:self didEndScrollingWithCurrentTime:currentTime];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

- (UIContextMenuConfiguration *)collectionView:(UICollectionView *)collectionView contextMenuConfigurationForItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths point:(CGPoint)point {
    if (indexPaths.count == 0) {
        // TODO: Add Asset
        return nil;
    }
    
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

- (NSUInteger)editorTrackCollectionViewLayout:(EditorTrackCollectionViewLayout *)collectionViewLayout numberOfItemsForSectionIndex:(NSInteger)index {
    return [self.viewModel queue_numberOfItemsAtSectionIndex:index];
}

- (EditorTrackSectionModel *)editorTrackCollectionViewLayout:(EditorTrackCollectionViewLayout *)collectionViewLayout sectionModelForIndex:(NSInteger)index {
    return [self.viewModel queue_sectionModelAtIndex:index];
}

- (EditorTrackItemModel *)editorTrackCollectionViewLayout:(EditorTrackCollectionViewLayout *)collectionViewLayout itemModelForIndexPath:(NSIndexPath *)indexPath {
    return [self.viewModel queue_itemModelAtIndexPath:indexPath];
}

@end
