//
//  OrbitNode.swift
//  ARSolar
//
//  Created by Yichao Wu on 2018/6/16.
//  Copyright © 2018年 Yichao Wu. All rights reserved.
//

import ARKit

class OrbitNode: SCNNode {
    
    var orbitRadius: Double
    var orbitPeriod: Double
    
    init(withRadius radius: Double, andPeriod period: Double) {
        self.orbitRadius = radius
        self.orbitPeriod = period
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
