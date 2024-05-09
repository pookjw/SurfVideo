//
//  EditorViewController+Private.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 5/4/24.
//

#import "EditorViewController.hpp"
#import <SurfVideoCore/EditorService.hpp>
#import "EditorViewVisualProvider.hpp"

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface EditorViewController (Private) <EditorViewVisualProviderDelegate>
@property (retain, readonly, nonatomic) EditorPlayerViewController *playerViewController;
@property (retain, readonly, nonatomic) EditorTrackViewController *trackViewController;
@property (retain, readonly, nonatomic) EditorService *editorService;
@end

NS_ASSUME_NONNULL_END
