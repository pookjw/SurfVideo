//
//  SVNSValueValueTransformer.h
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/21/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface SVNSValueValueTransformer : NSValueTransformer
@property (class, readonly, nonatomic) NSValueTransformerName name;
@end

NS_ASSUME_NONNULL_END
