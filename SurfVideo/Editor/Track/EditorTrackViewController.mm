//
//  EditorTrackViewController.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/13/23.
//

#import "EditorTrackViewController.hpp"
#import "EditorTrackViewModel.hpp"
#import "EditorTrackCollectionViewLayout.hpp"
#import "EditorTrackAudioTrackSegmentContentConfiguration.hpp"
#import "UIAlertController+Private.h"
#import "UIAlertController+SetCustomView.hpp"
#import "EditorTrackAudioTrackSegmentPreviewViewController.hpp"
#import "UIImagePickerController+Private.h"
#import <objc/message.h>
#import <objc/runtime.h>
#import <TargetConditionals.h>
#import <AVKit/AVKit.h>

__attribute__((objc_direct_members))
@interface EditorTrackViewController () <UICollectionViewDelegate, EditorTrackCollectionViewLayoutDelegate>
#if !TARGET_OS_VISION
@property (class, readonly, nonatomic) void *editVideoViewControllerItemModelAssociationKey;
#endif
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

#if !TARGET_OS_VISION

+ (void *)editVideoViewControllerItemModelAssociationKey {
    static void *key = &key;
    return key;
}

#endif

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
    
    CGFloat contentOffsetX = [collectionViewLayout contentOffsetXFromTime:currentTime];
    CGPoint contentOffset = collectionView.contentOffset;
    contentOffset.x = contentOffsetX;
    
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
    
    UICollectionViewCellRegistration *videoTrackSegmentCellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:UICollectionViewCell.class configurationHandler:^(__kindof UICollectionViewCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, EditorTrackItemModel * _Nonnull itemModel) {
        
    }];
    
    _videoTrackSegmentCellRegistration = [videoTrackSegmentCellRegistration retain];
    return videoTrackSegmentCellRegistration;
}

- (UICollectionViewCellRegistration *)audioTrackSegmentCellRegistration {
    if (auto audioTrackSegmentCellRegistration = _audioTrackSegmentCellRegistration) return audioTrackSegmentCellRegistration;
    
    UICollectionViewCellRegistration *audioTrackSegmentCellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:UICollectionViewCell.class configurationHandler:^(__kindof UICollectionViewCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, EditorTrackItemModel * _Nonnull itemModel) {
        EditorTrackAudioTrackSegmentContentConfiguration *contentConfiguration = [[EditorTrackAudioTrackSegmentContentConfiguration alloc] initWithItemModel:itemModel];
        cell.contentConfiguration = contentConfiguration;
        [contentConfiguration release];
    }];
    
    _audioTrackSegmentCellRegistration = [audioTrackSegmentCellRegistration retain];
    return audioTrackSegmentCellRegistration;
}

- (UICollectionViewCellRegistration *)captionCellRegistration {
    if (auto captionCellRegistration = _captionCellRegistration) return captionCellRegistration;
    
    UICollectionViewCellRegistration *captionCellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:UICollectionViewListCell.class configurationHandler:^(__kindof UICollectionViewListCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, EditorTrackItemModel * _Nonnull itemModel) {
        UIListContentConfiguration *contentConfiguration = cell.defaultContentConfiguration;
        contentConfiguration.text = itemModel.renderCaption.attributedString.string;
        contentConfiguration.image = [UIImage systemImageNamed:@"textformat.size.larger"];
        contentConfiguration.imageProperties.tintColor = contentConfiguration.textProperties.color;
        
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

- (void)presentTrimClipViewControllerWithItemModel:(EditorTrackItemModel *)itemModel __attribute__((objc_direct)) {
#if TARGET_OS_VISION
    AVCompositionTrackSegment *trackSegment = itemModel.compositionTrackSegment;
    AVURLAsset *asset = [AVURLAsset assetWithURL:trackSegment.sourceURL];
    
    AVPlayerViewController *playerViewController = [AVPlayerViewController new];
    
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:asset];
    
    playerItem.reversePlaybackEndTime = trackSegment.timeMapping.source.start;
    playerItem.forwardPlaybackEndTime = CMTimeRangeGetEnd(trackSegment.timeMapping.source);
    
    AVPlayer *player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    [playerItem release];
    
    playerViewController.player = player;
    [player release];
    
    [self presentViewController:playerViewController animated:YES completion:nil];
    
    EditorTrackViewModel *viewModel = self.viewModel;
    [playerViewController beginTrimmingWithCompletionHandler:^(BOOL success) {
        if (success) {
            [viewModel trimVideoClipWithItemModel:itemModel
                                   assetStartTime:playerItem.reversePlaybackEndTime
                                     assetEndTime:playerItem.forwardPlaybackEndTime
                                completionHandler:nil];
        }
        
        [playerViewController dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [playerViewController release];
#else
    assert(UIImagePickerLoadPhotoLibraryIfNecessary());
    
    AVCompositionTrackSegment *trackSegment = itemModel.compositionTrackSegment;
    
    CMTimeMapping timeMapping = trackSegment.timeMapping;
    double startTimeValue = (double)CMTimeConvertScale(timeMapping.source.start, 1000000ULL, kCMTimeRoundingMethod_Default).value / 1000000.;
    double endTimeValue = (double)CMTimeConvertScale(CMTimeRangeGetEnd(timeMapping.source), 1000000ULL, kCMTimeRoundingMethod_Default).value / 1000000.;
    
    NSURL *assetURL = trackSegment.sourceURL;
    
    NSDictionary<NSString *, id> *properties = @{
        UIImagePickerControllerVideoQuality: @(UIImagePickerControllerQualityTypeHigh),
        _UIVideoEditorControllerVideoURL: assetURL
    };
    
    __kindof UIViewController *editVideoViewController = ((id (*)(id, SEL, id))objc_msgSend)([objc_lookUpClass("PLUIEditVideoViewController") alloc], sel_registerName("initWithProperties:"), properties);
    
    ((void (*)(id, SEL, id))objc_msgSend)(editVideoViewController, sel_registerName("setDelegate:"), self);
    objc_setAssociatedObject(editVideoViewController, [EditorTrackViewController editVideoViewControllerItemModelAssociationKey], itemModel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:editVideoViewController];
    
    [editVideoViewController loadViewIfNeeded];
    UIBarButtonItem *trimVideoBarButtonItem = editVideoViewController.navigationItem.rightBarButtonItem;
    trimVideoBarButtonItem.target = self;
    trimVideoBarButtonItem.action = @selector(editVideoViewControllerTrimVideo:);
    
    // PLVideoView *
    __kindof UIView *_videoView = nil;
    object_getInstanceVariable(editVideoViewController, "_videoView", (void **)&_videoView);
    
    [editVideoViewController release];
    
    [self presentViewController:navigationController animated:YES completion:^{
        // UIMovieScrubber *
        __kindof UIControl *_scrubber = nil;
        object_getInstanceVariable(_videoView, "_scrubber", (void **)&_scrubber);
        
        ((void (*)(id, SEL, BOOL))objc_msgSend)(_scrubber, sel_registerName("setEditing:"), YES);
        ((void (*)(id, SEL, double))objc_msgSend)(_scrubber, sel_registerName("setTrimStartValue:"), startTimeValue);
        ((void (*)(id, SEL, double))objc_msgSend)(_scrubber, sel_registerName("setTrimEndValue:"), endTimeValue);
    }];
    
    [navigationController release];
#endif
}

- (void)presentEditingCaptionAlertControllerWithItemModel:(EditorTrackItemModel *)itemModel __attribute__((objc_direct)) {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Edit Caption" message:nil preferredStyle:UIAlertControllerStyleAlert];
    alertController.image = [UIImage systemImageNamed:@"pencil"];
    
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectNull];
    textView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.2f];
    textView.textColor = UIColor.whiteColor;
    textView.layer.cornerRadius = 8.f;
    textView.attributedText = itemModel.renderCaption.attributedString;
    [alertController sv_setContentView:textView];
    [textView release];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    EditorTrackViewModel *viewModel = self.viewModel;
    UIAlertAction *editCaptionAction = [UIAlertAction actionWithTitle:@"Edit" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [viewModel editCaptionWithItemModel:itemModel attributedString:textView.attributedText completionHandler:nil];
    }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:editCaptionAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (UIMenu *)trackSegmentMenuWithItemModel:(EditorTrackItemModel *)itemModel suggestedActions:(NSArray<UIMenuElement *> *)suggestedActions __attribute__((objc_direct)) {
    EditorTrackViewModel *viewModel = self.viewModel;
    
    __weak auto weakSelf = self;
    
    UIAction *trimAction = [UIAction actionWithTitle:@"Trim" image:[UIImage systemImageNamed:@"timeline.selection"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf presentTrimClipViewControllerWithItemModel:itemModel];
    }];
    
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
                                      children:@[
        trimAction,
        deleteAction
    ]];
    
    UIMenu *suggestedMenu = [UIMenu menuWithTitle:[NSString string]
                                            image:nil
                                       identifier:nil 
                                          options:UIMenuOptionsDisplayInline
                                         children:suggestedActions];
    
    return [UIMenu menuWithChildren:@[deleteMenu, suggestedMenu]];
}

- (UIMenu *)captionMenuWithItemModel:(EditorTrackItemModel *)itemModel suggestedActions:(NSArray<UIMenuElement *> *)suggestedActions __attribute__((objc_direct)) {
    EditorTrackViewModel *viewModel = self.viewModel;
    EditorRenderCaption *caption = itemModel.renderCaption;
    CMTime totalDurationTime = viewModel.durationTime;
    CMTime startTime = CMTimeConvertScale(caption.startTime, totalDurationTime.timescale, kCMTimeRoundingMethod_RoundAwayFromZero);
    CMTime endTime = CMTimeConvertScale(caption.endTime, totalDurationTime.timescale, kCMTimeRoundingMethod_RoundAwayFromZero);
    
    __weak auto weakSelf = self;
    
    UIAction *editAction = [UIAction actionWithTitle:@"Edit Text" image:[UIImage systemImageNamed:@"pencil"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf presentEditingCaptionAlertControllerWithItemModel:itemModel];
    }];
    
    //
    
    // TODO: https://github.com/pookjw/xrOS_UISliderLeak Memory Leak
    UISlider *startTimeSlider = [UISlider new];
    UISlider *endTimeSlider = [UISlider new];
    __weak UISlider *startTimeSlider_weakRef = startTimeSlider;
    __weak UISlider *endTimeSlider_weakRef = endTimeSlider;
    
    startTimeSlider.minimumValue = 0.f;
    startTimeSlider.maximumValue = endTime.value;
    startTimeSlider.value = startTime.value;
    endTimeSlider.minimumValue = startTime.value;
    endTimeSlider.maximumValue = totalDurationTime.value;
    endTimeSlider.value = endTime.value;
    
    UIAction *startTimeValueChangedAction = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        UISlider *startTimeSlider = action.sender;
        endTimeSlider_weakRef.minimumValue = startTimeSlider.value;
    }];
    
    UIAction *endTimeValueChangedAction = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        UISlider *endTimeSlider = action.sender;
        startTimeSlider_weakRef.maximumValue = endTimeSlider.value;
    }];
    
    UIAction *startTimeTouchUpAction = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        UISlider *startTimeSlider = action.sender;
        endTimeSlider_weakRef.minimumValue = startTimeSlider.value;
        
        [viewModel editCaptionWithItemModel:itemModel 
                                  startTime:CMTimeMake(startTimeSlider.value, totalDurationTime.timescale)
                                    endTime:CMTimeMake(endTimeSlider_weakRef.value, totalDurationTime.timescale)
                          completionHandler:nil];
    }];
    
    UIAction *endTimeTouchUpAction = [UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        UISlider *endTimeSlider = action.sender;
        startTimeSlider_weakRef.maximumValue = endTimeSlider.value;
        
        [viewModel editCaptionWithItemModel:itemModel 
                                  startTime:CMTimeMake(startTimeSlider_weakRef.value, totalDurationTime.timescale)
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
        CMTime currentTime = [collectionViewLayout timeFromContentOffsetX:scrollView.contentOffset.x];
        [_delegate editorTrackViewController:self scrollingWithCurrentTime:currentTime];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {  
    if ([scrollView isEqual:self.collectionView]) {       
        id<EditorTrackViewControllerDelegate> _delegate = self.delegate;
        if (_delegate == nil) return;
        
        auto collectionViewLayout = static_cast<EditorTrackCollectionViewLayout *>(self.collectionView.collectionViewLayout);
        CMTime currentTime = [collectionViewLayout timeFromContentOffsetX:scrollView.contentOffset.x];
        [_delegate editorTrackViewController:self willBeginScrollingWithCurrentTime:currentTime];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if ([scrollView isEqual:self.collectionView]) {  
        if (decelerate) return;
        id<EditorTrackViewControllerDelegate> _delegate = self.delegate;
        if (_delegate == nil) return;
        
        auto collectionViewLayout = static_cast<EditorTrackCollectionViewLayout *>(self.collectionView.collectionViewLayout);
        CMTime currentTime = [collectionViewLayout timeFromContentOffsetX:scrollView.contentOffset.x];
        [_delegate editorTrackViewController:self didEndScrollingWithCurrentTime:currentTime];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if ([scrollView isEqual:self.collectionView]) {  
        id<EditorTrackViewControllerDelegate> _delegate = self.delegate;
        if (_delegate == nil) return;
        
        auto collectionViewLayout = static_cast<EditorTrackCollectionViewLayout *>(self.collectionView);
        CMTime currentTime = [collectionViewLayout timeFromContentOffsetX:scrollView.contentOffset.x];
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
                                                                                        previewProvider:^UIViewController * _Nullable{
        AVCompositionTrackSegment *compoistionTrackSegment = itemModel.compositionTrackSegment;
        
        if (compoistionTrackSegment == nil) return nil;
        
        EditorTrackAudioTrackSegmentPreviewViewController *viewController = [[EditorTrackAudioTrackSegmentPreviewViewController alloc] initWithAVCompositionTrackSegment:compoistionTrackSegment];
        viewController.preferredContentSize = CGSizeMake(200., 200.);
        
        return [viewController autorelease];
    }
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


#pragma mark - PLUIEditVideoViewController

#if !TARGET_OS_VISION
- (void)editVideoViewControllerTrimVideo:(UIBarButtonItem *)sender {
    UINavigationItem *_owningNavigationItem = ((id (*)(id, SEL))objc_msgSend)(sender, sel_registerName("_owningNavigationItem"));
    
    UINavigationBar *_navigationBar = nil;
    object_getInstanceVariable(_owningNavigationItem, "_navigationBar", (void **)&_navigationBar);
    
    UINavigationController *navigationController = (UINavigationController *)_navigationBar.delegate;
    __kindof UIViewController *editVideoViewController = navigationController.viewControllers[0];
    
    // PLVideoView *
    __kindof UIView *_videoView = nil;
    object_getInstanceVariable(editVideoViewController, "_videoView", (void **)&_videoView);
    
    double startTime = ((double (*)(id, SEL))objc_msgSend)(_videoView, sel_registerName("startTime"));
    double endTime = ((double (*)(id, SEL))objc_msgSend)(_videoView, sel_registerName("endTime"));
    
    EditorTrackItemModel *itemModel = objc_getAssociatedObject(editVideoViewController, [EditorTrackViewController editVideoViewControllerItemModelAssociationKey]);
    
    [self.viewModel trimVideoClipWithItemModel:itemModel 
                                assetStartTime:CMTimeMake(startTime * 1000000ULL, 1000000ULL) 
                                  assetEndTime:CMTimeMake(endTime * 1000000ULL, 1000000ULL)
                             completionHandler:nil];
    
    [navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)editVideoViewController:(__kindof UIViewController *)editVideoViewController didFailWithError:(NSError *)error {
    abort();
}

- (void)editVideoViewController:(__kindof UIViewController *)editVideoViewController didTrimVideoWithOptions:(NSDictionary *)options {
    [editVideoViewController dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"%@", options);
}

- (void)editVideoViewControllerDidCancel:(__kindof UIViewController *)editVideoViewController {
    [editVideoViewController dismissViewControllerAnimated:YES completion:nil];
}
#endif

@end
