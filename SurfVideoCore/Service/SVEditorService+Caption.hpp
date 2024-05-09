//
//  SVEditorService+Caption.h
//  SurfVideo
//
//  Created by Jinwoo Kim on 3/1/24.
//

#import <SurfVideoCore/SVEditorService.hpp>

NS_ASSUME_NONNULL_BEGIN

@interface SVEditorService (Caption)
- (void)appendCaptionWithAttributedString:(NSAttributedString *)attributedString completionHandler:(EditorServiceCompletionHandler)completionHandler;

// kCMTimeInvalid will not update time
- (void)editCaption:(SVEditorRenderCaption *)caption attributedString:(NSAttributedString *)attributedString startTime:(CMTime)startTime endTime:(CMTime)endTime completionHandler:(EditorServiceCompletionHandler)completionHandler;

- (void)removeCaption:(SVEditorRenderCaption *)caption completionHandler:(EditorServiceCompletionHandler)completionHandler;
@end

NS_ASSUME_NONNULL_END
