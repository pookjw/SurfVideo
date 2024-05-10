//
//  SVNSApplication.hpp
//  SurfVideo_AppKit
//
//  Created by Jinwoo Kim on 5/10/24.
//

#import <Cocoa/Cocoa.h>
#import <SurfVideoCore/SVVideoProject.hpp>
#import "ProjectsWindow.hpp"
#import "EditorWindow.hpp"

NS_ASSUME_NONNULL_BEGIN

@interface SVNSApplication : NSApplication
+ (SVNSApplication *)sharedApplication;
- (ProjectsWindow *)makeProjectsWindowAndMakeKey __attribute__((objc_direct));
- (EditorWindow *)makeEditorWindowAndMakeKeyWithVideoProject:(SVVideoProject *)videoProject __attribute__((objc_direct));
@end

NS_ASSUME_NONNULL_END
