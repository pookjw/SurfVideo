//
//  EditorViewController.mm
//  SurfVideo_AppKit
//
//  Created by Jinwoo Kim on 5/11/24.
//

#import "EditorViewController.hpp"
#import "NSView+Private.h"
#import "EditorPlayerViewController.hpp"
#import "EditorTrackViewController.hpp"
#import "NSSplitViewItem+Private.h"
#import <SurfVideoCore/SVEditorService.hpp>

__attribute__((objc_direct_members))
@interface EditorViewController () <EditorPlayerViewControllerDelegate, EditorTrackViewControllerDelegate>
@property (retain, readonly, nonatomic) SVEditorService *editorService;
@property (retain, readonly, nonatomic) NSSplitViewController *splitViewController;
@property (retain, readonly, nonatomic) EditorPlayerViewController *playerViewController;
@property (retain, readonly, nonatomic) NSSplitViewItem *playerSplitViewItem;
@property (retain, readonly, nonatomic) EditorTrackViewController *trackViewController;
@property (retain, readonly, nonatomic) NSSplitViewItem *trackSplitViewItem;
@end

@implementation EditorViewController

@synthesize splitViewController = _splitViewController;
@synthesize playerViewController = _playerViewController;
@synthesize playerSplitViewItem = _playerSplitViewItem;
@synthesize trackViewController = _trackViewController;
@synthesize trackSplitViewItem = _trackSplitViewItem;

- (instancetype)initWithVideoProject:(SVVideoProject *)videoProject {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _editorService = [[SVEditorService alloc] initWithVideoProject:videoProject];
    }
    
    return self;
}

- (void)dealloc {
    [_editorService release];
    [_splitViewController release];
    [_playerViewController release];
    [_playerSplitViewItem release];
    [_trackViewController release];
    [_trackSplitViewItem release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addObservers];
    [self setupSplitViewController];
    [self initializeComposition];
}

- (NSTouchBar *)makeTouchBar {
    return nil;
}

- (void)addObservers __attribute__((objc_direct)) {
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(compositionDidChange:)
                                               name:EditorServiceCompositionDidChangeNotification
                                             object:_editorService];
}

- (void)setupSplitViewController __attribute__((objc_direct)) {
    NSSplitViewController *splitViewController = self.splitViewController;
    
    [splitViewController addSplitViewItem:self.playerSplitViewItem];
    [splitViewController addSplitViewItem:self.trackSplitViewItem];
    
    NSView *contentView = splitViewController.view;
    
    [self addChildViewController:splitViewController];
    
    contentView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self.view addSubview:contentView];
    contentView.frame = self.view.bounds;
}

- (void)initializeComposition __attribute__((objc_direct))  {
    [self.editorService initializeWithProgressHandler:^(NSProgress * _Nonnull progress) {
        
    } completionHandler:EditorServiceCompletionHandlerBlock {
        assert(!error);
    }];
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

- (NSSplitViewController *)splitViewController {
    if (auto splitViewController = _splitViewController) return splitViewController;
    
    NSSplitViewController *splitViewController = [NSSplitViewController new];
    NSSplitView *splitView = splitViewController.splitView;
    
    splitView.vertical = NO;
    splitView.dividerStyle = NSSplitViewDividerStylePaneSplitter;
    
    _splitViewController = [splitViewController retain];
    return [splitViewController autorelease];
}

- (EditorPlayerViewController *)playerViewController {
    if (auto playerViewController = _playerViewController) return playerViewController;
    
    EditorPlayerViewController *playerViewController = [EditorPlayerViewController new];
    playerViewController.delegate = self;
    
    _playerViewController = [playerViewController retain];
    return [playerViewController autorelease];
}

- (NSSplitViewItem *)playerSplitViewItem {
    if (auto playerSplitViewItem = _playerSplitViewItem) return playerSplitViewItem;
    
    NSSplitViewItem *playerSplitViewItem = [NSSplitViewItem splitViewItemWithViewController:self.playerViewController];
    [playerSplitViewItem setMinimumSize:200.];
    
    _playerSplitViewItem = [playerSplitViewItem retain];
    return playerSplitViewItem;
}

- (EditorTrackViewController *)trackViewController {
    if (auto trackViewController = _trackViewController) return trackViewController;
    
    EditorTrackViewController *trackViewController = [[EditorTrackViewController alloc] initWithEditorService:self.editorService];
    trackViewController.delegate = self;
    
    _trackViewController = [trackViewController retain];
    return [trackViewController autorelease];
}

- (NSSplitViewItem *)trackSplitViewItem {
    if (auto trackSplitViewItem = _trackSplitViewItem) return trackSplitViewItem;
    
    NSSplitViewItem *trackSplitViewItem = [NSSplitViewItem splitViewItemWithViewController:self.trackViewController];
    [trackSplitViewItem setMinimumSize:200.];
    
    _trackSplitViewItem = [trackSplitViewItem retain];
    return trackSplitViewItem;
}


#pragma mark - EditorPlayerViewControllerDelegate

- (void)editorPlayerViewController:(EditorPlayerViewController *)editorPlayerViewController didChangeCurrentTime:(CMTime)currentTime {
    [self.trackViewController updateCurrentTime:currentTime];
}


#pragma mark - EditorTrackViewControllerDelegate

- (void)editorTrackViewController:(nonnull EditorTrackViewController *)viewController didEndScrollingWithCurrentTime:(CMTime)currentTime {
    AVPlayer *player = self.playerViewController.player;
    [player pause];
    [player seekToTime:currentTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

- (void)editorTrackViewController:(nonnull EditorTrackViewController *)viewController scrollingWithCurrentTime:(CMTime)currentTime { 
    [self.playerViewController.player seekToTime:currentTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

- (void)editorTrackViewController:(nonnull EditorTrackViewController *)viewController willBeginScrollingWithCurrentTime:(CMTime)currentTime {
    [self.playerViewController.player seekToTime:currentTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

@end
