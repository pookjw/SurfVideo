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
#import <AVKit/AVKit.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <TargetConditionals.h>
#import <memory>

OBJC_EXPORT id objc_loadWeakRetained(id *location) __attribute__((__ns_returns_retained__));

__attribute__((objc_direct_members))
@interface EditorViewController ()
@property (retain, readonly, nonatomic) EditorPlayerView *editorPlayerView;
@property (retain, readonly, nonatomic) UIView *timelineView;
@property (assign, nonatomic) std::shared_ptr<EditorViewModel> viewModel;
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
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViewAttibutes];
    [self setupEditorPlayerView];
    [self setupTimelineView];
    
    auto viewModel = _viewModel;
    auto editorPlayerView = self.editorPlayerView;
    
    viewModel.get()->initialize(viewModel, ^(NSError * _Nullable error) {
        assert(!error);
        AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:_viewModel.get()->_composition];
        AVPlayer *player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
        [playerItem release];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            editorPlayerView.player = player;
        });
        
        [player release];
    });
}

- (void)commonInit_EditorViewController __attribute__((objc_direct)) {
    UINavigationItem *navigationItem = self.navigationItem;
    navigationItem.title = @"Editor";
    navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    
    NSMutableArray<UIBarButtonItem *> *trailingBarButtomItems = [NSMutableArray<UIBarButtonItem *> new];
    
    id weakRef = nil;
    objc_storeWeak(&weakRef, self);
    
#if TARGET_OS_VISION
    
#else
    UIAction *dismissAction = [UIAction actionWithTitle:@"Done" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        auto loaded = static_cast<EditorViewController * _Nullable>(objc_loadWeakRetained(const_cast<id *>(&weakRef)));
        if (!loaded) return;
        [loaded dismissViewControllerAnimated:YES completion:nil];
        [loaded release];
    }];
    UIBarButtonItem *dismissBarButtonItem = [[UIBarButtonItem alloc] initWithPrimaryAction:dismissAction];
    [trailingBarButtomItems addObject:dismissBarButtonItem];
    [dismissBarButtonItem release];
#endif
    
    auto trailingItemGroups = static_cast<NSMutableArray<UIBarButtonItemGroup *> *>([navigationItem.trailingItemGroups mutableCopy]);
    UIBarButtonItemGroup *trailingItemGroup = [[UIBarButtonItemGroup alloc] initWithBarButtonItems:trailingBarButtomItems representativeItem:nil];
    [trailingBarButtomItems release];
    [trailingItemGroups addObject:trailingItemGroup];
    [trailingItemGroup release];
    navigationItem.trailingItemGroups = trailingItemGroups;
    [trailingItemGroups release];
    
    //
    
#if TARGET_OS_VISION
    // MRUIOrnamentsItem
    id mrui_ornamentsItem = reinterpret_cast<id (*) (id, SEL)>(objc_msgSend) (self, NSSelectorFromString (@"mrui_ornamentsItem"));
    EditorMenuOrnamentViewController *menuOrnamentViewController = [EditorMenuOrnamentViewController new];
    id ornament = reinterpret_cast<id (*) (id, SEL, id)>(objc_msgSend)([NSClassFromString(@"MRUIPlatterOrnament") alloc], NSSelectorFromString(@"initWithViewController:"), menuOrnamentViewController);
    [menuOrnamentViewController release];
    
    reinterpret_cast<void (*) (id, SEL, CGSize)>(objc_msgSend)(ornament, NSSelectorFromString(@"setPreferredContentSize:"), CGSizeMake(400.f, 400.f));
    reinterpret_cast<void (*) (id, SEL, CGPoint)>(objc_msgSend)(ornament, NSSelectorFromString(@"setContentAnchorPoint:"), CGPointMake(0.f, 0.5f));
    reinterpret_cast<void (*) (id, SEL, CGPoint)>(objc_msgSend)(ornament, NSSelectorFromString(@"setSceneAnchorPoint:"), CGPointMake(1.f, 0.5f));
    reinterpret_cast<void (*) (id, SEL, CGFloat)>(objc_msgSend)(ornament, NSSelectorFromString(@"_setZOffset:"), 100.f);
    reinterpret_cast<void (*) (id, SEL, id)>(objc_msgSend)(mrui_ornamentsItem, NSSelectorFromString(@"setOrnaments:"), @[ornament]);
    [ornament release];
#endif
}

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

@end
