//
//  Star.swift
//  ARSolar
//
//  Created by Yichao Wu on 2018/6/15.
//  Copyright © 2018年 Yichao Wu. All rights reserved.
//

import ARKit
import SceneKit

class Star: SCNNode {
    
    var radius: CGFloat
    var orbitRadius: Double
    var orbitPeriod: Double
    var rotationPeriod: Double

    init(_ name: String = "") {
        radius = 0
        orbitRadius = 0
        orbitPeriod = 0
        rotationPeriod = 0
        super.init()
        self.name = name
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
