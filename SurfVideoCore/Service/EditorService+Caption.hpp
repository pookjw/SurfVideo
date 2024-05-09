//
//  EditorService+Caption.h
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/1/24.
//

#import <SurfVideoCore/EditorService.hpp>

NS_ASSUME_NONNULL_BEGIN

@interface EditorService (Caption)
- (void)appendCaptionWithAttributedString:(NSAttributedString *)attributedString completionHandler:(EditorServiceCompletionHandler)completionHandler;

// kCMTimeInvalid will not update time
- (void)editCaption:(EditorRenderCaption *)caption attributedString:(NSAttributedString *)attributedString startTime:(CMTime)startTime endTime:(CMTime)endTime completionHandler:(EditorServiceCompletionHandler)completionHandler;

- (void)removeCaption:(EditorRenderCaption *)caption completionHandler:(EditorServiceCompletionHandler)completionHandler;
@end

NS_ASSUME_NONNULL_END
