//
//  EditorTrackViewController.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/13/23.
//

#import "EditorTrackViewController.hpp"
#import <SurfVideoCore/EditorTrackViewModel.hpp>
#import "EditorTrackCollectionViewLayout.hpp"
#import "EditorTrackAudioTrackSegmentContentConfiguration.hpp"
#import "UIAlertController+Private.h"
#import "UIAlertController+SetCustomView.hpp"
#import "EditorTrackAudioTrackSegmentPreviewViewController.hpp"
#import "UIImagePickerController+Private.h"
#import "PLVideoView+Swizzle.hpp"
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
#warning TODO _UIClickPresentationInteraction (-[UIButton showsMenuAsPrimaryAction])
@property (retain, nonatomic, readonly) UITapGestureRecognizer *collectionViewTapGestureRecognizer;
@property (retain, nonatomic, readonly) UIPinchGestureRecognizer *collectionViewPinchGestureRecognizer;
@property (retain, nonatomic, readonly) UICollectionViewCellRegistration *videoTrackSegmentCellRegistration;
@property (retain, nonatomic, readonly) UICollectionViewCellRegistration *audioTrackSegmentCellRegistration;
@property (retain, nonatomic, readonly) UICollectionViewCellRegistration *captionCellRegistration;
@property (retain, nonatomic, readonly) UICollectionViewCellRegistration *effectCellRegistration;
@property (retain, nonatomic, readonly) EditorTrackViewModel *viewModel;
@property (assign, nonatomic) CGFloat bak_pixelPerSecond;
@end

@implementation EditorTrackViewController

@synthesize collectionView = _collectionView;
@synthesize collectionViewTapGestureRecognizer = _collectionViewTapGestureRecognizer;
@synthesize collectionViewPinchGestureRecognizer = _collectionViewPinchGestureRecognizer;
@synthesize videoTrackSegmentCellRegistration = _videoTrackSegmentCellRegistration;
@synthesize audioTrackSegmentCellRegistration = _audioTrackSegmentCellRegistration;
@synthesize captionCellRegistration = _captionCellRegistration;
@synthesize effectCellRegistration = _effectCellRegistration;

#if !TARGET_OS_VISION

+ (void *)editVideoViewControllerItemModelAssociationKey {
    static void *key = &key;
    return key;
}

#endif

- (instancetype)initWithEditorService:(SVEditorService *)editorService {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _viewModel = [[EditorTrackViewModel alloc] initWithEditorService:editorService dataSource:[self makeDataSource]];
    }
    
    return self;
}

- (void)dealloc {
    [_collectionView release];
    [_collectionViewTapGestureRecognizer release];
    [_collectionViewPinchGestureRecognizer release];
    [_videoTrackSegmentCellRegistration release];
    [_audioTrackSegmentCellRegistration release];
    [_captionCellRegistration release];
    [_effectCellRegistration release];
    [_viewModel release];
    [super dealloc];
}

- (UICollectionView *)collectionViewIfLoaded {
    return _collectionView;
}

- (void)loadView {
    self.view = self.collectionView;
}

- (void)updateCurrentTime:(CMTime)currentTime {
    UICollectionView *collectionView = self.collectionView;
    
    EditorTrackCollectionViewLayout *collectionViewLayout = (EditorTrackCollectionViewLayout *)collectionView.collectionViewLayout;
    
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
    
    [collectionView addGestureRecognizer:self.collectionViewTapGestureRecognizer];
    [collectionView addGestureRecognizer:self.collectionViewPinchGestureRecognizer];
    
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

- (UICollectionViewCellRegistration *)effectCellRegistration {
    if (auto effectCellRegistration = _effectCellRegistration) return effectCellRegistration;
    
    UICollectionViewCellRegistration *effectCellRegistration = [UICollectionViewCellRegistration registrationWithCellClass:UICollectionViewListCell.class configurationHandler:^(__kindof UICollectionViewListCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, EditorTrackItemModel * _Nonnull itemModel) {
        UIListContentConfiguration *contentConfiguration = cell.defaultContentConfiguration;
        contentConfiguration.text = itemModel.renderEffect.effectName;
        contentConfiguration.image = [UIImage systemImageNamed:@"star.fill"];
        contentConfiguration.imageProperties.tintColor = contentConfiguration.textProperties.color;
        
        UIBackgroundConfiguration *backgroundConfiguration = [cell defaultBackgroundConfiguration];
        backgroundConfiguration.backgroundColor = [UIColor.systemGreenColor colorWithAlphaComponent:0.2f];
        
        cell.contentConfiguration = contentConfiguration;
        cell.backgroundConfiguration = backgroundConfiguration;
    }];
    
    _effectCellRegistration = [effectCellRegistration retain];
    return effectCellRegistration;
}

- (UITapGestureRecognizer *)collectionViewTapGestureRecognizer {
    if (auto collectionViewTapGestureRecognizer = _collectionViewTapGestureRecognizer) return collectionViewTapGestureRecognizer;
    
    UITapGestureRecognizer *collectionViewTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(collectionViewTapGestureRecognizerDidTrigger:)];
    
    _collectionViewTapGestureRecognizer = [collectionViewTapGestureRecognizer retain];
    return [collectionViewTapGestureRecognizer autorelease];
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
    UICollectionViewCellRegistration *effectCellRegistration = self.effectCellRegistration;
    
    auto dataSource = [[UICollectionViewDiffableDataSource<EditorTrackSectionModel *, EditorTrackItemModel *> alloc] initWithCollectionView:self.collectionView cellProvider:^UICollectionViewCell * _Nullable(UICollectionView * _Nonnull collectionView, NSIndexPath * _Nonnull indexPath, EditorTrackItemModel * _Nonnull itemIdentifier) {
        switch (itemIdentifier.type) {
            case EditorTrackItemModelTypeVideoTrackSegment:
                return [collectionView dequeueConfiguredReusableCellWithRegistration:videoTrackSegmentCellRegistration forIndexPath:indexPath item:itemIdentifier];
            case EditorTrackItemModelTypeAudioTrackSegment:
                return [collectionView dequeueConfiguredReusableCellWithRegistration:audioTrackSegmentCellRegistration forIndexPath:indexPath item:itemIdentifier];
            case EditorTrackItemModelTypeCaption:
                return [collectionView dequeueConfiguredReusableCellWithRegistration:captionCellRegistration forIndexPath:indexPath item:itemIdentifier];
            case EditorTrackItemModelTypeEffect:
                return [collectionView dequeueConfiguredReusableCellWithRegistration:effectCellRegistration forIndexPath:indexPath item:itemIdentifier];
            default:
                return nil;
        }
    }];
    
    return [dataSource autorelease];
}

- (void)collectionViewTapGestureRecognizerDidTrigger:(UITapGestureRecognizer *)sender {
    UICollectionView *collectionView = self.collectionView;
    
    CGPoint point = [sender locationInView:collectionView];
    UIContextMenuInteraction *contextMenuInteraction = collectionView.contextMenuInteraction;
    
    ((void (*)(id, SEL, CGPoint))objc_msgSend)(contextMenuInteraction, sel_registerName("_presentMenuAtLocation:"), point);
    // -[UIContextMenuInteraction _presentMenuAtLocation:]
}

- (void)collectionViewPinchGestureRecognizerDidTrigger:(UIPinchGestureRecognizer *)sender {
    EditorTrackCollectionViewLayout *collectionViewLayout = (EditorTrackCollectionViewLayout *)self.collectionView.collectionViewLayout;
    
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
                              sourceTrimTimeRange:CMTimeRangeFromTimeToTime(playerItem.reversePlaybackEndTime, playerItem.forwardPlaybackEndTime)
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
        _UIVideoEditorControllerVideoURL: assetURL,
        _UIImagePickerControllerCustomBackgroundColor: UIColor.tintColor
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
    
    /*
     -[PLUIImageViewController viewWillAppear:]에서 -[PLVideoView setShowsScrubber:duration:]를 호출하고 여기서
     
     dispatchtime(0, 200000000)를 호출해서 PLMoviePlayerController를 만들어서 AVPlayerItem을 생성하고
     (-[PLVideoView _prepareMoviePlayerIfNeeded], -[AVPlayerItem initWithAsset:])
     
     KVO으로 Ready To Play 상태가 되어야 (-[PLVideoView moviePlayerReadyToPlay:])가 불리고
     
     UIMovieScrubber *가 만들어지기 때문에 (-[PLVideoView _createScrubberIfNeeded] 또는 -[UIMovieScrubber initWithFrame:])
     
     UIMovieScrubber *가 생성되는 시점을 아래처럼 알 수 있다.
     */
    __weak __block id<NSObject> observer = [NSNotificationCenter.defaultCenter addObserverForName:SV_PLVideoViewDidMoviePlayerReadyToPlayNotification
                                                                                           object:_videoView
                                                                                            queue:nil
                                                                                       usingBlock:^(NSNotification * _Nonnull notification) {
        __kindof UIView *_videoView = notification.object;
        
        // UIMovieScrubber *
        __kindof UIControl *_scrubber = nil;
        object_getInstanceVariable(_videoView, "_scrubber", (void **)&_scrubber);
        
        ((void (*)(id, SEL, BOOL))objc_msgSend)(_scrubber, sel_registerName("setEditing:"), YES);
        ((void (*)(id, SEL, double))objc_msgSend)(_scrubber, sel_registerName("setTrimStartValue:"), startTimeValue);
        ((void (*)(id, SEL, double))objc_msgSend)(_scrubber, sel_registerName("setTrimEndValue:"), endTimeValue);
        
        // PLMoviePlayerController *
        id _moviePlayer = nil;
        object_getInstanceVariable(_videoView, "_moviePlayer", (void **)&_moviePlayer);
        
        AVPlayer *player = ((id (*)(id, SEL))objc_msgSend)(_moviePlayer, sel_registerName("player"));
        AVPlayerItem *currentItem = player.currentItem;
        currentItem.reversePlaybackEndTime = timeMapping.source.start;
        currentItem.forwardPlaybackEndTime = CMTimeRangeGetEnd(timeMapping.source);
        
        if (observer) {
            [NSNotificationCenter.defaultCenter removeObserver:observer];
        }
    }];
    
    ((void (*)(id, SEL, double))objc_msgSend)(_videoView, sel_registerName("setCurrentTime:"), startTimeValue);
    
    //
    
    [self presentViewController:navigationController animated:YES completion:nil];
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
    SVEditorRenderCaption *caption = itemModel.renderCaption;
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
    
    __kindof UIMenuElement *startTimeSliderMenuElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
        return startTimeSlider;
    });
    
    __kindof UIMenuElement *endTimeSliderMenuElement = reinterpret_cast<id (*)(Class, SEL, id)>(objc_msgSend)(objc_lookUpClass("UICustomViewMenuElement"), sel_registerName("elementWithViewProvider:"), ^ UIView * (__kindof UIMenuElement *menuElement) {
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
                           sourceTrimTimeRange:CMTimeRangeFromTimeToTime(CMTimeMake(startTime * 1000000ULL, 1000000ULL) , CMTimeMake(endTime * 1000000ULL, 1000000ULL))
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
