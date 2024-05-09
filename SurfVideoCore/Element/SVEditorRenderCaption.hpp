//
//  SVEditorRenderCaption.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 2/21/24.
//

#import <SurfVideoCore/SVEditorRenderElement.hpp>
#import <CoreData/CoreData.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface SVEditorRenderCaption : SVEditorRenderElement
@property (copy, readonly, nonatomic) NSAttributedString *attributedString;
@property (assign, readonly, nonatomic) CMTime startTime;
@property (assign, readonly, nonatomic) CMTime endTime;
@property (copy, readonly, nonatomic) NSUUID *captionID;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithAttributedString:(NSAttributedString *)attributedString startTime:(CMTime)startTime endTime:(CMTime)endTime captionID:(NSUUID *)captionID NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END
