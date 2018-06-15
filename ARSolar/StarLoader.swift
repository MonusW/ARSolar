//
//  StarLoader.swift
//  ARSolar
//
//  Created by Yichao Wu on 2018/6/15.
//  Copyright © 2018年 Yichao Wu. All rights reserved.
//

import Foundation
import ARKit

enum DisplayMode {
    case normal
    case physical
}

class StarLoader {
    
    private(set) var loadedStars = [SCNNode]()
    
    static let shared = StarLoader()
    
    var sun: SCNNode!
    var mercury: SCNNode!
    var venus: SCNNode!
    var earth, moon: SCNNode!
    var mars: SCNNode!
    var jupiter: SCNNode!
    var saturn: SCNNode!
    var uranus: SCNNode!
    var neptune: SCNNode!
    var pluto: SCNNode!
    
    var currentMode: DisplayMode = .normal
    
    var radiusArray: [CGFloat]!
    
    var orbitRadiusArray = [0, 0.4, 0.6, 0.8, 0,
                      1.0, 1.4, 1.68, 1.95, 2.14]
    
    private init() {
        sun = SCNNode()
        mercury = SCNNode()
        venus = SCNNode()
        earth = SCNNode()
        moon = SCNNode()
        mars = SCNNode()
        jupiter = SCNNode()
        saturn = SCNNode()
        uranus = SCNNode()
        neptune = SCNNode()
        
        loadedStars.append(sun)
        loadedStars.append(mercury)
        loadedStars.append(venus)
        loadedStars.append(earth)
        loadedStars.append(moon)
        loadedStars.append(mars)
        loadedStars.append(jupiter)
        loadedStars.append(saturn)
        loadedStars.append(uranus)
        loadedStars.append(neptune)
        
        currentMode = .physical
        self.loadAllStars(withMode: .normal)
    }
    
    func loadAllStars(withMode mode: DisplayMode) {
        if currentMode == mode {
            return
        }
        currentMode = mode
        
        switch mode {
        case .normal:
            radiusArray = [0.25, 0.02, 0.04, 0.05, 0.01,
                           0.03, 0.15, 0.12, 0.09, 0.08]
        case .physical:
            let realRadius = Physics.shared.realRadius
            let max = realRadius.max()! * 2
            print(max)
            radiusArray = realRadius.map({ (r) -> CGFloat in
                return r/max
            })
        }
        let diffuseNameArray: [String] = ["sun", "mercury", "venus", "earth_diffuse", "moon",
                                          "mars", "jupiter", "saturn", "uranus", "neptune"]
        for i in 0..<radiusArray.count {
            let starNode = loadedStars[i]
            starNode.geometry = SCNSphere(radius: radiusArray[i])
            starNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: diffuseNameArray[i])
            starNode.geometry?.firstMaterial?.locksAmbientWithDiffuse = true
            if i > 0 {
                starNode.geometry?.firstMaterial?.shininess = 0.1
                starNode.geometry?.firstMaterial?.specular.intensity = 0.5
            }
        }
        
        sun.geometry?.firstMaterial?.multiply.contents = UIImage(named: "sun")
        sun.geometry?.firstMaterial?.multiply.intensity = 0.5
        sun.geometry?.firstMaterial?.lightingModel = .constant
        sun.geometry?.firstMaterial?.multiply.wrapT = .repeat
        sun.geometry?.firstMaterial?.diffuse.wrapS = .repeat
        sun.geometry?.firstMaterial?.multiply.wrapT = .repeat
        sun.geometry?.firstMaterial?.diffuse.wrapT = .repeat
        
        earth.geometry?.firstMaterial?.emission.contents = UIImage(named: "earth_emissive")
        earth.geometry?.firstMaterial?.specular.contents = UIImage(named: "earch_specular")
        
        moon.geometry?.firstMaterial?.specular.contents = UIColor.gray
        
        for node in saturn.childNodes {
            node.removeFromParentNode()
        }
        
        let saturnLoopNode = SCNNode()
        saturnLoopNode.opacity = 0.4
        let saturnRadius = radiusArray[7]
        let saturnLoopWidth = 0.6 * saturnRadius / 0.12
        saturnLoopNode.geometry = SCNBox(width: saturnLoopWidth, height: 0, length: saturnLoopWidth, chamferRadius: 0)
        saturnLoopNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "saturn_loop")
        saturnLoopNode.geometry?.firstMaterial?.diffuse.mipFilter = .linear
        saturnLoopNode.rotation = SCNVector4(-0.5, -1, 0, Double.pi*0.5)
        saturnLoopNode.geometry?.firstMaterial?.lightingModel = .constant
        saturn.addChildNode(saturnLoopNode)
    }
}
