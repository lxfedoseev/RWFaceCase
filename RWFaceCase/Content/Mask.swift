//
//  Mask.swift
//  RWFaceCase
//
//  Created by Alex Fedoseev on 12.02.2019.
//  Copyright © 2019 Razeware. All rights reserved.
//

import ARKit
import SceneKit

enum MaskType: Int {
    case basic
    case painted
    case zombie
}

class Mask: SCNNode {
    
    init(geometry: ARSCNFaceGeometry, maskType: MaskType) {
        super.init()
        self.geometry = geometry
        self.swapMaterials(maskType: maskType)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }
    
    // MARK: Materials Setup
    func swapMaterials(maskType: MaskType) {
        // 1
        guard let material = geometry?.firstMaterial! else { return }
        material.lightingModel = .physicallyBased
        // 2
        // Reset materials
        material.diffuse.contents = nil
        material.normal.contents = nil
        material.transparent.contents = nil
        // 3
        switch maskType {
        case .basic:
            material.lightingModel = .physicallyBased
            material.diffuse.contents = UIColor(red: 0.0,
                                                green: 0.68,
                                                blue: 0.37,
                                                alpha: 1)
        case .painted:
            material.diffuse.contents =
            "Models.scnassets/Masks/Painted/Diffuse.png"
            material.normal.contents =
            "Models.scnassets/Masks/Painted/Normal_v1.png"
            material.transparent.contents =
            "Models.scnassets/Masks/Painted/Transparency.png"
        case .zombie:
            material.diffuse.contents =
            "Models.scnassets/Masks/Zombie/Diffuse.png"
            material.normal.contents =
            "Models.scnassets/Masks/Zombie/Normal_v1.png"
        }
    }
    
    // Tag: ARFaceAnchor Update
    func update(withFaceAnchor anchor: ARFaceAnchor) {
        let faceGeometry = geometry as! ARSCNFaceGeometry
        faceGeometry.update(from: anchor.geometry)
    }
}
