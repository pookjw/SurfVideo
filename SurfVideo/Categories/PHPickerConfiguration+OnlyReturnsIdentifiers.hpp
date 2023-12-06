//
//  PHPickerConfiguration+OnlyReturnsIdentifiers.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/6/23.
//

#import <PhotosUI/PhotosUI.h>

NS_ASSUME_NONNULL_BEGIN

@interface PHPickerConfiguration (OnlyReturnsIdentifiers)
@property (nonatomic, setter=set_sv_onlyReturnsIdentifiers:, direct) BOOL sv_onlyReturnsIdentifiers;
@end

NS_ASSUME_NONNULL_END
