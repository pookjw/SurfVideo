//
//  main.mm
//  SurfVideo_AppKit
//
//  Created by Jinwoo Kim on 5/10/24.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.hpp"

int main(int argc, const char * argv[]) {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    NSApplication *application = [NSApplication sharedApplication];
    AppDelegate *delegate = [AppDelegate new];
    
    application.delegate = delegate;
    
    [application run];
    [delegate release];
    
    [pool release];
    
    return EXIT_SUCCESS;
}
