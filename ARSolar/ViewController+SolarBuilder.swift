//
//  ViewController+SolarBuilder.swift
//  ARSolar
//
//  Created by Yichao Wu on 2018/6/16.
//  Copyright © 2018年 Yichao Wu. All rights reserved.
//

import ARKit
import SceneKit

private let log = Log()

extension ViewController {
    
    func addSolar(solarPosition: float3) {
        log.info("Start loading solar system")
        displayObjectLoadingUI()
        DispatchQueue.global(qos: .background).async {
            
            self.addBasicNode()
            self.addOtherNode()
            self.resetSceneLight()
            
            self.updateSelfRotation()
            self.updateOrbitRotation()
            
            DispatchQueue.main.async {
                self.timestamp = Date().timeIntervalSince1970
                self.dispatchTimer(timeInterval: 1.0, handler: { (timer) in
                    self.updateTime()
                })
                self.labelView.isHidden = false
                self.btnAdd.isHidden = true
                self.solarGroupNode.simdPosition = solarPosition
                self.sceneView.scene.rootNode.addChildNode(self.solarGroupNode)
                self.hideObjectLoadingUI()
                self.solarSceneLoaded = true
                log.info("Finish loading.")
            }
        }
        
    }
    
    // Add all stars to the solarGroupNode
    func addBasicNode() {
        StarLoader.shared.loadAllStars(withMode: .normal)
        let solarGroupNode = SCNNode()
        let earthGroupNode = SCNNode()
        let saturnGroupNode = SCNNode()
        self.solarGroupNode = solarGroupNode
        self.earthGroupNode = earthGroupNode
        self.saturnGroupNode = saturnGroupNode
        self.stars = [Star]()
        self.orbitNodeArray = [OrbitNode]()
        
        let realOrbitPosArray = Physics.shared.getCurrentObitPos()
        for i in 0..<StarLoader.shared.loadedStars.count {
            let star = StarLoader.shared.loadedStars[i]
            self.stars.append(star)
            
            let orbitAngle = realOrbitPosArray[i]
            star.simdPosition = self.calRelativePos(origin: float3(0,0,0), radian: orbitAngle, orbitRadius: star.orbitRadius)
            let orbitNode = OrbitNode(withRadius: star.orbitRadius, andPeriod: star.orbitPeriod)
            
            switch star.name {
            case "sun":
                // sun don't have a orbit
                solarGroupNode.addChildNode(star)
            case "earth":
                orbitNode.addChildNode(earthGroupNode)
                earthGroupNode.addChildNode(star)
                star.simdPosition = float3(0, 0, 0)
                earthGroupNode.simdPosition = self.calRelativePos(origin: float3(0,0,0), radian: orbitAngle, orbitRadius: star.orbitRadius)
                self.orbitNodeArray.append(orbitNode)
                solarGroupNode.addChildNode(orbitNode)
            case "moon":
                orbitNode.addChildNode(star)
                earthGroupNode.addChildNode(orbitNode)
                self.orbitNodeArray.append(orbitNode)
            case "saturn":
                orbitNode.addChildNode(saturnGroupNode)
                saturnGroupNode.addChildNode(star)
                star.simdPosition = float3(0, 0, 0)
                saturnGroupNode.simdPosition = self.calRelativePos(origin: float3(0,0,0), radian: orbitAngle, orbitRadius: star.orbitRadius)
                self.orbitNodeArray.append(orbitNode)
                solarGroupNode.addChildNode(orbitNode)
            default:
                orbitNode.addChildNode(star)
                self.orbitNodeArray.append(orbitNode)
                solarGroupNode.addChildNode(orbitNode)
            }
        }
    }
    
    // Add other node of the scene
    // such as the orbit indicator, the cloud of Earth, the halo of Sun
    // the loop of Saturn
    func addOtherNode() {
        // orbit indicator
        for orbitNode in self.orbitNodeArray {
            let diameter = CGFloat(orbitNode.orbitRadius * 2)
            let orbitIndicatorNode = SCNNode()
            orbitIndicatorNode.opacity = 0.4
            orbitIndicatorNode.geometry = SCNBox(width: diameter, height: 0, length: diameter, chamferRadius: 0)
            orbitIndicatorNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "orbit")
            orbitIndicatorNode.geometry?.firstMaterial?.diffuse.mipFilter = .linear
            orbitIndicatorNode.rotation = SCNVector4(0, 1, 0, Double.pi*2)
            orbitIndicatorNode.geometry?.firstMaterial?.lightingModel = .constant
            
            orbitNode.parent?.addChildNode(orbitIndicatorNode)
        }
        
        // cloud of earth
        let cloudsNode = SCNNode()
        let earth = StarLoader.shared.earth!
        cloudsNode.geometry = SCNSphere(radius: earth.radius * 6/5)
        cloudsNode.opacity = 0.5
        cloudsNode.geometry?.firstMaterial?.transparent.contents = UIImage(named: "clouds_transparency")
        cloudsNode.geometry?.firstMaterial?.transparencyMode = .rgbZero
        earth.addChildNode(cloudsNode)
        
        // halo of sun
        let sunHaloNode = SCNNode()
        self.sunHaloNode = sunHaloNode
        let sun = StarLoader.shared.sun!
        sunHaloNode.opacity = 0.2
        sunHaloNode.geometry = SCNPlane(width: sun.radius*10, height: sun.radius*10)
        sunHaloNode.rotation = SCNVector4(1, 0, 0, 0 * Double.pi / 180)
        sunHaloNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "sun_halo")
        sunHaloNode.geometry?.firstMaterial?.lightingModel = .constant
        sunHaloNode.geometry?.firstMaterial?.writesToDepthBuffer = false
        solarGroupNode.addChildNode(sunHaloNode)
        
        // the loop of saturn
        let saturnLoopNode = SCNNode()
        let saturn = StarLoader.shared.saturn!
        saturnLoopNode.opacity = 0.4
        let saturnRadius = saturn.radius
        let saturnLoopWidth = 0.6 * saturnRadius / 0.12
        saturnLoopNode.geometry = SCNBox(width: saturnLoopWidth, height: 0, length: saturnLoopWidth, chamferRadius: 0)
        saturnLoopNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "saturn_loop")
        saturnLoopNode.geometry?.firstMaterial?.diffuse.mipFilter = .linear
        saturnLoopNode.rotation = SCNVector4(-0.5, -1, 0, Double.pi*0.5)
        saturnLoopNode.geometry?.firstMaterial?.lightingModel = .constant
        self.saturnGroupNode.addChildNode(saturnLoopNode)
    }
    
    // Reset the light effect in the scene
    // to give a impression that the sun light the scene
    func resetSceneLight() {
        let sun = StarLoader.shared.sun!
        let lightNode = SCNNode()
        let light = SCNLight()
        light.color = UIColor.black
        light.type = .omni
        // TODO: need fix magic number
        light.attenuationStartDistance = 19
        light.attenuationEndDistance = 21
        lightNode.light = light
        sun.addChildNode(lightNode)
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1
        lightNode.light?.color = UIColor.white
        self.sunHaloNode.opacity = 0.5
        SCNTransaction.commit()
    }
    
    func updateOrbitRotation() {
        if self.orbitNodeArray.isEmpty {
            return
        }
        for orbitNode in orbitNodeArray {
            let rotationSpeed = (360.0/(orbitNode.orbitPeriod*24*60*60))/180*Double.pi*speed
            orbitNode.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: CGFloat(rotationSpeed), z: 0, duration: 1)), forKey: "rotation")
        }
    }
    
    func updateSelfRotation() {
        if self.stars.isEmpty {
            return
        }
        for star in self.stars {
            let rotationSpeed = (360.0/(star.rotationPeriod*24*60*60))/180*Double.pi*speed
            star.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: CGFloat(rotationSpeed), z: 0, duration: 1)), forKey: "rotation")
        }
    }
    
    public func dispatchTimer(timeInterval: Double, handler: @escaping (DispatchSourceTimer?)->()) {
        timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.main)
        timer.schedule(deadline: .now(), repeating: timeInterval)
        timer.setEventHandler {
            DispatchQueue.main.async {
                handler(self.timer)
            }
        }
        timer.resume()
    }
    
    func updateTime() {
        let dFormatter = DateFormatter()
        self.timestamp += speed
        dFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        let date = Date(timeIntervalSince1970: timestamp)
        timeLabel.text = dFormatter.string(from: date)
    }
    
    func calRelativePos(origin: float3, radian: Double, orbitRadius: Double) -> float3 {
        let x = orbitRadius * cos(radian)
        let z = -orbitRadius * sin(radian)
        let relativePos = float3(Float(x), 0, Float(z))
        return relativePos + origin
    }
    
    
}
