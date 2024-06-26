//
//  main.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.hpp"

int main(int argc, char * argv[]) {
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    
    @autoreleasepool {
        NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.apple.UIKit"];
        
        [userDefaults setObject:@NO forKey:@"MRUIEnableOrnamentWindowDebugVis"];
        [userDefaults setObject:@NO forKey:@"MRUIEnableTextEffectstWindowDebugVis"];
        
        [userDefaults release];
    }
    
    int result = UIApplicationMain(argc, argv, nil, NSStringFromClass(AppDelegate.class));
    [pool release];
    return result;;
}
