//
//  ProjectsViewController.hpp
//  SurfVideo_AppKit
//
//  Created by Jinwoo Kim on 5/10/24.
//

#import <Cocoa/Cocoa.h>
#import <PhotosUI/PhotosUI.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface ProjectsViewController : NSViewController
- (void)didFinishPicking:(NSArray<PHPickerResult *> *)results;
@end

NS_ASSUME_NONNULL_END
