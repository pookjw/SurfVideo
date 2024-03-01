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
#import "UIAlertController+Private.h"
#import "UIAlertController+SetCustomView.hpp"
#import <objc/message.h>

__attribute__((objc_direct_members))
@interface EditorTrackViewController () <UICollectionViewDelegate, EditorTrackCollectionViewLayoutDelegate>
@property (retain, nonatomic, readonly) UICollectionView *collectionView;
@property (retain, nonatomic, readonly) UICollectionViewCellRegistration *videoTrackSegmentCellRegistration;
@property (retain, nonatomic, readonly) UICollectionViewCellRegistration *audioTrackSegmentCellRegistration;
@property (retain, nonatomic, readonly) UICollectionViewCellRegistration *captionCellRegistration;
@property (retain, nonatomic, readonly) UIPinchGestureRecognizer *collectionViewPinchGestureRecognizer;
@property (retain, nonatomic, readonly) EditorTrackViewModel *viewModel;
@property (assign, nonatomic) CGFloat bak_pixelPerSecond;
@end

@implementation EditorTrackViewController
@synthesize collectionView = _collectionView;
@synthesize videoTrackSegmentCellRegistration = _videoTrackSegmentCellRegistration;
@synthesize audioTrackSegmentCellRegistration = _audioTrackSegmentCellRegistration;
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
    [_audioTrackSegmentCellRegistration release];
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
    
    EditorTrackCollectionViewLayout *collectionViewLayout = [EditorTrackCollectionViewLayout new];
    collectionViewLayout.delegate = self;
    
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

- (UICollectionViewCellRegistration *)audioTrackSegmentCellRegistration {
    if (auto audioTrackSegmentCellRegistration = _audioTrackSegmentCellRegistration) return audioTrackSegmentCellRegistration;
    
    UICollectionViewCellRegistration *audioTrackSegmentCellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:UICollectionViewListCell.class configurationHandler:^(__kindof UICollectionViewListCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, EditorTrackItemModel * _Nonnull itemModel) {
        UIListContentConfiguration *contentConfiguration = cell.defaultContentConfiguration;
        contentConfiguration.text = indexPath.description;
        
        UIBackgroundConfiguration *backgroundConfiguration = [cell defaultBackgroundConfiguration];
        backgroundConfiguration.backgroundColor = [UIColor.systemPinkColor colorWithAlphaComponent:0.2f];
        
        cell.contentConfiguration = contentConfiguration;
        cell.backgroundConfiguration = backgroundConfiguration;
    }];
    
    _audioTrackSegmentCellRegistration = [audioTrackSegmentCellRegistration retain];
    return audioTrackSegmentCellRegistration;
}

- (UICollectionViewCellRegistration *)captionCellRegistration {
    if (auto captionCellRegistration = _captionCellRegistration) return captionCellRegistration;
    
    UICollectionViewCellRegistration *captionCellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:UICollectionViewListCell.class configurationHandler:^(__kindof UICollectionViewListCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, EditorTrackItemModel * _Nonnull itemModel) {
        UIListContentConfiguration *contentConfiguration = cell.defaultContentConfiguration;
        contentConfiguration.text = static_cast<EditorRenderCaption *>(itemModel.userInfo[EditorTrackItemModelRenderCaptionKey]).attributedString.string;
        
        UIBackgroundConfiguration *backgroundConfiguration = [cell defaultBackgroundConfiguration];
        backgroundConfiguration.backgroundColor = [UIColor.systemCyanColor colorWithAlphaComponent:0.2f];
        
        cell.contentConfiguration = contentConfiguration;
        cell.backgroundConfiguration = backgroundConfiguration;
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
    UICollectionViewCellRegistration *videoTrackSegmentCellRegistration = self.videoTrackSegmentCellRegistration;
    UICollectionViewCellRegistration *audioTrackSegmentCellRegistration = self.audioTrackSegmentCellRegistration;
    UICollectionViewCellRegistration *captionCellRegistration = self.captionCellRegistration;
    
    auto dataSource = [[UICollectionViewDiffableDataSource<EditorTrackSectionModel *, EditorTrackItemModel *> alloc] initWithCollectionView:self.collectionView cellProvider:^UICollectionViewCell * _Nullable(UICollectionView * _Nonnull collectionView, NSIndexPath * _Nonnull indexPath, EditorTrackItemModel * _Nonnull itemIdentifier) {
        switch (itemIdentifier.type) {
            case EditorTrackItemModelTypeVideoTrackSegment:
                return [collectionView dequeueConfiguredReusableCellWithRegistration:videoTrackSegmentCellRegistration forIndexPath:indexPath item:itemIdentifier];
            case EditorTrackItemModelTypeAudioTrackSegment:
                return [collectionView dequeueConfiguredReusableCellWithRegistration:audioTrackSegmentCellRegistration forIndexPath:indexPath item:itemIdentifier];
            case EditorTrackItemModelTypeCaption:
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
}

- (void)presentEditingCaptionAlertControllerWithItemModel:(EditorTrackItemModel *)itemModel __attribute__((objc_direct)) {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Test" message:nil preferredStyle:UIAlertControllerStyleAlert];
    alertController.image = [UIImage systemImageNamed:@"pencil"];
    
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectNull];
    textView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.2f];
    textView.textColor = UIColor.whiteColor;
    textView.layer.cornerRadius = 8.f;
    textView.attributedText = static_cast<EditorRenderCaption *>(itemModel.userInfo[EditorTrackItemModelRenderCaptionKey]).attributedString;
    [alertController sv_setContentView:textView];
    [textView release];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    EditorTrackViewModel *viewModel = self.viewModel;
    UIAlertAction *editCaptionAction = [UIAlertAction actionWithTitle:@"Edit Caption" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [viewModel editCaptionWithItemModel:itemModel attributedString:textView.attributedText completionHandler:nil];
    }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:editCaptionAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (UIMenu *)trackSegmentMenuWithItemModel:(EditorTrackItemModel *)itemModel suggestedActions:(NSArray<UIMenuElement *> *)suggestedActions __attribute__((objc_direct)) {
    EditorTrackViewModel *viewModel = self.viewModel;
    
    UIAction *deleteAction = [UIAction actionWithTitle:@"Delete" image:[UIImage systemImageNamed:@"trash"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [viewModel removeTrackSegmentWithItemModel:itemModel completionHandler:^(NSError * _Nullable error) {
            assert(!error);
        }];
    }];
    deleteAction.attributes = UIMenuElementAttributesDestructive;
    
    UIMenu *deleteMenu = [UIMenu menuWithTitle:[NSString string]
                                         image:nil
                                    identifier:nil 
                                       options:UIMenuOptionsDisplayInline
                                      children:@[deleteAction]];
    
    UIMenu *suggestedMenu = [UIMenu menuWithTitle:[NSString string]
                                            image:nil
                                       identifier:nil 
                                          options:UIMenuOptionsDisplayInline
                                         children:suggestedActions];
    
    return [UIMenu menuWithChildren:@[deleteMenu, suggestedMenu]];
}

- (UIMenu *)captionMenuWithItemModel:(EditorTrackItemModel *)itemModel suggestedActions:(NSArray<UIMenuElement *> *)suggestedActions __attribute__((objc_direct)) {
    EditorTrackViewModel *viewModel = self.viewModel;
    EditorRenderCaption *caption = itemModel.userInfo[EditorTrackItemModelRenderCaptionKey];
    CMTime totalDurationTime = viewModel.durationTime;
    CMTime startTime = CMTimeConvertScale(caption.startTime, totalDurationTime.timescale, kCMTimeRoundingMethod_RoundAwayFromZero);
    CMTime endTime = CMTimeConvertScale(caption.endTime, totalDurationTime.timescale, kCMTimeRoundingMethod_RoundAwayFromZero);
    
    __weak auto weakSelf = self;
    
    UIAction *editAction = [UIAction actionWithTitle:@"Edit Text" image:[UIImage systemImageNamed:@"pencil"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf presentEditingCaptionAlertControllerWithItemModel:itemModel];
    }];
    
    //
    
    UISlider *startTimeSlider = [UISlider new];
    UISlider *endTimeSlider = [UISlider new];
    
    startTimeSlider.minimumValue = 0.f;
    startTimeSlider.maximumValue = endTime.value;
    startTimeSlider.value = startTime.value;
    endTimeSlider.minimumValue = startTime.value;
    endTimeSlider.maximumValue = totalDurationTime.value;
    endTimeSlider.value = endTime.value;
    
    UIAction *startTimeValueChangedAction = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        UISlider *startTimeSlider = action.sender;
        endTimeSlider.minimumValue = startTimeSlider.value;
    }];
    
    UIAction *endTimeValueChangedAction = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        UISlider *endTimeSlider = action.sender;
        startTimeSlider.maximumValue = endTimeSlider.value;
    }];
    
    UIAction *startTimeTouchUpAction = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        UISlider *startTimeSlider = action.sender;
        endTimeSlider.minimumValue = startTimeSlider.value;
        
        [viewModel editCaptionWithItemModel:itemModel 
                                  startTime:CMTimeMake(startTimeSlider.value, totalDurationTime.timescale)
                                    endTime:CMTimeMake(endTimeSlider.value, totalDurationTime.timescale)
                          completionHandler:nil];
    }];
    
    UIAction *endTimeTouchUpAction = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        UISlider *endTimeSlider = action.sender;
        startTimeSlider.maximumValue = endTimeSlider.value;
        
        [viewModel editCaptionWithItemModel:itemModel 
                                  startTime:CMTimeMake(startTimeSlider.value, totalDurationTime.timescale)
                                    endTime:CMTimeMake(endTimeSlider.value, totalDurationTime.timescale)
                          completionHandler:nil];
    }];
    
    [startTimeSlider addAction:startTimeValueChangedAction forControlEvents:UIControlEventValueChanged];
    [endTimeSlider addAction:endTimeValueChangedAction forControlEvents:UIControlEventValueChanged];
    [startTimeSlider addAction:startTimeTouchUpAction forControlEvents:UIControlEventTouchUpInside];
    [startTimeSlider addAction:startTimeTouchUpAction forControlEvents:UIControlEventTouchUpOutside];
    [endTimeSlider addAction:endTimeTouchUpAction forControlEvents:UIControlEventTouchUpInside];
    [endTimeSlider addAction:endTimeTouchUpAction forControlEvents:UIControlEventTouchUpOutside];
    
    __kindof UIMenuElement *startTimeSliderMenuElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * {
        return startTimeSlider;
    });
    
    __kindof UIMenuElement *endTimeSliderMenuElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * {
        return endTimeSlider;
    });
    
    [startTimeSlider release];
    [endTimeSlider release];
    
    UIMenu *adjustTimeMenu = [UIMenu menuWithTitle:@"Adjust Time"
                                             image:[UIImage systemImageNamed:@"timer"]
                                        identifier:nil
                                           options:0
                                          children:@[startTimeSliderMenuElement, endTimeSliderMenuElement]];
    
    //
    
    UIAction *deleteAction = [UIAction actionWithTitle:@"Delete" image:[UIImage systemImageNamed:@"trash"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [viewModel removeCaptionWithItemModel:itemModel completionHandler:nil];
    }];
    deleteAction.attributes = UIMenuElementAttributesDestructive;
    
    UIMenu *editMenu = [UIMenu menuWithTitle:[NSString string]
                                         image:nil
                                    identifier:nil 
                                       options:UIMenuOptionsDisplayInline
                                      children:@[
        editAction,
        adjustTimeMenu
    ]];
    
    UIMenu *deleteMenu = [UIMenu menuWithTitle:[NSString string]
                                         image:nil
                                    identifier:nil 
                                       options:UIMenuOptionsDisplayInline
                                      children:@[deleteAction]];
    
    UIMenu *suggestedMenu = [UIMenu menuWithTitle:[NSString string]
                                            image:nil
                                       identifier:nil 
                                          options:UIMenuOptionsDisplayInline
                                         children:suggestedActions];
    
    return [UIMenu menuWithChildren:@[editMenu, deleteMenu, suggestedMenu]];
}


#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

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

- (UIContextMenuConfiguration *)collectionView:(UICollectionView *)collectionView contextMenuConfigurationForItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths point:(CGPoint)point {
    if (indexPaths.count == 0) {
        // TODO: Add Asset
        return nil;
    }
    
    __weak auto weakSelf = self;
    EditorTrackViewModel *viewModel = self.viewModel;
    EditorTrackItemModel *itemModel = [viewModel queue_itemModelAtIndexPath:indexPaths.firstObject];
    
    UIContextMenuConfiguration *configuration = [UIContextMenuConfiguration configurationWithIdentifier:nil
                                                                                        previewProvider:nil
                                                                                         actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
        switch (itemModel.type) {
            case EditorTrackItemModelTypeVideoTrackSegment: {
                return [weakSelf trackSegmentMenuWithItemModel:itemModel suggestedActions:suggestedActions];
            }
            case EditorTrackItemModelTypeAudioTrackSegment: {
                return [weakSelf trackSegmentMenuWithItemModel:itemModel suggestedActions:suggestedActions];
            }
            case EditorTrackItemModelTypeCaption: {
                return [weakSelf captionMenuWithItemModel:itemModel suggestedActions:suggestedActions];
            }
            default:
                return [UIMenu menuWithChildren:suggestedActions];
        }
    }];
    
    return configuration;
}

#pragma mark - EditorTrackCollectionViewLayoutDelegate

- (EditorTrackSectionModel *)editorTrackCollectionViewLayout:(EditorTrackCollectionViewLayout *)collectionViewLayout sectionModelForIndex:(NSInteger)index {
    return [self.viewModel queue_sectionModelAtIndex:index];
}

- (EditorTrackItemModel *)editorTrackCollectionViewLayout:(EditorTrackCollectionViewLayout *)collectionViewLayout itemModelForIndexPath:(NSIndexPath *)indexPath {
    return [self.viewModel queue_itemModelAtIndexPath:indexPath];
}

@end
