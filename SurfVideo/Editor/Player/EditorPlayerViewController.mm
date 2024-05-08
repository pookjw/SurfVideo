//
//  EditorPlayerViewController.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/28/24.
//

#import "EditorPlayerViewController.hpp"
#import "EditorPlayerViewController+Private.h"
#import "EditorPlayerViewVisualProviderReality.hpp"
#import "EditorPlayerViewVisualProviderIOS.hpp"
#import <TargetConditionals.h>

__attribute__((objc_direct_members))
@interface EditorPlayerViewController ()
@property (class, readonly, nonatomic) Class visualProviderClass;
@property (retain, readonly, nonatomic) __kindof EditorPlayerViewVisualProvider *visualProvider;
@property (retain, nonatomic) id _Nullable timeObserverToken;
@end

@implementation EditorPlayerViewController

@synthesize visualProvider = _visualProvider;

+ (Class)visualProviderClass {
#if TARGET_OS_VISION
    return [EditorPlayerViewVisualProviderReality class];
#else
    return [EditorPlayerViewVisualProviderIOS class];
#endif
}

- (void)dealloc {
    if (id timeObserverToken = _timeObserverToken) {
        [_visualProvider.player removeTimeObserver:timeObserverToken];
        [timeObserverToken release];
    }
    
    [_visualProvider release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.visualProvider playerViewController_viewDidLoad];
}

- (AVPlayer *)player {
    return self.visualProvider.player;
}

- (void)setPlayer:(AVPlayer *)player {
    __kindof EditorPlayerViewVisualProvider *visualProvider = self.visualProvider;
    
    if (AVPlayer *oldPlayer = visualProvider.player) {
        if (id timeObserverToken = self.timeObserverToken) {
            [oldPlayer removeTimeObserver:timeObserverToken];
        }
    }
    
    self.visualProvider.player = player;
    
    __weak auto weakSelf = self;
    
    self.timeObserverToken = [player addPeriodicTimeObserverForInterval:CMTimeMake(1, 90) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        auto unwrapped = weakSelf;
        if (unwrapped == nil) return;
        
        [unwrapped.visualProvider playerCurrentTimeDidChange:time];
        
        auto delegate = unwrapped.delegate;
        if (delegate != nil) {
            [delegate editorPlayerViewController:unwrapped didChangeCurrentTime:time];
        }
    }];
}

- (__kindof EditorPlayerViewVisualProvider *)visualProvider {
    if (auto visualProvider = _visualProvider) return visualProvider;
    
    Class visualProviderClass = [EditorPlayerViewController visualProviderClass];
    __kindof EditorPlayerViewVisualProvider *visualProvider = [(EditorPlayerViewVisualProvider *)[visualProviderClass alloc] initWithPlayerViewController:self];
    
    _visualProvider = [visualProvider retain];
    return [visualProvider autorelease];
}

@end


@implementation EditorPlayerViewController (Private)

@end
