//
//  Glasses.swift
//  RWFaceCase
//
//  Created by Alex Fedoseev on 13.02.2019.
//  Copyright © 2019 Razeware. All rights reserved.
//

import ARKit
import SceneKit

class Glasses: SCNNode {
    
    let occlusionNode: SCNNode
    
    init(geometry: ARSCNFaceGeometry) {
        geometry.firstMaterial!.colorBufferWriteMask = []
        occlusionNode = SCNNode(geometry: geometry)
        occlusionNode.renderingOrder = -1
        super.init()
        addChildNode(occlusionNode)
        
        // 1
        guard let url = Bundle.main.url(forResource: "glasses",
                                        withExtension: "scn",
                                        subdirectory: "Models.scnassets")
            else { fatalError("Missing resource") }
        // 2
        let node = SCNReferenceNode(url: url)!
        node.load()
        // 3
        addChildNode(node)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }
    
    // - Tag: ARFaceAnchor Update
    func update(withFaceAnchor anchor: ARFaceAnchor) {
        let faceGeometry = occlusionNode.geometry as! ARSCNFaceGeometry
        faceGeometry.update(from: anchor.geometry)
    }
}
