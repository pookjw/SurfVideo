//
//  EditorViewController.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import "EditorViewController.hpp"
#import "EditorViewModel.hpp"
#import "EditorMenuOrnamentViewController.hpp"
#import "EditorPlayerView.hpp"
#import "ImageUtils.hpp"
#import "UIAlertController+SetCustomView.hpp"
#import "UIAlertController+Private.h"
#import "PHPickerConfiguration+onlyReturnsIdentifiers.hpp"
#import "EditorTrackViewController.hpp"
#import <AVKit/AVKit.h>
#import <PhotosUI/PhotosUI.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <TargetConditionals.h>

namespace _EditorViewController {
    void *progressFinishedContext = &progressFinishedContext;
}

__attribute__((objc_direct_members))
@interface EditorViewController () <PHPickerViewControllerDelegate>
@property (retain, readonly, nonatomic) EditorPlayerView *playerView;
@property (retain, readonly, nonatomic) EditorTrackViewController *trackViewController;
@property (retain, nonatomic) EditorViewModel *viewModel;
@property (retain, nonatomic) NSProgress * _Nullable progress;
@end

@implementation EditorViewController
@synthesize playerView = _playerView;
@synthesize trackViewController = _trackViewController;

- (instancetype)initWithUserActivities:(NSSet<NSUserActivity *> *)userActivities {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _viewModel = [[EditorViewModel alloc] initWithUserActivities:userActivities];
        [self commonInit_EditorViewController];
    }
    
    return self;
}

- (instancetype)initWithVideoProject:(SVVideoProject *)videoProject {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _viewModel = [[EditorViewModel alloc] initWithVideoProject:videoProject];
        [self commonInit_EditorViewController];
    }
    
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self
                                                  name:EditorViewModelDidChangeCompositionNotification
                                                object:_viewModel];
    [_playerView release];
    [_trackViewController release];
    [_progress cancel];
    [_progress release];
    [_viewModel release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == _EditorViewController::progressFinishedContext) {
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
    [self setupMenuOrnament];
#endif
}

- (void)setupTrailingItemGroups __attribute__((objc_direct)) {
    NSMutableArray<UIBarButtonItem *> *trailingBarButtomItems = [NSMutableArray<UIBarButtonItem *> new];
    
    __weak auto weakSelf = self;
    
    UIAction *addFootageAction = [UIAction actionWithTitle:[NSString string] image:[UIImage systemImageNamed:@"photo.badge.plus.fill"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf presentPickerViewController];
    }];
    
    UIBarButtonItem *addFootageBarButtonItem = [[UIBarButtonItem alloc] initWithPrimaryAction:addFootageAction];
    [trailingBarButtomItems addObject:addFootageBarButtonItem];
    [addFootageBarButtonItem release];
    
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
- (void)setupMenuOrnament __attribute__((objc_direct)) {
    // MRUIOrnamentsItem
    id mrui_ornamentsItem = reinterpret_cast<id (*) (id, SEL)>(objc_msgSend) (self, NSSelectorFromString (@"mrui_ornamentsItem"));
    EditorMenuOrnamentViewController *menuOrnamentViewController = [EditorMenuOrnamentViewController new];
    id ornament = reinterpret_cast<id (*) (id, SEL, id)>(objc_msgSend)([NSClassFromString(@"MRUIPlatterOrnament") alloc], NSSelectorFromString(@"initWithViewController:"), menuOrnamentViewController);
    [menuOrnamentViewController release];
    
    reinterpret_cast<void (*) (id, SEL, CGSize)>(objc_msgSend)(ornament, NSSelectorFromString(@"setPreferredContentSize:"), CGSizeMake(400.f, 400.f));
    reinterpret_cast<void (*) (id, SEL, CGPoint)>(objc_msgSend)(ornament, NSSelectorFromString(@"setContentAnchorPoint:"), CGPointMake(0.f, 0.5f));
    reinterpret_cast<void (*) (id, SEL, CGPoint)>(objc_msgSend)(ornament, NSSelectorFromString(@"setSceneAnchorPoint:"), CGPointMake(1.f, 0.5f));
    reinterpret_cast<void (*) (id, SEL, CGFloat)>(objc_msgSend)(ornament, NSSelectorFromString(@"_setZOffset:"), 100.f);
    
    NSMutableArray *ornaments = [reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(mrui_ornamentsItem, NSSelectorFromString(@"ornaments")) mutableCopy];
    [ornaments addObject:ornament];
    [ornament release];
    
    reinterpret_cast<void (*) (id, SEL, id)>(objc_msgSend)(mrui_ornamentsItem, NSSelectorFromString(@"setOrnaments:"), ornaments);
    [ornaments release];
}
#endif

- (void)setupViewAttibutes __attribute__((objc_direct)) {
    self.view.backgroundColor = UIColor.systemBackgroundColor;
}

- (void)setupPlayerView __attribute__((objc_direct)) {
    EditorPlayerView *playerView = self.playerView;
    playerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:playerView];
    [NSLayoutConstraint activateConstraints:@[
        [playerView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [playerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [playerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
    ]];
}

- (void)setupTrackViewController __attribute__((objc_direct)) {
    EditorTrackViewController *trackViewController = self.trackViewController;
    
    [self addChildViewController:trackViewController];
    UIView *contentView = trackViewController.view;
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:contentView];
    [NSLayoutConstraint activateConstraints:@[
        [contentView.topAnchor constraintEqualToAnchor:self.playerView.bottomAnchor],
        [contentView.heightAnchor constraintEqualToAnchor:self.playerView.heightAnchor],
        [contentView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [contentView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [contentView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
    [trackViewController didMoveToParentViewController:self];
}

- (void)addObservers __attribute__((objc_direct)) {
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(compositionDidChange:)
                                               name:EditorViewModelDidChangeCompositionNotification
                                             object:_viewModel];
}

- (void)loadInitialComposition __attribute__((objc_direct)) {
    auto alert = [self presentLoadingAlertController];
    __weak auto weakSelf = self;
    
    [_viewModel initializeWithProgressHandler:^(NSProgress * _Nonnull progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.progress = progress;
            static_cast<UIProgressView *>(alert.contentViewController.view).observedProgress = progress;
        });
    } completionHandler:^(AVComposition * _Nullable composition, NSError * _Nullable error) {
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

- (PHPickerViewController *)presentPickerViewController __attribute__((objc_direct)) {
    PHPickerConfiguration *configuration = [[PHPickerConfiguration alloc] initWithPhotoLibrary:[PHPhotoLibrary sharedPhotoLibrary]];
    configuration.selectionLimit = 0;
    configuration.sv_onlyReturnsIdentifiers = YES;
    
    PHPickerViewController *pickerViewController = [[PHPickerViewController alloc] initWithConfiguration:configuration];
    [configuration release];
    
    pickerViewController.delegate = self;
    
    [self presentViewController:pickerViewController animated:YES completion:nil];
    
    return [pickerViewController autorelease];
}

- (void)compositionDidChange:(NSNotification *)notification {
    auto composition = static_cast<AVComposition *>(notification.userInfo[EditorViewModelDidChangeCompositionKey]);
    
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:composition];
    const CGSize renderSize = CGSizeMake(1280.f, 720.f);
    __weak auto weakSelf = self;
    
    [AVMutableVideoComposition videoCompositionWithAsset:composition applyingCIFiltersWithHandler:^(AVAsynchronousCIImageFilteringRequest * _Nonnull request) {
        CIImage *sourceImage = request.sourceImage;
        CIImage *image2 = ImageUtils::aspectFit(sourceImage, renderSize).imageByClampingToExtent;
        CIColor *color = [[CIColor alloc] initWithRed:1.f green:1.f blue:1.f alpha:1.f];
        CIImage *finalImage = [image2 imageByCompositingOverImage:[CIImage imageWithColor:color]];
        [color release];
        
        [request finishWithImage:finalImage context:nil];
    } completionHandler:^(AVMutableVideoComposition * _Nullable videoComposition, NSError * _Nullable error) {
        videoComposition.renderSize = renderSize;
        videoComposition.frameDuration = CMTimeMake(1, 90);
        videoComposition.renderScale = 1.f;
        
        playerItem.videoComposition = videoComposition;
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        auto loadedSelf = weakSelf;
        if (!loadedSelf) NS_VOIDRETURN;
        
        if (AVPlayer *player = loadedSelf.playerView.player) {
            [player.currentItem cancelPendingSeeks];
            [player replaceCurrentItemWithPlayerItem:playerItem];
        } else {
            AVPlayer *_player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
            weakSelf.playerView.player = _player;
            [_player release];
        }
    });
    
    [playerItem release];
}

- (EditorPlayerView *)playerView {
    if (_playerView) return _playerView;
    
    EditorPlayerView *editorPlayerView = [[EditorPlayerView alloc] initWithFrame:self.view.bounds];
    
    [_playerView release];
    _playerView = [editorPlayerView retain];
    
    return [editorPlayerView autorelease];
}

- (EditorTrackViewController *)trackViewController {
    if (_trackViewController) return _trackViewController;
    
    EditorTrackViewController *trackViewController = [[EditorTrackViewController alloc] initWithEditorViewModel:_viewModel];
    
    [_trackViewController release];
    _trackViewController = [trackViewController retain];
    
    return [trackViewController autorelease];
}


#pragma mark - PHPickerViewControllerDelegate

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    auto alert = [self presentLoadingAlertController];
    __weak auto weakSelf = self;
    
    [_viewModel appendVideosToMainVideoTrackFromPickerResults:results
                                              progressHandler:^(NSProgress * _Nonnull progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.progress = progress;
            static_cast<UIProgressView *>(alert.contentViewController.view).observedProgress = progress;
        });
    } completionHandler:^(AVComposition * _Nullable composition, NSError * _Nullable error) {
        assert(!error);
        dispatch_async(dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:NO completion:nil];
        });
    }];
}

@end
