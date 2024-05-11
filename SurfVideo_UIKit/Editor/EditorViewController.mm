//
//  EditorViewController.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import "EditorViewController.hpp"
#import "EditorViewController+Private.hpp"
#import <SurfVideoCore/SVEditorService+VideoClip.hpp>
#import <SurfVideoCore/SVEditorService+AudioClip.hpp>
#import <SurfVideoCore/SVEditorService+Caption.hpp>
#import "EditorPlayerViewController.hpp"
#import "UIAlertController+SetCustomView.hpp"
#import "UIAlertController+Private.h"
#import "EditorTrackViewController.hpp"
#import "EditorViewVisualProviderReality.hpp"
#import "EditorViewVisualProviderIOS.hpp"
#import <SurfVideoCore/PHPickerConfiguration+onlyReturnsIdentifiers.hpp>
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
@interface EditorViewController () <PHPickerViewControllerDelegate, UIDocumentBrowserViewControllerDelegate, EditorPlayerViewControllerDelegate, EditorTrackViewControllerDelegate>
@property (class, readonly, nonatomic) Class visualProviderClass;
@property (retain, readonly, nonatomic) __kindof EditorViewVisualProvider *visualProvider;
@property (retain, nonatomic) NSProgress * _Nullable progress;
@property (assign, nonatomic) BOOL isTrackViewScrolling;
@end

@implementation EditorViewController

@synthesize visualProvider = _visualProvider;

+ (Class)visualProviderClass {
#if TARGET_OS_VISION
    return [EditorViewVisualProviderReality class];
#else
    return [EditorViewVisualProviderIOS class];
#endif
}

- (instancetype)initWithUserActivities:(NSSet<NSUserActivity *> *)userActivities {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _editorService = [[SVEditorService alloc] initWithUserActivities:userActivities];
        [self commonInit_EditorViewController];
    }
    
    return self;
}

- (instancetype)initWithVideoProject:(SVVideoProject *)videoProject {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _editorService = [[SVEditorService alloc] initWithVideoProject:videoProject];
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
    
    [_visualProvider release];
    [_playerViewController release];
    [_trackViewController release];
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
    [self.visualProvider editorViewController_viewDidLoad];
    [self addObservers];
}

- (void)viewIsAppearing:(BOOL)animated {
    [super viewIsAppearing:animated];
    [self loadInitialComposition];
}

- (void)commonInit_EditorViewController __attribute__((objc_direct)) {
    UINavigationItem *navigationItem = self.navigationItem;
    navigationItem.title = @"Editor";
    navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
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
    } completionHandler:EditorServiceCompletionHandlerBlock {
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
    
    SVEditorService *editorService = self.editorService;
    UIAlertAction *addCaptionAction = [UIAlertAction actionWithTitle:@"Add" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [editorService appendCaptionWithAttributedString:textView.attributedText completionHandler:nil];
    }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:addCaptionAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)compositionDidChange:(NSNotification *)notification {
    AVComposition *composition = notification.userInfo[EditorServiceCompositionKey];
    if (composition == nil) return;
    
    AVVideoComposition *videoComposition = notification.userInfo[EditorServiceVideoCompositionKey];
    
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:composition];
    AVMutableVideoComposition *mutableVideoComposition = [videoComposition mutableCopy];
    
    mutableVideoComposition.renderSize = composition.naturalSize;
    mutableVideoComposition.frameDuration = CMTimeMake(1, 60);
    mutableVideoComposition.renderScale = 1.f;
    
    playerItem.videoComposition = mutableVideoComposition;
    [mutableVideoComposition release];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (AVPlayer *player = self.playerViewController.player) {
            [player.currentItem cancelPendingSeeks];
            [player replaceCurrentItemWithPlayerItem:playerItem];
        } else {
            AVPlayer *_player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
            self.playerViewController.player = _player;
            [_player release];
        }
    });
    
    [playerItem release];
}

- (__kindof EditorViewVisualProvider *)visualProvider {
    if (auto visualProvider = _visualProvider) return visualProvider;
    
    Class visualProviderClass = [EditorViewController visualProviderClass];
    __kindof EditorViewVisualProvider *visualProvider = [(EditorViewVisualProvider *)[visualProviderClass alloc] initWithEditorViewController:self];
    visualProvider.delegate = self;
    
    _visualProvider = [visualProvider retain];
    return [visualProvider autorelease];
}

- (void)addVideoClipsWithPickerResults:(NSArray<PHPickerResult *> *)pickerResults __attribute__((objc_direct)) {
    UIProgressView *progressView;
    UIAlertController *alert = [self presentLoadingAlertControllerWithProgressView:&progressView animated:YES];
    __weak auto weakSelf = self;
    
    [self.editorService appendVideoClipsToMainVideoTrackFromPickerResults:pickerResults
                                                      progressHandler:^(NSProgress * _Nonnull progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.progress = progress;
            progressView.observedProgress = progress;
        });
    } completionHandler:EditorServiceCompletionHandlerBlock {
        assert(!error);
        dispatch_async(dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:NO completion:nil];
        });
    }];
}

- (void)addAudioClipsWithPickerResults:(NSArray<PHPickerResult *> *)pickerResults __attribute__((objc_direct)) {
    UIProgressView *progressView;
    UIAlertController *alert = [self presentLoadingAlertControllerWithProgressView:&progressView animated:YES];
    __weak auto weakSelf = self;
    
    [self.editorService appendAudioClipsToAudioTrackFromPickerResults:pickerResults
                                                  progressHandler:^(NSProgress * _Nonnull progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.progress = progress;
            progressView.observedProgress = progress;
        });
    } completionHandler:EditorServiceCompletionHandlerBlock {
        assert(!error);
        dispatch_async(dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:NO completion:nil];
        });
    }];
}


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
        [self addVideoClipsWithPickerResults:results];
    } else {
        [self addAudioClipsWithPickerResults:results];
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
        } completionHandler:EditorServiceCompletionHandlerBlock {
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
        } completionHandler:EditorServiceCompletionHandlerBlock {
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

@end


@implementation EditorViewController (Private)

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

- (SVEditorService *)editorService {
    return _editorService;
}


#pragma mark - EditorViewVisualProviderDelegate

- (void)didSelectAddCaptionWithEditorViewVisualProvider:(nonnull EditorViewVisualProvider *)editorViewVisualProvider { 
    [self presentAddCaptionAlertController];
}

- (void)didSelectDocumentBrowserForAddingAudioClipWithEditorViewVisualProvider:(nonnull EditorViewVisualProvider *)editorViewVisualProvider { 
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

- (void)didSelectDocumentBrowserForAddingVideoClipWithEditorViewVisualProvider:(nonnull EditorViewVisualProvider *)editorViewVisualProvider { 
    UIDocumentBrowserViewController *documentBrowserViewController = [[UIDocumentBrowserViewController alloc] initForOpeningContentTypes:@[UTTypeMPEG4Movie]];
    
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

- (void)didSelectPhotoPickerForAddingAudioClipWithEditorViewVisualProvider:(nonnull EditorViewVisualProvider *)editorViewVisualProvider { 
    PHPickerConfiguration *configuration = [[PHPickerConfiguration alloc] initWithPhotoLibrary:[PHPhotoLibrary sharedPhotoLibrary]];
    configuration.filter = [PHPickerFilter videosFilter];
    configuration.selectionLimit = 0;
    configuration.sv_onlyReturnsIdentifiers = YES;
    
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

- (void)didSelectPhotoPickerForAddingVideoClipWithEditorViewVisualProvider:(nonnull EditorViewVisualProvider *)editorViewVisualProvider { 
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

- (void)editorViewVisualProvider:(nonnull EditorViewVisualProvider *)editorViewVisualProvider didFinishPickingPickerResultsForAddingVideoClip:(nonnull NSArray<PHPickerResult *> *)pickerResults { 
    [self addVideoClipsWithPickerResults:pickerResults];
}

- (void)editorViewVisualProvider:(nonnull EditorViewVisualProvider *)editorViewVisualProvider didSelectExportWithQuality:(EditorServiceExportQuality)exportQuality { 
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

@end
