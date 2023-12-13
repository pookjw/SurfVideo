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
#import <AVKit/AVKit.h>
#import <PhotosUI/PhotosUI.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <TargetConditionals.h>
#import <memory>

namespace _EditorViewController {
    void *progressFinishedContext = &progressFinishedContext;
}

__attribute__((objc_direct_members))
@interface EditorViewController () <PHPickerViewControllerDelegate>
@property (retain, readonly, nonatomic) EditorPlayerView *editorPlayerView;
@property (retain, readonly, nonatomic) UIView *timelineView;
@property (assign, nonatomic) std::shared_ptr<EditorViewModel> viewModel;
@property (retain, nonatomic) NSProgress * _Nullable progress;
@end

@implementation EditorViewController
@synthesize editorPlayerView = _editorPlayerView;
@synthesize timelineView = _timelineView;

- (instancetype)initWithUserActivities:(NSSet<NSUserActivity *> *)userActivities {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _viewModel = std::make_shared<EditorViewModel>(userActivities);
        [self commonInit_EditorViewController];
    }
    
    return self;
}

- (instancetype)initWithVideoProject:(SVVideoProject *)videoProject {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _viewModel = std::make_shared<EditorViewModel>(videoProject);
        [self commonInit_EditorViewController];
    }
    
    return self;
}

- (void)dealloc {
    [_editorPlayerView release];
    [_timelineView release];
    [_progress cancel];
    [_progress release];
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
    [self setupEditorPlayerView];
    [self setupTimelineView];
    
    auto alert = [self presentLoadingAlertController];
    __weak auto weakSelf = self;
    
    _viewModel.get()->initialize(_viewModel,
                                ^(NSProgress *progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.progress = progress;
            static_cast<UIProgressView *>(alert.contentViewController.view).observedProgress = progress;
        });
    },
                                ^(AVMutableComposition * _Nullable composition, NSError * _Nullable error) {
        assert(!error);
        [weakSelf processComposition:composition];
        dispatch_async(dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:NO completion:nil];
        });
    });
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

- (void)setupEditorPlayerView __attribute__((objc_direct)) {
    EditorPlayerView *editorPlayerView = self.editorPlayerView;
    editorPlayerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:editorPlayerView];
    [NSLayoutConstraint activateConstraints:@[
        [editorPlayerView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [editorPlayerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [editorPlayerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
    ]];
}

- (void)setupTimelineView __attribute__((objc_direct)) {
    UIView *timelineView = self.timelineView;
    timelineView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:timelineView];
    [NSLayoutConstraint activateConstraints:@[
        [timelineView.topAnchor constraintEqualToAnchor:self.editorPlayerView.bottomAnchor],
        [timelineView.heightAnchor constraintEqualToAnchor:self.editorPlayerView.heightAnchor],
        [timelineView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [timelineView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [timelineView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
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

- (void)processComposition:(AVMutableComposition *)composition __attribute__((objc_direct)) {
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
        if (!loadedSelf) return;
        
        if (AVPlayer *player = loadedSelf.editorPlayerView.player) {
            [player.currentItem cancelPendingSeeks];
            [player replaceCurrentItemWithPlayerItem:playerItem];
        } else {
            AVPlayer *_player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
            weakSelf.editorPlayerView.player = _player;
            [_player release];
        }
    });
    
    [playerItem release];
}

- (EditorPlayerView *)editorPlayerView {
    if (_editorPlayerView) return _editorPlayerView;
    
    EditorPlayerView *editorPlayerView = [[EditorPlayerView alloc] initWithFrame:self.view.bounds];
    
    [_editorPlayerView release];
    _editorPlayerView = [editorPlayerView retain];
    
    return [editorPlayerView autorelease];
}

- (UIView *)timelineView {
    if (_timelineView) return _timelineView;
    
    UIView *timelineView = [[UIView alloc] initWithFrame:self.view.bounds];
    timelineView.backgroundColor = [[UIColor systemOrangeColor] colorWithAlphaComponent:0.3f];
    
    [_timelineView release];
    _timelineView = [timelineView retain];
    
    return [timelineView autorelease];
}


#pragma mark - PHPickerViewControllerDelegate

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    auto alert = [self presentLoadingAlertController];
    __weak auto weakSelf = self;
    
    _viewModel.get()->appendVideosFromPickerResults(_viewModel, results, ^(NSProgress * _Nonnull progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.progress = progress;
            static_cast<UIProgressView *>(alert.contentViewController.view).observedProgress = progress;
        });
    }, ^(AVMutableComposition * _Nullable composition, NSError * _Nullable error) {
        assert(!error);
        [weakSelf processComposition:composition];
        dispatch_async(dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:NO completion:nil];
        });
    });
}

@end
