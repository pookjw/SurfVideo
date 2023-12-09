//
//  ImageUtils.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/9/23.
//

#import <CoreImage/CoreImage.h>

NS_ASSUME_NONNULL_BEGIN

namespace ImageUtils {
    CIImage * aspectFit(CIImage *original, CGSize targetSize);
};

NS_ASSUME_NONNULL_END
