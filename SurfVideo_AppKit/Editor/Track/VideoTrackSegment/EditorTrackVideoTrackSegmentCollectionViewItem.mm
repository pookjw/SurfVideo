//
//  EditorTrackVideoTrackSegmentCollectionViewItem.mm
//  SurfVideo_AppKit
//
//  Created by Jinwoo Kim on 5/16/24.
//

#import "EditorTrackVideoTrackSegmentCollectionViewItem.hpp"
#import "NSView+Private.h"

@implementation EditorTrackVideoTrackSegmentCollectionViewItem

+ (NSUserInterfaceItemIdentifier)reuseIdentifier {
    return @"EditorTrackVideoTrackSegmentCollectionViewItem";
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = NSColor.systemPinkColor;
}

@end
