//
//  Entity+Sphere.swift
//  Effects
//
//  Created by Jinwoo Kim on 5/30/24.
//

import RealityKit
import CoreGraphics

extension Entity {
    static func metalicSphere(
        sphereRadius: Float = 0.15 * .random(in: (0.2...0.7)),
        sceneFrame: BoundingBox
    ) -> Entity {
        let sphereEntity: ModelEntity = .init(
            mesh: .generateSphere(radius: sphereRadius),
            materials: [
                metallicSphereMeterial()
            ]
        )
        
        let shape: ShapeResource = .generateSphere(radius: sphereRadius)
        
        sphereEntity.components.set(CollisionComponent(shapes: [shape], isStatic: true))
        
        var physics: PhysicsBodyComponent = .init(
            shapes: [shape],
            density: 1_000
        )
        
        physics.isAffectedByGravity = true
        
        sphereEntity.components.set(physics)
        
        sphereEntity.components.set(HoverEffectComponent())
        
        sphereEntity.position = .init(
            x: sceneFrame.min.x + .random(in: 0.0..<sceneFrame.extents.x),
            y: sceneFrame.max.y + .random(in: 2.0...3.0),
            z: sceneFrame.min.z - .random(in: 1.0...2.0)
        )
        
        return sphereEntity
    }
}

private func metallicSphereMeterial(
    hue: CGFloat = .random(in: (0.0)...(1.0))
) -> PhysicallyBasedMaterial {
    var material: PhysicallyBasedMaterial = .init()
    
    let color: RealityKit.Material.Color = .init(
        hue: hue,
        saturation: .random(in: (0.5)...(1.0)),
        brightness: 0.9,
        alpha: 1.0
    )
    
    material.baseColor = .init(tint: color, texture: nil)
    material.metallic = 1.0
    material.roughness = 0.5
    material.clearcoat = 1.0
    material.clearcoatRoughness = 0.1
    
    return material
}
