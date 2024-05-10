//
//  EditorWindow.hpp
//  SurfVideo_AppKit
//
//  Created by Jinwoo Kim on 5/11/24.
//

#import <Cocoa/Cocoa.h>
#import <SurfVideoCore/SVVideoProject.hpp>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorWindow : NSWindow
- (instancetype)initWithVideoProject:(SVVideoProject *)videoProject;
@end

NS_ASSUME_NONNULL_END
