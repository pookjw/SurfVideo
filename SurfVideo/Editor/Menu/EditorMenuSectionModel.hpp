//
//  EditorMenuSectionModel.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/23/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, EditorMenuSectionModelType) {
    EditorMenuSectionModelTypeMain
};

__attribute__((objc_direct_members))
@interface EditorMenuSectionModel : NSObject
@property (assign, nonatomic, readonly) EditorMenuSectionModelType type;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithType:(EditorMenuSectionModelType)type NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END
