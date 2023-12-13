//
//  EditorTrackViewModel.mm
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/13/23.
//

#import "EditorTrackViewModel.hpp"

EditorTrackViewModel::EditorTrackViewModel(std::shared_ptr<EditorViewModel> editorViewModel) : _editorViewModel(editorViewModel) {
    
}

EditorTrackViewModel::~EditorTrackViewModel() {
    [_composition release];
}

AVComposition * _Nullable EditorTrackViewModel::getComposition() {
    assert([NSThread isMainThread]);
    return _composition;
}

void EditorTrackViewModel::setComposition(AVComposition * _Nullable composition) {
    assert([NSThread isMainThread]);
    
    [_composition release];
    _composition = [composition copy];
}
