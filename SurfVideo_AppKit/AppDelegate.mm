//
//  AppDelegate.mm
//  SurfVideo_AppKit
//
//  Created by Jinwoo Kim on 5/10/24.
//

#import "AppDelegate.hpp"
#import "SVNSApplication.hpp"

@interface AppDelegate ()
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [SVNSApplication.sharedApplication makeProjectsWindowAndMakeKey];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

@end
