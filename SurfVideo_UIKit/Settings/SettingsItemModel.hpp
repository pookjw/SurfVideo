//
//  SettingsItemModel.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/11/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, SettingsItemModelType) {
    SettingsItemModelTypeCleanupUnusedFootages,
    SettingsItemModelTypeDeveloperX,
    SettingsItemModelTypeDeveloperGitHub,
};

__attribute__((objc_direct_members))
@interface SettingsItemModel : NSObject
@property (assign, readonly, nonatomic) SettingsItemModelType type;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithType:(SettingsItemModelType)type;
@end

NS_ASSUME_NONNULL_END
