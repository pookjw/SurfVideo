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
    EditorViewModel(std::variant<NSSet<NSUserActivity *> *, SVVideoProject *> videoProjectVariant);
    ~EditorViewModel();
    EditorViewModel(const EditorViewModel&) = delete;
    EditorViewModel& operator=(const EditorViewModel&) = delete;
    
    void initialize(std::shared_ptr<EditorViewModel> ref, void (^progressHandler)(NSProgress *progress), void (^completionHandler)(AVMutableComposition * _Nullable composition, NSError * _Nullable error));
private:
    dispatch_queue_t _queue;
    std::variant<NSSet<NSUserActivity *> *, SVVideoProject *> _videoProjectVariant;
    
    void videoProjectFromVarient(std::variant<NSSet<NSUserActivity *> *, SVVideoProject *> initialData, void (^completionHandler)(SVVideoProject * _Nullable videoProject, NSError * _Nullable error));
    void composition(SVVideoProject *videoProject, void (^progressHandler)(NSProgress *progress), void (^completionHandler)(AVMutableComposition * _Nullable composition, NSError * _Nullable error));
};

NS_ASSUME_NONNULL_END
