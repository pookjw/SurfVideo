//
//  EditorViewModel.hpp
//  SurfVideo
//
//  Created by Jinwoo Kim on 12/2/23.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <memory>
#import <variant>
#import "SVVideoProject.hpp"

NS_ASSUME_NONNULL_BEGIN

class EditorViewModel {
public:
    EditorViewModel(std::variant<NSSet<NSUserActivity *> *, SVVideoProject *> initialData);
    ~EditorViewModel();
    EditorViewModel(const EditorViewModel&) = delete;
    EditorViewModel& operator=(const EditorViewModel&) = delete;
    
    void initialize(std::shared_ptr<EditorViewModel> ref, void (^completionHandler)(NSError * _Nullable error));
    AVMutableComposition *_composition;
private:
    dispatch_queue_t _queue;
    std::variant<NSSet<NSUserActivity *> *, SVVideoProject *> _initialData;
    SVVideoProject *_videoProject;
    
    void setupComposition(SVVideoProject *videoProject, void (^completionHandler)(NSError * _Nullable error));
};

NS_ASSUME_NONNULL_END
