//
//  SettingsSectionModel.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/11/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, SettingsSectionModelType) {
    SettingsSectionModelTypeMiscellaneous,
    SettingsSectionModelTypeAbout
};

__attribute__((objc_direct_members))
@interface SettingsSectionModel : NSObject
@property (assign, readonly, nonatomic) SettingsSectionModelType type;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithType:(SettingsSectionModelType)type;
@end

NS_ASSUME_NONNULL_END
