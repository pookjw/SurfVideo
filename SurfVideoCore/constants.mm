//
//  constants.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import <SurfVideoCore/constants.hpp>

NSErrorDomain const SurfVideoErrorDomain = @"SurfVideoErrorDomain";

NSString * const EditorSceneUserActivityType = @"EditorSceneUserActivityType";
NSString * const EditorSceneUserActivityVideoProjectURIRepresentationKey = @"EditorSceneUserActivityVideoProjectURIRepresentationKey";

#if TARGET_OS_VISION
NSString * const ImmersiveEffectSceneUserActivityType = @"ImmersiveEffectSceneUserActivityType";
#endif
