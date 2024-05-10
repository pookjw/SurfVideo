//
//  SVNSApplication.mm
//  SurfVideo_AppKit
//
//  Created by Jinwoo Kim on 5/10/24.
//

#import "SVNSApplication.hpp"
#import "AppDelegate.hpp"
#import "ProjectsWindow.hpp"

@interface SVNSApplication () {
    AppDelegate *_sv_delegate;
}
@end

@implementation SVNSApplication

+ (SVNSApplication *)sharedApplication {
    __kindof SVNSApplication *sharedApplication = [super sharedApplication];
    
    if (sharedApplication->_sv_delegate == nil) {
        AppDelegate *delegate = [AppDelegate new];
        sharedApplication.delegate = delegate;
        sharedApplication->_sv_delegate = [delegate retain];
        [delegate release];
    }
    
    return sharedApplication;
}

- (void)dealloc {
    [_sv_delegate release];
    [super dealloc];
}

- (ProjectsWindow *)makeProjectsWindowAndMakeKey {
    ProjectsWindow *projectsWindow = [ProjectsWindow new];
    projectsWindow.releasedWhenClosed = NO;
    [projectsWindow makeKeyAndOrderFront:nil];
    
    return [projectsWindow autorelease];
}

- (EditorWindow *)makeEditorWindowAndMakeKeyWithVideoProject:(SVVideoProject *)videoProject {
    EditorWindow *editorWindow = [[EditorWindow alloc] initWithVideoProject:videoProject];
    editorWindow.releasedWhenClosed = NO;
    [editorWindow makeKeyAndOrderFront:nil];
    
    return [editorWindow autorelease];
}

@end
