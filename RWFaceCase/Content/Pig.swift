//
//  Pig.swift
//  RWFaceCase
//
//  Created by Alex Fedoseev on 13.02.2019.
//  Copyright © 2019 Razeware. All rights reserved.
//

import ARKit
import SceneKit
class Pig: SCNNode {
    let occlusionNode: SCNNode
    init(geometry: ARSCNFaceGeometry) {
        geometry.firstMaterial!.colorBufferWriteMask = []
        occlusionNode = SCNNode(geometry: geometry)
        occlusionNode.renderingOrder = -1
        super.init()
        self.geometry = geometry
        // 1
        guard let url = Bundle.main.url(forResource: "pig",
                                        withExtension: "scn",
                                        subdirectory: "Models.scnassets")
                                        else {
            fatalError("Missing resource")
        }
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
        let faceGeometry = geometry as! ARSCNFaceGeometry
        faceGeometry.update(from: anchor.geometry)
    }
}
