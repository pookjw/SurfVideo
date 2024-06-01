//
//  ImmersiveView+Requests.swift
//  SurfVideo_UIKit
//
//  Created by Jinwoo Kim on 6/2/24.
//

#if os(visionOS)

extension ImmersiveView {
    @MainActor final class Requests {
        var toBeAddedEffectComponents: [EffectComponent] = []
        var toBeRemovedEffectComponents: [EffectComponent] = []
        var tasksByEffectComponent: [EffectComponent: Task<Void, Never>] = [:]
    }
}

#endif
