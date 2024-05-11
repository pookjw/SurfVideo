//
//  EditorTrackViewController.hpp
//  SurfVideo_AppKit
//
//  Created by Jinwoo Kim on 5/11/24.
//

#import <Cocoa/Cocoa.h>
#import <SurfVideoCore/SVEditorService.hpp>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorTrackViewController : NSViewController
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithEditorService:(SVEditorService *)editorService;
@end

NS_ASSUME_NONNULL_END
