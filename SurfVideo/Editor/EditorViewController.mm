//
//  EditorViewController.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import "EditorViewController.hpp"
#import "EditorViewModel.hpp"
#import "EditorMenuOrnamentViewController.hpp"
#import <AVKit/AVKit.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <TargetConditionals.h>
#import <memory>

OBJC_EXPORT id objc_loadWeakRetained(id *location) __attribute__((__ns_returns_retained__));

__attribute__((objc_direct_members))
@interface EditorViewController ()
@property (retain, readonly, nonatomic) AVPlayerViewController *playerViewController;
@property (assign, nonatomic) std::shared_ptr<EditorViewModel> viewModel;
@end

@implementation EditorViewController
@synthesize playerViewController = _playerViewController;

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
    [_playerViewController release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupPlayerViewController];
    
    _viewModel.get()->initialize(_viewModel, ^(NSError * _Nullable error) {
        assert(!error);
        AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:_viewModel.get()->_composition];
        AVPlayer *player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
        [playerItem release];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.playerViewController.player = player;
            
#if TARGET_OS_VISION
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                [self.playerViewController beginTrimmingWithCompletionHandler:^(BOOL success) {
//                    
//                }];
//            });
#endif
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

- (void)setupPlayerViewController __attribute__((objc_direct)) {
    AVPlayerViewController *playerViewController = self.playerViewController;
    [self addChildViewController:playerViewController];
    
    UIView *contentView = playerViewController.view;
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:contentView];
    [NSLayoutConstraint activateConstraints:@[
        [contentView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [contentView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [contentView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [contentView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
    [playerViewController didMoveToParentViewController:self];
}

- (AVPlayerViewController *)playerViewController {
    if (_playerViewController) return _playerViewController;
    
    AVPlayerViewController *playerViewController = [AVPlayerViewController new];
    playerViewController.entersFullScreenWhenPlaybackBegins = NO;
    
    [_playerViewController release];
    _playerViewController = [playerViewController retain];
    
    return [playerViewController autorelease];
}

@end
