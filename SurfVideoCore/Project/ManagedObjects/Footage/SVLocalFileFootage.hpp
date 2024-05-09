//
//  SVLocalFileFootage.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/25/24.
//

#import <SurfVideoCore/SVFootage.hpp>

NS_ASSUME_NONNULL_BEGIN

@interface SVLocalFileFootage : SVFootage
@property (copy, nonatomic) NSString * _Nullable fileName;
@property (retain, nonatomic) NSData *digestSHA256;
@end

NS_ASSUME_NONNULL_END
