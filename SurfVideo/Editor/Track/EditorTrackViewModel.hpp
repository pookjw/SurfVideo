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
#import "EditorTrackSectionModel.hpp"
#import "EditorTrackItemModel.hpp"

NS_ASSUME_NONNULL_BEGIN

class EditorTrackViewModel {
public:
    EditorTrackViewModel(std::shared_ptr<EditorViewModel> editorViewModel,
                         UICollectionViewDiffableDataSource<EditorTrackSectionModel *, EditorTrackItemModel *> *dataSource);
    ~EditorTrackViewModel();
    EditorTrackViewModel(const EditorTrackViewModel&) = delete;
    EditorTrackViewModel& operator=(const EditorTrackViewModel&) = delete;
    
    void updateComposition(std::shared_ptr<EditorTrackViewModel> ref,
                           AVComposition * _Nullable composition,
                           void (^ _Nullable completionHandler)());
private:
    std::shared_ptr<EditorViewModel> _editorViewModel;
    dispatch_queue_t _queue;
    UICollectionViewDiffableDataSource<EditorTrackSectionModel *, EditorTrackItemModel *> *_dataSource;
    AVComposition *_composition;
};

NS_ASSUME_NONNULL_END
