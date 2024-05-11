//
//  EditorTrackViewController.mm
//  SurfVideo_AppKit
//
//  Created by Jinwoo Kim on 5/11/24.
//

#import "EditorTrackViewController.hpp"
#import "NSView+Private.h"

__attribute__((objc_direct_members))
@interface EditorTrackViewController ()

@end

@implementation EditorTrackViewController

- (instancetype)initWithEditorService:(SVEditorService *)editorService {
    if (self = [super initWithNibName:nil bundle:nil]) {
        
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = NSColor.systemPinkColor;
}

@end
