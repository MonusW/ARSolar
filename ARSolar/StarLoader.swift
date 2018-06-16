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
    
    private(set) var loadedStars = [Star]()
    
    static let shared = StarLoader()
    
    var sun: Star!
    var mercury: Star!
    var venus: Star!
    var earth, moon: Star!
    var mars: Star!
    var jupiter: Star!
    var saturn: Star!
    var uranus: Star!
    var neptune: Star!
    var pluto: Star!
    
    var currentMode: DisplayMode = .normal
    
    var radiusArray: [CGFloat] = [0.25, 0.02, 0.04, 0.05, 0.01,
                                  0.03, 0.15, 0.12, 0.09, 0.08]
    
    var orbitRadiusArray = [0, 0.4, 0.6, 0.8, 0.1,
                            1.0, 1.4, 1.68, 1.95, 2.14]
    
    private init() {
        sun = Star("sun")
        mercury = Star("mercury")
        venus = Star("venus")
        earth = Star("earth")
        moon = Star("moon")
        mars = Star("mars")
        jupiter = Star("jupiter")
        saturn = Star("saturn")
        uranus = Star("uranus")
        neptune = Star("neptune")
        
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
            starNode.radius = radiusArray[i]
            starNode.orbitPeriod = Physics.shared.orbitPeriod[i]
            starNode.rotationPeriod = Physics.shared.rotationPeriod[i]
            starNode.orbitRadius = orbitRadiusArray[i]
            
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
    }
}
