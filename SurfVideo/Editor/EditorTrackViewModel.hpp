//
//  EditorTrackViewModel.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/13/23.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <memory>
#import "EditorViewModel.hpp"

NS_ASSUME_NONNULL_BEGIN

class EditorTrackViewModel {
public:
    EditorTrackViewModel(std::shared_ptr<EditorViewModel> editorViewModel);
    ~EditorTrackViewModel();
    EditorTrackViewModel(const EditorTrackViewModel&) = delete;
    EditorTrackViewModel& operator=(const EditorTrackViewModel&) = delete;
    
    AVComposition * _Nullable getComposition();
    void setComposition(AVComposition * _Nullable composition);
private:
    std::shared_ptr<EditorViewModel> _editorViewModel;
    AVComposition *_composition;
};

NS_ASSUME_NONNULL_END
