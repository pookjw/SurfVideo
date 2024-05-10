//
//  ProjectsCollectionViewItem.mm
//  SurfVideo_AppKit
//
//  Created by Jinwoo Kim on 5/10/24.
//

#import "ProjectsCollectionViewItem.hpp"
#import "NSView+Private.h"

@implementation ProjectsCollectionViewItem

+ (NSUserInterfaceItemIdentifier)reuseIdentifier {
    return @"ProjectsCollectionViewItem";
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = NSColor.systemCyanColor;
}

@end
