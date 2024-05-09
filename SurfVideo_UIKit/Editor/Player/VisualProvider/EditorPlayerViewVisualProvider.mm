//
//  EditorPlayerViewVisualProvider.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 5/7/24.
//

#import "EditorPlayerViewVisualProvider.hpp"

@implementation EditorPlayerViewVisualProvider

- (instancetype)initWithPlayerViewController:(EditorPlayerViewController *)playerViewController {
    if (self = [super init]) {
        _playerViewController = playerViewController;
    }
    
    return self;
}

- (void)setPlayer:(AVPlayer *)player {
    
}

- (AVPlayer *)player {
    return nil;
}

- (void)playerViewController_viewDidLoad {
    
}

- (void)playerCurrentTimeDidChange:(CMTime)currentTime {
    
}

@end
