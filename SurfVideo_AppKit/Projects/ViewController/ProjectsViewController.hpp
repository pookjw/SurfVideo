//
//  ProjectsViewController.hpp
//  SurfVideo_AppKit
//
//  Created by Jinwoo Kim on 5/10/24.
//

#import <Cocoa/Cocoa.h>
#import <SurfVideoCore/SVProjectsViewModel.hpp>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface ProjectsViewController : NSViewController
@property (retain, readonly, nonatomic) SVProjectsViewModel *viewModel;
@end

NS_ASSUME_NONNULL_END
