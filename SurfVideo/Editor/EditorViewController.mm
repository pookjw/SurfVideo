//
//  EditorViewController.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import "EditorViewController.hpp"
#import "EditorService+VideoClip.hpp"
#import "EditorService+AudioClip.hpp"
#import "EditorService+Caption.hpp"
#import "EditorMenuViewController.hpp"
#import "EditorPlayerViewController.hpp"
#import "EditorExportButtonViewController.hpp"
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

    void *pickerTypeKey = &pickerTypeKey;
    NSString *ornamentPickerType = @"ornamentPickerType";
    NSString *addVideoClipPickerType = @"addVideoClipPickerType";
    NSString *addAudioClipPickerType = @"addAudioClipPickerType";
}

__attribute__((objc_direct_members))
#if TARGET_OS_VISION
@interface EditorViewController () <PHPickerViewControllerDelegate, UIDocumentBrowserViewControllerDelegate, EditorPlayerViewControllerDelegate, EditorTrackViewControllerDelegate, EditorMenuViewControllerDelegate, EditorExportButtonViewControllerDelegate>
#else
@interface EditorViewController () <PHPickerViewControllerDelegate, UIDocumentBrowserViewControllerDelegate, EditorPlayerViewControllerDelegate, EditorTrackViewControllerDelegate, EditorMenuViewControllerDelegate>
#endif
@property (retain, readonly, nonatomic) EditorPlayerViewController *playerViewController;
@property (retain, readonly, nonatomic) EditorTrackViewController *trackViewController;
@property (retain, readonly, nonatomic) EditorMenuViewController *menuViewController;
@property (retain, readonly, nonatomic) PHPickerViewController *ornamentPhotoPickerViewController;
#if TARGET_OS_VISION
@property (retain, readonly, nonatomic) EditorExportButtonViewController *exportButtonViewController;
@property (retain, readonly, nonatomic) id playerOrnament; // MRUIPlatterOrnament *
@property (retain, readonly, nonatomic) id menuOrnament; // MRUIPlatterOrnament *
@property (retain, readonly, nonatomic) id photoPickerOrnament; // MRUIPlatterOrnament *
@property (retain, readonly, nonatomic) id exportButtonOrnament; // MRUIPlatterOrnament *
#endif
@property (retain, nonatomic) EditorService *editorService;
@property (retain, nonatomic) NSProgress * _Nullable progress;
@property (assign, nonatomic) BOOL isTrackViewScrolling;
@end

@implementation EditorViewController

@synthesize playerViewController = _playerViewController;
@synthesize trackViewController = _trackViewController;
@synthesize menuViewController = _menuViewController;
@synthesize ornamentPhotoPickerViewController = _ornamentPhotoPickerViewController;
#if TARGET_OS_VISION
@synthesize exportButtonViewController = _exportButtonViewController;
@synthesize playerOrnament = _playerOrnament;
@synthesize menuOrnament = _menuOrnament;
@synthesize photoPickerOrnament = _photoPickerOrnament;
@synthesize exportButtonOrnament = _exportButtonOrnament;
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
    [_ornamentPhotoPickerViewController release];
#if TARGET_OS_VISION
    [_exportButtonViewController release];
    [_playerOrnament release];
    [_menuOrnament release];
    [_photoPickerOrnament release];
    [_exportButtonOrnament release];
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
    [self setupTrackViewController];
    [self addObservers];
}

- (void)viewIsAppearing:(BOOL)animated {
    [super viewIsAppearing:animated];
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
    __weak auto weakSelf = self;
    
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
    reinterpret_cast<void (*) (id, SEL, id)>(objc_msgSend)(mrui_ornamentsItem, NSSelectorFromString(@"setOrnaments:"), @[self.playerOrnament, self.menuOrnament, self.photoPickerOrnament, self.exportButtonOrnament]);
}
#endif

- (void)setupViewAttibutes __attribute__((objc_direct)) {
    self.view.backgroundColor = UIColor.systemBackgroundColor;
}

- (void)setupTrackViewController __attribute__((objc_direct)) {
    EditorTrackViewController *trackViewController = self.trackViewController;
    
    [self addChildViewController:trackViewController];
    UIView *trackView = trackViewController.view;
    trackView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:trackView];
    [trackViewController didMoveToParentViewController:self];
}

- (void)addObservers __attribute__((objc_direct)) {
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(compositionDidChange:)
                                               name:EditorServiceCompositionDidChangeNotification
                                             object:_editorService];
}

- (void)loadInitialComposition __attribute__((objc_direct)) {
    UIProgressView *progressView;
    UIAlertController *alert = [self presentLoadingAlertControllerWithProgressView:&progressView animated:NO];
    __weak auto weakSelf = self;
    
    [self.editorService initializeWithProgressHandler:^(NSProgress * _Nonnull progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.progress = progress;
            progressView.observedProgress = progress;
        });
    } completionHandler:^(AVComposition * _Nullable composition, AVVideoComposition * _Nullable videoComposition, NSArray<__kindof EditorRenderElement *> * _Nullable renderElements, NSDictionary<NSNumber *, NSDictionary<NSNumber *, NSString *> *> *trackSegmentNames, NSDictionary<NSNumber *, NSArray<NSUUID *> *> *compositionIDs, NSError * _Nullable error) {
        assert(!error);
        dispatch_async(dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:NO completion:nil];
        });
    }];
}

- (UIAlertController *)presentLoadingAlertControllerWithProgressView:(UIProgressView **)progressViewPtr animated:(BOOL)animated __attribute__((objc_direct)) {
    __weak auto weakSelf = self;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Loading..." message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    [alert sv_setContentView:progressView];
    *progressViewPtr = [[progressView retain] autorelease];
    
    alert.image = [UIImage systemImageNamed:@"figure.socialdance"];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf.progress cancel];
    }];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:animated completion:^{
        if (weakSelf.progress.isFinished) {
            [alert dismissViewControllerAnimated:animated completion:nil];
        }
    }];
    
    [progressView release];
    
    return alert;
}

- (void)presentAddCaptionAlertController __attribute__((objc_direct)) {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Add Caption" message:nil preferredStyle:UIAlertControllerStyleAlert];
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
    UIAlertAction *addCaptionAction = [UIAlertAction actionWithTitle:@"Add" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
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

- (PHPickerViewController *)ornamentPhotoPickerViewController {
    if (auto pickerViewController = _ornamentPhotoPickerViewController) return pickerViewController;
    
    PHPickerConfiguration *configuration = [[PHPickerConfiguration alloc] initWithPhotoLibrary:[PHPhotoLibrary sharedPhotoLibrary]];
    configuration.filter = [PHPickerFilter videosFilter];
    configuration.selectionLimit = 0;
    configuration.sv_onlyReturnsIdentifiers = YES;
    
    PHPickerViewController *pickerViewController = [[PHPickerViewController alloc] initWithConfiguration:configuration];
    [configuration release];
    
    pickerViewController.delegate = self;
    
    objc_setAssociatedObject(pickerViewController, 
                             ns_EditorViewController::pickerTypeKey,
                             ns_EditorViewController::ornamentPickerType,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    _ornamentPhotoPickerViewController = [pickerViewController retain];
    return [pickerViewController autorelease];
}

#if TARGET_OS_VISION

- (EditorExportButtonViewController *)exportButtonViewController {
    if (auto exportButtonViewController = _exportButtonViewController) return exportButtonViewController;
    
    EditorExportButtonViewController *exportButtonViewController = [EditorExportButtonViewController new];
    exportButtonViewController.delegate = self;
    
    _exportButtonViewController = [exportButtonViewController retain];
    return [exportButtonViewController autorelease];
}

- (id)playerOrnament {
    if (id playerOrnament = _playerOrnament) return playerOrnament;
    
    EditorPlayerViewController *playerViewController = self.playerViewController;
    id playerOrnament = reinterpret_cast<id (*) (id, SEL, id)>(objc_msgSend)([NSClassFromString(@"MRUIPlatterOrnament") alloc], NSSelectorFromString(@"initWithViewController:"), playerViewController);
    
    reinterpret_cast<void (*) (id, SEL, CGSize)>(objc_msgSend)(playerOrnament, NSSelectorFromString(@"setPreferredContentSize:"), CGSizeMake(1280.f, 720.f));
    reinterpret_cast<void (*) (id, SEL, CGPoint)>(objc_msgSend)(playerOrnament, NSSelectorFromString(@"setContentAnchorPoint:"), CGPointMake(0.5f, 1.f));
    reinterpret_cast<void (*) (id, SEL, CGPoint)>(objc_msgSend)(playerOrnament, NSSelectorFromString(@"setSceneAnchorPoint:"), CGPointMake(0.5f, 0.f));
    reinterpret_cast<void (*) (id, SEL, CGFloat)>(objc_msgSend)(playerOrnament, NSSelectorFromString(@"_setZOffset:"), 0.f);
    reinterpret_cast<void (*) (id, SEL, CGPoint)>(objc_msgSend)(playerOrnament, NSSelectorFromString(@"setOffset2D:"), CGPointMake(0.f, -50.f));
    
    _playerOrnament = [playerOrnament retain];
    return [playerOrnament autorelease];
}

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
    
    PHPickerViewController *photoPickerViewController = self.ornamentPhotoPickerViewController;
    
    id photoPickerOrnament = reinterpret_cast<id (*) (id, SEL, id)>(objc_msgSend)([NSClassFromString(@"MRUIPlatterOrnament") alloc], NSSelectorFromString(@"initWithViewController:"), photoPickerViewController);
    
    reinterpret_cast<void (*) (id, SEL, CGSize)>(objc_msgSend)(photoPickerOrnament, NSSelectorFromString(@"setPreferredContentSize:"), CGSizeMake(400.f, 600.f));
    reinterpret_cast<void (*) (id, SEL, CGPoint)>(objc_msgSend)(photoPickerOrnament, NSSelectorFromString(@"setContentAnchorPoint:"), CGPointMake(0.f, 0.5f));
    reinterpret_cast<void (*) (id, SEL, CGPoint)>(objc_msgSend)(photoPickerOrnament, NSSelectorFromString(@"setSceneAnchorPoint:"), CGPointMake(1.f, 0.5f));
    reinterpret_cast<void (*) (id, SEL, CGFloat)>(objc_msgSend)(photoPickerOrnament, NSSelectorFromString(@"_setZOffset:"), -10.f);
    reinterpret_cast<void (*) (id, SEL, CGPoint)>(objc_msgSend)(photoPickerOrnament, NSSelectorFromString(@"setOffset2D:"), CGPointMake(50.f, 0.f));
    
    _photoPickerOrnament = [photoPickerOrnament retain];
    return [photoPickerOrnament autorelease];
}

- (id)exportButtonOrnament {
    if (id exportButtonOrnament = _exportButtonOrnament) return exportButtonOrnament;
    
    EditorExportButtonViewController *exportButtonViewController = self.exportButtonViewController;
    
    id exportButtonOrnament = reinterpret_cast<id (*) (id, SEL, id)>(objc_msgSend)([NSClassFromString(@"MRUIPlatterOrnament") alloc], NSSelectorFromString(@"initWithViewController:"), exportButtonViewController);
    
    reinterpret_cast<void (*) (id, SEL, CGSize)>(objc_msgSend)(exportButtonOrnament, NSSelectorFromString(@"setPreferredContentSize:"), CGSizeMake(240.f, 80.f));
    reinterpret_cast<void (*) (id, SEL, CGPoint)>(objc_msgSend)(exportButtonOrnament, NSSelectorFromString(@"setContentAnchorPoint:"), CGPointMake(0.f, 0.f));
    reinterpret_cast<void (*) (id, SEL, CGPoint)>(objc_msgSend)(exportButtonOrnament, NSSelectorFromString(@"setSceneAnchorPoint:"), CGPointMake(0.5f, 1.f));
    reinterpret_cast<void (*) (id, SEL, CGFloat)>(objc_msgSend)(exportButtonOrnament, NSSelectorFromString(@"_setZOffset:"), 50.f);
    reinterpret_cast<void (*) (id, SEL, CGPoint)>(objc_msgSend)(exportButtonOrnament, NSSelectorFromString(@"setOffset2D:"), CGPointMake(120.f + 20.f, 0.f));
    
    _exportButtonOrnament = [exportButtonOrnament retain];
    return [exportButtonOrnament autorelease];
}

#endif


#pragma mark - PHPickerViewControllerDelegate

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    auto photoPickerType = static_cast<NSString *>(objc_getAssociatedObject(picker, ns_EditorViewController::pickerTypeKey));
    BOOL shouldAddVideoClips;
    
    if ([photoPickerType isEqualToString:ns_EditorViewController::ornamentPickerType]) {
        shouldAddVideoClips = YES;
    } else if ([photoPickerType isEqualToString:ns_EditorViewController::addVideoClipPickerType]) {
        shouldAddVideoClips = YES;
        [picker dismissViewControllerAnimated:YES completion:nil];
    } else if ([photoPickerType isEqualToString:ns_EditorViewController::addAudioClipPickerType]) {
        [picker dismissViewControllerAnimated:YES completion:nil];
        shouldAddVideoClips = NO;
    } else {
        return;
    }
    
    if (results.count == 0) return;
    
    //
    
    if (shouldAddVideoClips) {
        UIProgressView *progressView;
        UIAlertController *alert = [self presentLoadingAlertControllerWithProgressView:&progressView animated:YES];
        __weak auto weakSelf = self;
        
        [self.editorService appendVideoClipsToMainVideoTrackFromPickerResults:results
                                                          progressHandler:^(NSProgress * _Nonnull progress) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.progress = progress;
                progressView.observedProgress = progress;
            });
        } completionHandler:^(AVComposition * _Nullable composition, AVVideoComposition * _Nullable videoComposition, NSArray<__kindof EditorRenderElement *> * _Nullable renderElements, NSDictionary<NSNumber *, NSDictionary<NSNumber *, NSString *> *> *trackSegmentNames, NSDictionary<NSNumber *, NSArray<NSUUID *> *> *compositionIDs, NSError * _Nullable error) {
            assert(!error);
            dispatch_async(dispatch_get_main_queue(), ^{
                [alert dismissViewControllerAnimated:NO completion:nil];
            });
        }];
    } else {
        UIProgressView *progressView;
        UIAlertController *alert = [self presentLoadingAlertControllerWithProgressView:&progressView animated:YES];
        __weak auto weakSelf = self;
        
        [self.editorService appendAudioClipsToAudioTrackFromPickerResults:results
                                                      progressHandler:^(NSProgress * _Nonnull progress) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.progress = progress;
                progressView.observedProgress = progress;
            });
        } completionHandler:^(AVComposition * _Nullable composition, AVVideoComposition * _Nullable videoComposition, NSArray<__kindof EditorRenderElement *> * _Nullable renderElements, NSDictionary<NSNumber *, NSDictionary<NSNumber *, NSString *> *> *trackSegmentNames, NSDictionary<NSNumber *, NSArray<NSUUID *> *> *compositionIDs, NSError * _Nullable error) {
            assert(!error);
            dispatch_async(dispatch_get_main_queue(), ^{
                [alert dismissViewControllerAnimated:NO completion:nil];
            });
        }];
    }
}


#pragma mark - UIDocumentBrowserViewControllerDelegate

- (void)documentBrowser:(UIDocumentBrowserViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)documentURLs {
    [controller dismissViewControllerAnimated:YES completion:nil];
    if (documentURLs.count == 0) return;
    
    auto photoPickerType = static_cast<NSString *>(objc_getAssociatedObject(controller, ns_EditorViewController::pickerTypeKey));
    
    if ([photoPickerType isEqualToString:ns_EditorViewController::addVideoClipPickerType]) {
        UIProgressView *progressView;
        UIAlertController *alert = [self presentLoadingAlertControllerWithProgressView:&progressView animated:YES];
        __weak auto weakSelf = self;
        
        [self.editorService appendVideoClipsToMainVideoTrackFromURLs:documentURLs
                                                 progressHandler:^(NSProgress * _Nonnull progress) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.progress = progress;
                progressView.observedProgress = progress;
            });
        } completionHandler:^(AVComposition * _Nullable composition, AVVideoComposition * _Nullable videoComposition, NSArray<__kindof EditorRenderElement *> * _Nullable renderElements, NSDictionary<NSNumber *, NSDictionary<NSNumber *, NSString *> *> *trackSegmentNames, NSDictionary<NSNumber *, NSArray<NSUUID *> *> *compositionIDs, NSError * _Nullable error) {
            assert(!error);
            dispatch_async(dispatch_get_main_queue(), ^{
                [alert dismissViewControllerAnimated:NO completion:nil];
            });
        }];
    } else if ([photoPickerType isEqualToString:ns_EditorViewController::addAudioClipPickerType]) {
        UIProgressView *progressView;
        UIAlertController *alert = [self presentLoadingAlertControllerWithProgressView:&progressView animated:YES];
        __weak auto weakSelf = self;
        
        [self.editorService appendAudioClipsToVideoTrackFromURLs:documentURLs
                                                 progressHandler:^(NSProgress * _Nonnull progress) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.progress = progress;
                progressView.observedProgress = progress;
            });
        } completionHandler:^(AVComposition * _Nullable composition, AVVideoComposition * _Nullable videoComposition, NSArray<__kindof EditorRenderElement *> * _Nullable renderElements, NSDictionary<NSNumber *, NSDictionary<NSNumber *, NSString *> *> *trackSegmentNames, NSDictionary<NSNumber *, NSArray<NSUUID *> *> *compositionIDs, NSError * _Nullable error) {
            assert(!error);
            dispatch_async(dispatch_get_main_queue(), ^{
                [alert dismissViewControllerAnimated:NO completion:nil];
            });
        }];
    }
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
    PHPickerConfiguration *configuration = [[PHPickerConfiguration alloc] initWithPhotoLibrary:[PHPhotoLibrary sharedPhotoLibrary]];
    configuration.filter = [PHPickerFilter videosFilter];
    configuration.selectionLimit = 0;
    configuration.sv_onlyReturnsIdentifiers = YES;
    
    PHPickerViewController *pickerViewController = [[PHPickerViewController alloc] initWithConfiguration:configuration];
    [configuration release];
    pickerViewController.delegate = self;
    
    objc_setAssociatedObject(pickerViewController, 
                             ns_EditorViewController::pickerTypeKey,
                             ns_EditorViewController::addVideoClipPickerType,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [self presentViewController:pickerViewController animated:YES completion:nil];
    [pickerViewController release];
}

- (void)editorMenuViewControllerDidSelectAddVideoClipsWithDocumentBrowser:(EditorMenuViewController *)viewController {
    UIDocumentBrowserViewController *documentBrowserViewController = [[UIDocumentBrowserViewController alloc] initForOpeningContentTypes:@[UTTypeQuickTimeMovie, UTTypeMPEG4Movie]];
    
    documentBrowserViewController.allowsDocumentCreation = NO;
    documentBrowserViewController.allowsPickingMultipleItems = YES;
    documentBrowserViewController.shouldShowFileExtensions = YES;
    documentBrowserViewController.delegate = self;
    
    objc_setAssociatedObject(documentBrowserViewController, 
                             ns_EditorViewController::pickerTypeKey,
                             ns_EditorViewController::addVideoClipPickerType,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [self presentViewController:documentBrowserViewController animated:YES completion:nil];
    [documentBrowserViewController release];
}

- (void)editorMenuViewControllerDidSelectAddAudioClipsWithPhotoPicker:(EditorMenuViewController *)viewController {
    PHPickerConfiguration *configuration = [[PHPickerConfiguration alloc] initWithPhotoLibrary:[PHPhotoLibrary sharedPhotoLibrary]];
    configuration.selectionLimit = 0;
    configuration.sv_onlyReturnsIdentifiers = YES;
    PHPickerFilter *filter = [PHPickerFilter anyFilterMatchingSubfilters:@[
        [PHPickerFilter videosFilter]
    ]];
    configuration.filter = filter;
    
    PHPickerViewController *pickerViewController = [[PHPickerViewController alloc] initWithConfiguration:configuration];
    [configuration release];
    pickerViewController.delegate = self;
    
    objc_setAssociatedObject(pickerViewController, 
                             ns_EditorViewController::pickerTypeKey,
                             ns_EditorViewController::addAudioClipPickerType,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [self presentViewController:pickerViewController animated:YES completion:nil];
    [pickerViewController release];
}

- (void)editorMenuViewControllerDidSelectAddAudioClipsWithDocumentBrowser:(EditorMenuViewController *)viewController {
    UIDocumentBrowserViewController *documentBrowserViewController = [[UIDocumentBrowserViewController alloc] initForOpeningContentTypes:@[UTTypeMP3]];
    
    documentBrowserViewController.allowsDocumentCreation = NO;
    documentBrowserViewController.allowsPickingMultipleItems = YES;
    documentBrowserViewController.shouldShowFileExtensions = YES;
    documentBrowserViewController.delegate = self;
    
    objc_setAssociatedObject(documentBrowserViewController, 
                             ns_EditorViewController::pickerTypeKey,
                             ns_EditorViewController::addAudioClipPickerType,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [self presentViewController:documentBrowserViewController animated:YES completion:nil];
    [documentBrowserViewController release];
}


#if TARGET_OS_VISION

#pragma mark - EditorExportButtonViewControllerDelegate

- (void)editorExportButtonViewController:(EditorExportButtonViewController *)editorExportButtonViewController didTriggerButtonWithExportQuality:(EditorServiceExportQuality)exportQuality {
    UIProgressView *progressView;
    UIAlertController *alert = [self presentLoadingAlertControllerWithProgressView:&progressView animated:YES];
    
    NSProgress *progress = [self.editorService exportWithQuality:exportQuality completionHandler:^(NSError * _Nullable error) {
        assert(!error);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:YES completion:nil];
        });
    }];
    
    self.progress = progress;
    progressView.observedProgress = progress;
}

#endif

@end
