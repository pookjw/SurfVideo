//
//  EditorTrackViewController.mm
//  SurfVideo_AppKit
//
//  Created by Jinwoo Kim on 5/11/24.
//

#import "EditorTrackViewController.hpp"
#import "NSView+Private.h"
#import "EditorTrackCollectionViewLayout.hpp"
#import "EditorTrackVideoTrackSegmentCollectionViewItem.hpp"
#import "SVCollectionView.hpp"
#import <SurfVideoCore/EditorTrackViewModel.hpp>
#import <objc/message.h>

__attribute__((objc_direct_members))
@interface EditorTrackViewController () <EditorTrackCollectionViewLayoutDelegate>
@property (retain, readonly, nonatomic) NSScrollView *scrollView;
@property (retain, readonly, nonatomic) SVCollectionView *collectionView;
@property (retain, readonly, nonatomic) EditorTrackViewModel *viewModel;
@end

@implementation EditorTrackViewController

@synthesize scrollView = _scrollView;
@synthesize collectionView = _collectionView;

- (instancetype)initWithEditorService:(SVEditorService *)editorService {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _viewModel = [[EditorTrackViewModel alloc] initWithEditorService:editorService dataSource:[self makeDataSource]];
    }
    
    return self;
}

- (void)dealloc {
    [_scrollView release];
    [_collectionView release];
    [_viewModel release];
    [super dealloc];
}

- (void)updateCurrentTime:(CMTime)currentTime {
    NSScrollView *scrollView = self.scrollView;
    NSClipView *clipView = scrollView.contentView;
    NSCollectionView *collectionView = self.collectionView;
    
    EditorTrackCollectionViewLayout *collectionViewLayout = (EditorTrackCollectionViewLayout *)collectionView.collectionViewLayout;
    
    CGFloat contentOffsetX = [collectionViewLayout contentOffsetXFromTime:currentTime];
    
    // TODO: 더 좋은 방법이 없나?
    [NSNotificationCenter.defaultCenter removeObserver:self name:NSViewBoundsDidChangeNotification object:clipView];
    
//    [clipView setBoundsOrigin:NSMakePoint(contentOffsetX, clipView.bounds.origin.y)];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(clipViewBoundsDidChange:)
                                               name:NSViewBoundsDidChangeNotification
                                             object:clipView];
}

- (void)loadView {
    self.view = self.scrollView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addObservers];
}

- (NSScrollView *)scrollView {
    if (auto scrollView = _scrollView) return scrollView;
    
    // TODO: NSRulerView
    NSScrollView *scrollView = [NSScrollView new];
    scrollView.documentView = self.collectionView;
    scrollView.hasHorizontalScroller = YES;
    NSLog(@"%@", scrollView.horizontalScroller);
    scrollView.horizontalScroller.hidden = YES;
    scrollView.contentView.postsBoundsChangedNotifications = YES;
    
    _scrollView = [scrollView retain];
    return [scrollView autorelease];
}

- (SVCollectionView *)collectionView {
    if (auto collectionView = _collectionView) return collectionView;
    
    SVCollectionView *collectionView = [SVCollectionView new];
    
    EditorTrackCollectionViewLayout *collectionViewLayout = [EditorTrackCollectionViewLayout new];
    collectionViewLayout.delegate = self;
    collectionView.collectionViewLayout = collectionViewLayout;
    [collectionViewLayout release];
    
    [collectionView registerClass:[EditorTrackVideoTrackSegmentCollectionViewItem class] forItemWithIdentifier:[EditorTrackVideoTrackSegmentCollectionViewItem reuseIdentifier]];
    
    _collectionView = [collectionView retain];
    return [collectionView autorelease];
}

- (NSCollectionViewDiffableDataSource<EditorTrackSectionModel *, EditorTrackItemModel *> *)makeDataSource __attribute__((objc_direct)) {
    __weak auto weakSelf = self;
    
    NSCollectionViewDiffableDataSource<EditorTrackSectionModel *, EditorTrackItemModel *> *dataSource = [[NSCollectionViewDiffableDataSource alloc] initWithCollectionView:self.collectionView itemProvider:^NSCollectionViewItem * _Nullable(NSCollectionView * _Nonnull collectionView, NSIndexPath * _Nonnull indexPath, EditorTrackItemModel * _Nonnull itemIdentifier) {
        EditorTrackViewModel *viewModel = weakSelf.viewModel;
        if (viewModel == nil) return nil;
        EditorTrackItemModel *itemModel = [viewModel queue_itemModelAtIndexPath:indexPath];
        if (itemModel == nil) return nil;
        
        EditorTrackItemModelType type = itemModel.type;
        
        if (type == EditorTrackItemModelTypeVideoTrackSegment) {
            EditorTrackVideoTrackSegmentCollectionViewItem *item = [collectionView makeItemWithIdentifier:[EditorTrackVideoTrackSegmentCollectionViewItem reuseIdentifier] forIndexPath:indexPath];
            return item;
        } else if (type == EditorTrackItemModelTypeAudioTrackSegment) {
            abort();
        } else if (type == EditorTrackItemModelTypeCaption) {
            abort();
        } else {
            abort();
        }
    }];
    
    return [dataSource autorelease];
}

- (void)addObservers __attribute__((objc_direct)) {
    NSScrollView *scrollView = self.scrollView;
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(clipViewBoundsDidChange:)
                                               name:NSViewBoundsDidChangeNotification
                                             object:scrollView.contentView];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(willScrollViewStartLiveScroll:)
                                               name:NSScrollViewWillStartLiveScrollNotification
                                             object:scrollView];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didScrollViewLiveScroll:)
                                               name:NSScrollViewDidLiveScrollNotification
                                             object:scrollView];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(didScrollViewEndLiveScroll:)
                                               name:NSScrollViewDidEndLiveScrollNotification
                                             object:scrollView];
}

- (void)clipViewBoundsDidChange:(NSNotification *)notification {
    auto delegate = self.delegate;
    if (delegate == nil) return;
    
    NSClipView *clipView = notification.object;;
    NSCollectionView *collectionView = self.collectionView;
    
    CMTime time = [(EditorTrackCollectionViewLayout *)collectionView.collectionViewLayout timeFromContentOffsetX:clipView.bounds.origin.x];
    
    [delegate editorTrackViewController:self scrollingWithCurrentTime:time];
}

- (void)willScrollViewStartLiveScroll:(NSNotification *)notification {
    auto delegate = self.delegate;
    if (delegate == nil) return;
    
    NSScrollView *scrollView = notification.object;
    NSClipView *clipView = scrollView.contentView;
    NSCollectionView *collectionView = self.collectionView;
    
    CMTime time = [(EditorTrackCollectionViewLayout *)collectionView.collectionViewLayout timeFromContentOffsetX:clipView.bounds.origin.x];
    
    [delegate editorTrackViewController:self willBeginScrollingWithCurrentTime:time];
}

- (void)didScrollViewLiveScroll:(NSNotification *)notification {
    auto delegate = self.delegate;
    if (delegate == nil) return;
    
    NSScrollView *scrollView = notification.object;
    NSClipView *clipView = scrollView.contentView;
    NSCollectionView *collectionView = self.collectionView;
    
    CMTime time = [(EditorTrackCollectionViewLayout *)collectionView.collectionViewLayout timeFromContentOffsetX:clipView.bounds.origin.x];
    
    [delegate editorTrackViewController:self scrollingWithCurrentTime:time];
}

- (void)didScrollViewEndLiveScroll:(NSNotification *)notification {
    auto delegate = self.delegate;
    if (delegate == nil) return;
    
    NSScrollView *scrollView = notification.object;
    NSClipView *clipView = scrollView.contentView;
    NSCollectionView *collectionView = self.collectionView;
    
    CMTime time = [(EditorTrackCollectionViewLayout *)collectionView.collectionViewLayout timeFromContentOffsetX:clipView.bounds.origin.x];
    
    [delegate editorTrackViewController:self didEndScrollingWithCurrentTime:time];
}


#pragma mark - EditorTrackCollectionViewLayoutDelegate

- (EditorTrackItemModel * _Nullable)editorTrackCollectionViewLayout:(nonnull EditorTrackCollectionViewLayout *)collectionViewLayout itemModelForIndexPath:(nonnull NSIndexPath *)indexPath { 
    return [self.viewModel queue_itemModelAtIndexPath:indexPath];
}

- (EditorTrackSectionModel * _Nullable)editorTrackCollectionViewLayout:(nonnull EditorTrackCollectionViewLayout *)collectionViewLayout sectionModelForIndex:(NSInteger)index { 
    return [self.viewModel queue_sectionModelAtIndex:index];
}

@end
