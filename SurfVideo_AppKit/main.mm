//
//  main.mm
//  SurfVideo_AppKit
//
//  Created by Jinwoo Kim on 5/10/24.
//

#import <Cocoa/Cocoa.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        [NSUserDefaults.standardUserDefaults setBool:YES forKey:@"NSDebugCollectionView"];
        NSApplicationMain(argc, argv);
    }
}
