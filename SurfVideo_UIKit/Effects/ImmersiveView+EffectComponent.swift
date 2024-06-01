//
//  ImmersiveView+EffectComponent.swift
//  SurfVideo_UIKit
//
//  Created by Jinwoo Kim on 6/2/24.
//

#if os(visionOS)

import Foundation
import RealityKit
import CoreMedia

extension ImmersiveView {
    struct EffectComponent: Component, Hashable {
        let immersiveEffect: ImmersiveEffect
        let requestID: UUID
        let duration: CMTime
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(requestID)
        }
    }
}

#endif
