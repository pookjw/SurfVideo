//
//  EditorViewController.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import "EditorViewController.hpp"
#import "EditorService.hpp"
#import "EditorMenuViewController.hpp"
#import "EditorPlayerViewController.hpp"
#import "UIAlertController+SetCustomView.hpp"
#import "UIAlertController+Private.h"
#import "PHPickerConfiguration+onlyReturnsIdentifiers.hpp"
#import "EditorTrackViewController.hpp"
#import <AVKit/AVKit.h>
#import <PhotosUI/PhotosUI.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <TargetConditionals.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

namespace ns_EditorViewController {
    void *progressFinishedContext = &progressFinishedContext;
}

__attribute__((objc_direct_members))
@interface EditorViewController () <PHPickerViewControllerDelegate, UIDocumentBrowserViewControllerDelegate, EditorPlayerViewControllerDelegate, EditorTrackViewControllerDelegate, EditorMenuViewControllerDelegate>
@property (retain, readonly, nonatomic) EditorPlayerViewController *playerViewController;
@property (retain, readonly, nonatomic) EditorTrackViewController *trackViewController;
@property (retain, readonly, nonatomic) EditorMenuViewController *menuViewController;
@property (retain, readonly, nonatomic) PHPickerViewController *photoPickerViewController;
#if TARGET_OS_VISION
@property (retain, readonly, nonatomic) id menuOrnament; // MRUIPlatterOrnament *
@property (retain, readonly, nonatomic) id photoPickerOrnament; // MRUIPlatterOrnament *
#endif
@property (retain, nonatomic) EditorService *editorService;
@property (retain, nonatomic) NSProgress * _Nullable progress;
@property (assign, nonatomic) BOOL isTrackViewScrolling;
@end

@implementation EditorViewController

@synthesize playerViewController = _playerViewController;
@synthesize trackViewController = _trackViewController;
@synthesize menuViewController = _menuViewController;
@synthesize photoPickerViewController = _photoPickerViewController;
#if TARGET_OS_VISION
@synthesize menuOrnament = _menuOrnament;
@synthesize photoPickerOrnament = _photoPickerOrnament;
#endif

- (instancetype)initWithUserActivities:(NSSet<NSUserActivity *> *)userActivities {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _editorService = [[EditorService alloc] initWithUserActivities:userActivities];
        [self commonInit_EditorViewController];
    }
    
    return self;
}

- (instancetype)initWithVideoProject:(SVVideoProject *)videoProject {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _editorService = [[EditorService alloc] initWithVideoProject:videoProject];
        [self commonInit_EditorViewController];
    }
    
    return self;
}

- (void)dealloc {
    if (auto editorService = _editorService) {
        [NSNotificationCenter.defaultCenter removeObserver:self
                                                      name:EditorServiceCompositionDidChangeNotification
                                                    object:editorService];
    }
    [_playerViewController release];
    [_trackViewController release];
    [_menuViewController release];
    [_photoPickerViewController release];
#if TARGET_OS_VISION
    [_menuOrnament release];
    [_photoPickerOrnament release];
#endif
    [_progress cancel];
    [_progress release];
    [_editorService release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == ns_EditorViewController::progressFinishedContext) {
        NSLog(@"Done!");
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViewAttibutes];
    [self setupPlayerView];
    [self setupTrackViewController];
    [self addObservers];
    [self loadInitialComposition];
}

- (void)commonInit_EditorViewController __attribute__((objc_direct)) {
    UINavigationItem *navigationItem = self.navigationItem;
    navigationItem.title = @"Editor";
    navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    
    [self setupTrailingItemGroups];
#if TARGET_OS_VISION
    [self setupOrnaments];
#endif
}

- (void)setupTrailingItemGroups __attribute__((objc_direct)) {
    NSMutableArray<UIBarButtonItem *> *trailingBarButtomItems = [NSMutableArray<UIBarButtonItem *> new];
    
#if !TARGET_OS_VISION
    UIAction *dismissAction = [UIAction actionWithTitle:@"Done" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
    }];
    
    UIBarButtonItem *dismissBarButtonItem = [[UIBarButtonItem alloc] initWithPrimaryAction:dismissAction];
    [trailingBarButtomItems addObject:dismissBarButtonItem];
    [dismissBarButtonItem release];
#endif
    
    UINavigationItem *navigationItem = self.navigationItem;
    
    auto trailingItemGroups = static_cast<NSMutableArray<UIBarButtonItemGroup *> *>([navigationItem.trailingItemGroups mutableCopy]);
    UIBarButtonItemGroup *trailingItemGroup = [[UIBarButtonItemGroup alloc] initWithBarButtonItems:trailingBarButtomItems representativeItem:nil];
    [trailingBarButtomItems release];
    
    [trailingItemGroups addObject:trailingItemGroup];
    [trailingItemGroup release];
    
    navigationItem.trailingItemGroups = trailingItemGroups;
    [trailingItemGroups release];
}

#if TARGET_OS_VISION
- (void)setupOrnaments __attribute__((objc_direct)) {
    // MRUIOrnamentsItem
    id mrui_ornamentsItem = reinterpret_cast<id (*) (id, SEL)>(objc_msgSend) (self, NSSelectorFromString(@"mrui_ornamentsItem"));
    reinterpret_cast<void (*) (id, SEL, id)>(objc_msgSend)(mrui_ornamentsItem, NSSelectorFromString(@"setOrnaments:"), @[self.menuOrnament, self.photoPickerOrnament]);
}
#endif

- (void)setupViewAttibutes __attribute__((objc_direct)) {
    self.view.backgroundColor = UIColor.systemBackgroundColor;
}

- (void)setupPlayerView __attribute__((objc_direct)) {
    EditorPlayerViewController *playerViewController = self.playerViewController;
    
    [self addChildViewController:playerViewController];
    playerViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:playerViewController.view];
    [NSLayoutConstraint activateConstraints:@[
        [playerViewController.view.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [playerViewController.view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [playerViewController.view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
    ]];
    
    [playerViewController didMoveToParentViewController:self];
}

- (void)setupTrackViewController __attribute__((objc_direct)) {
    EditorTrackViewController *trackViewController = self.trackViewController;
    
    [self addChildViewController:trackViewController];
    UIView *contentView = trackViewController.view;
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:contentView];
    [NSLayoutConstraint activateConstraints:@[
        [contentView.topAnchor constraintEqualToAnchor:self.playerViewController.view.bottomAnchor],
        [contentView.heightAnchor constraintEqualToAnchor:self.playerViewController.view.heightAnchor],
        [contentView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [contentView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [contentView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
    [trackViewController didMoveToParentViewController:self];
}

- (void)addObservers __attribute__((objc_direct)) {
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(compositionDidChange:)
                                               name:EditorServiceCompositionDidChangeNotification
                                             object:_editorService];
}

- (void)loadInitialComposition __attribute__((objc_direct)) {
    auto alert = [self presentLoadingAlertController];
    __weak auto weakSelf = self;
    
    [_editorService initializeWithProgressHandler:^(NSProgress * _Nonnull progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.progress = progress;
            static_cast<UIProgressView *>(alert.contentViewController.view).observedProgress = progress;
        });
    } completionHandler:^(AVComposition * _Nullable composition, AVVideoComposition * _Nullable videoComposition, NSArray<__kindof EditorRenderElement *> * _Nullable renderElements, NSError * _Nullable error) {
        assert(!error);
        dispatch_async(dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:NO completion:nil];
        });
    }];
}

- (UIAlertController *)presentLoadingAlertController __attribute__((objc_direct)) {
    __weak auto weakSelf = self;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Loading..." message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    [alert sv_setContentView:progressView];
    
    alert.image = [UIImage systemImageNamed:@"figure.socialdance"];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf.progress cancel];
    }];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:NO completion:^{
        if (weakSelf.progress.isFinished) {
            [alert dismissViewControllerAnimated:NO completion:nil];
        }
    }];
    
    [progressView release];
    
    return alert;
}

- (PHPickerViewController *)presentPhotoPickerViewController __attribute__((objc_direct)) {
    PHPickerConfiguration *configuration = [[PHPickerConfiguration alloc] initWithPhotoLibrary:[PHPhotoLibrary sharedPhotoLibrary]];
    configuration.selectionLimit = 0;
    configuration.sv_onlyReturnsIdentifiers = YES;
    
    PHPickerViewController *pickerViewController = [[PHPickerViewController alloc] initWithConfiguration:configuration];
    [configuration release];
    
    pickerViewController.delegate = self;
    
    [self presentViewController:pickerViewController animated:YES completion:nil];
    
    return [pickerViewController autorelease];
}

- (UIDocumentBrowserViewController *)presentDocumentBrowserViewController __attribute__((objc_direct)) {
    UIDocumentBrowserViewController *documentBrowserViewController = [[UIDocumentBrowserViewController alloc] initForOpeningContentTypes:@[UTTypeQuickTimeMovie]];
//    UIDocumentBrowserViewController *documentBrowserViewController = [UIDocumentBrowserViewController new];
    
    documentBrowserViewController.allowsDocumentCreation = NO;
    documentBrowserViewController.allowsPickingMultipleItems = YES;
    documentBrowserViewController.shouldShowFileExtensions = YES;
    documentBrowserViewController.delegate = self;
    
    [self presentViewController:documentBrowserViewController animated:YES completion:nil];
    
    return [documentBrowserViewController autorelease];
}

- (void)presentAddCaptionAlertController __attribute__((objc_direct)) {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Test" message:nil preferredStyle:UIAlertControllerStyleAlert];
    alertController.image = [UIImage systemImageNamed:@"plus.bubble.fill"];
    
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectNull];
    textView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.2f];
    textView.textColor = UIColor.whiteColor;
    textView.layer.cornerRadius = 8.f;
    [alertController sv_setContentView:textView];
    [textView release];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    EditorService *editorService = self.editorService;
    UIAlertAction *addCaptionAction = [UIAlertAction actionWithTitle:@"Add Caption" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [editorService appendCaptionWithAttributedString:textView.attributedText completionHandler:nil];
    }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:addCaptionAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)compositionDidChange:(NSNotification *)notification {
    auto composition = static_cast<AVComposition *>(notification.userInfo[EditorServiceCompositionKey]);
    auto videoComposition = static_cast<AVVideoComposition *>(notification.userInfo[EditorServiceVideoCompositionKey]);
    if (composition == nil) return;
    
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:composition];
    AVMutableVideoComposition *mutableVideoComposition = [videoComposition mutableCopy];
    
    mutableVideoComposition.renderSize = composition.naturalSize;
    mutableVideoComposition.frameDuration = CMTimeMake(1, 90);
    mutableVideoComposition.renderScale = 1.f;
    
    playerItem.videoComposition = mutableVideoComposition;
    [mutableVideoComposition release];
    
    __weak auto weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        auto loadedSelf = weakSelf;
        if (!loadedSelf) return;
        
        if (AVPlayer *player = loadedSelf.playerViewController.player) {
            [player.currentItem cancelPendingSeeks];
            [player replaceCurrentItemWithPlayerItem:playerItem];
        } else {
            AVPlayer *_player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
            weakSelf.playerViewController.player = _player;
            [_player release];
        }
    });
    
    [playerItem release];
}

- (EditorPlayerViewController *)playerViewController {
    if (auto playerViewController = _playerViewController) return playerViewController;
    
    EditorPlayerViewController *playerViewController = [EditorPlayerViewController new];
    playerViewController.delegate = self;
    
    _playerViewController = [playerViewController retain];
    return [playerViewController autorelease];
}

- (EditorTrackViewController *)trackViewController {
    if (auto trackViewController = _trackViewController) return trackViewController;
    
    EditorTrackViewController *trackViewController = [[EditorTrackViewController alloc] initWithEditorService:self.editorService];
    trackViewController.delegate = self;
    
    _trackViewController = [trackViewController retain];
    return [trackViewController autorelease];
}

- (EditorMenuViewController *)menuViewController {
    if (auto menuViewController = _menuViewController) return menuViewController;
        
    EditorMenuViewController *menuViewController = [[EditorMenuViewController alloc] initWithEditorService:self.editorService];
    menuViewController.delegate = self;
    
    _menuViewController = [menuViewController retain];
    return [menuViewController autorelease];
}

- (PHPickerViewController *)photoPickerViewController {
    if (auto pickerViewController = _photoPickerViewController) return pickerViewController;
    
    PHPickerConfiguration *configuration = [[PHPickerConfiguration alloc] initWithPhotoLibrary:[PHPhotoLibrary sharedPhotoLibrary]];
    configuration.selectionLimit = 0;
    configuration.sv_onlyReturnsIdentifiers = YES;
    
    PHPickerViewController *pickerViewController = [[PHPickerViewController alloc] initWithConfiguration:configuration];
    [configuration release];
    
    pickerViewController.delegate = self;
    
    _photoPickerViewController = [pickerViewController retain];
    return [pickerViewController autorelease];
}

#if TARGET_OS_VISION

- (id)menuOrnament {
    if (id menuOrnament = _menuOrnament) return menuOrnament;
    
    EditorMenuViewController *menuViewController = self.menuViewController;
    id menuOrnament = reinterpret_cast<id (*) (id, SEL, id)>(objc_msgSend)([NSClassFromString(@"MRUIPlatterOrnament") alloc], NSSelectorFromString(@"initWithViewController:"), menuViewController);
    
    reinterpret_cast<void (*) (id, SEL, CGSize)>(objc_msgSend)(menuOrnament, NSSelectorFromString(@"setPreferredContentSize:"), CGSizeMake(240.f, 80.f));
    reinterpret_cast<void (*) (id, SEL, CGPoint)>(objc_msgSend)(menuOrnament, NSSelectorFromString(@"setContentAnchorPoint:"), CGPointMake(0.5f, 0.f));
    reinterpret_cast<void (*) (id, SEL, CGPoint)>(objc_msgSend)(menuOrnament, NSSelectorFromString(@"setSceneAnchorPoint:"), CGPointMake(0.5f, 1.f));
    reinterpret_cast<void (*) (id, SEL, CGFloat)>(objc_msgSend)(menuOrnament, NSSelectorFromString(@"_setZOffset:"), 50.f);
    
    _menuOrnament = [menuOrnament retain];
    return [menuOrnament autorelease];
}

- (id)photoPickerOrnament {
    if (id photoPickerOrnament = _photoPickerOrnament) return photoPickerOrnament;
    
    PHPickerViewController *photoPickerViewController = self.photoPickerViewController;
    
    id photoPickerOrnament = reinterpret_cast<id (*) (id, SEL, id)>(objc_msgSend)([NSClassFromString(@"MRUIPlatterOrnament") alloc], NSSelectorFromString(@"initWithViewController:"), photoPickerViewController);
    
    reinterpret_cast<void (*) (id, SEL, CGSize)>(objc_msgSend)(photoPickerOrnament, NSSelectorFromString(@"setPreferredContentSize:"), CGSizeMake(400.f, 600.f));
    reinterpret_cast<void (*) (id, SEL, CGPoint)>(objc_msgSend)(photoPickerOrnament, NSSelectorFromString(@"setContentAnchorPoint:"), CGPointMake(0.f, 0.5f));
    reinterpret_cast<void (*) (id, SEL, CGPoint)>(objc_msgSend)(photoPickerOrnament, NSSelectorFromString(@"setSceneAnchorPoint:"), CGPointMake(1.f, 0.5f));
//    reinterpret_cast<void (*) (id, SEL, CGFloat)>(objc_msgSend)(photoPickerOrnament, NSSelectorFromString(@"_setZOffset:"), 50.f);
    
    _menuOrnament = [photoPickerOrnament retain];
    return [photoPickerOrnament autorelease];
}

#endif


#pragma mark - PHPickerViewControllerDelegate

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    if (![self.photoPickerViewController isEqual:picker]) {
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
    
    if (results.count == 0) return;
    
    auto alert = [self presentLoadingAlertController];
    __weak auto weakSelf = self;
    
    [self.editorService appendVideosToMainVideoTrackFromPickerResults:results
                                              progressHandler:^(NSProgress * _Nonnull progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.progress = progress;
            static_cast<UIProgressView *>(alert.contentViewController.view).observedProgress = progress;
        });
    } completionHandler:^(AVComposition * _Nullable composition, AVVideoComposition * _Nullable videoComposition, NSArray<__kindof EditorRenderElement *> * _Nullable renderElements, NSError * _Nullable error) {
        assert(!error);
        dispatch_async(dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:NO completion:nil];
        });
    }];
}


#pragma mark - UIDocumentBrowserViewControllerDelegate

- (void)documentBrowser:(UIDocumentBrowserViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)documentURLs {
    [controller dismissViewControllerAnimated:YES completion:nil];
    
    if (documentURLs.count == 0) return;
    
    
    
    auto alert = [self presentLoadingAlertController];
    __weak auto weakSelf = self;
    
    [self.editorService appendVideosToMainVideoTrackFromURLs:documentURLs
                                              progressHandler:^(NSProgress * _Nonnull progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.progress = progress;
            static_cast<UIProgressView *>(alert.contentViewController.view).observedProgress = progress;
        });
    } completionHandler:^(AVComposition * _Nullable composition, AVVideoComposition * _Nullable videoComposition, NSArray<__kindof EditorRenderElement *> * _Nullable renderElements, NSError * _Nullable error) {
        assert(!error);
        dispatch_async(dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:NO completion:nil];
        });
    }];
}


#pragma mark - EditorPlayerViewControllerDelegate

- (void)editorPlayerViewController:(EditorPlayerViewController *)editorPlayerViewControler didChangeCurrentTime:(CMTime)currentTime {
    if (self.isTrackViewScrolling) return;
    [self.trackViewController updateCurrentTime:currentTime];
}


#pragma mark - EditorTrackViewControllerDelegate

- (void)editorTrackViewController:(EditorTrackViewController *)viewController willBeginScrollingWithCurrentTime:(CMTime)currentTime {
    [self.playerViewController.player pause];
    self.isTrackViewScrolling = YES;
}

- (void)editorTrackViewController:(EditorTrackViewController *)viewController scrollingWithCurrentTime:(CMTime)currentTime {
    [self.playerViewController.player seekToTime:currentTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

- (void)editorTrackViewController:(EditorTrackViewController *)viewController didEndScrollingWithCurrentTime:(CMTime)currentTime {
    self.isTrackViewScrolling = NO;
//    [self.playerView.player play];
}


#pragma mark - EditorMenuViewControllerDelegate

- (void)editorMenuViewControllerDidSelectAddCaption:(EditorMenuViewController *)viewController {
    [self presentAddCaptionAlertController];
}

- (void)editorMenuViewControllerDidSelectAddVideoClipsWithPhotoPicker:(EditorMenuViewController *)viewController {
    [self presentPhotoPickerViewController];
}

- (void)editorMenuViewControllerDidSelectAddVideoClipsWithDocumentBrowser:(EditorMenuViewController *)viewController {
    [self presentDocumentBrowserViewController];
}

- (void)editorMenuViewControllerDidSelectAddAudioClipsWithPhotoPicker:(EditorMenuViewController *)viewController {
    
}

- (void)editorMenuViewControllerDidSelectAddAudioClipsWithDocumentBrowser:(EditorMenuViewController *)viewController {
    
}

@end
