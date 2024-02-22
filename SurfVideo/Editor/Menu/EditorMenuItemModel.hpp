//
//  EditorMenuItemModel.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/23/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, EditorMenuItemModelType) {
    EditorMenuItemModelTypeAddCaption,
    EditorMenuItemModelTypeEditCaption,
    EditorMenuItemModelTypeChangeCaptionTime
};

__attribute__((objc_direct_members))
@interface EditorMenuItemModel : NSObject
@property (assign, nonatomic, readonly) EditorMenuItemModelType type;
@property (nonatomic, readonly) UIImage *image;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithType:(EditorMenuItemModelType)type NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END
