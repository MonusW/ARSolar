//
//  ViewController.swift
//  ARSolar
//
//  Created by Yichao Wu on 2018/6/13.
//  Copyright © 2018年 Yichao Wu. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

private let log = Log()

class ViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet weak var btnAdd: UIButton!
    var session: ARSession {
        return sceneView.session
    }
    
    var focusSquare = FocusSquare()
    
    let updateQueue = DispatchQueue(label: "serialSceneKitQueue")
    var screenCenter: CGPoint {
        let bounds = sceneView.bounds
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    lazy var statusViewController: StatusViewController = {
        return children.lazy.compactMap({ $0 as? StatusViewController }).first!
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup the sceneView
        sceneView.delegate = self
        session.delegate = self
        sceneView.showsStatistics = true
        
        setupCamera()
        sceneView.scene.rootNode.addChildNode(focusSquare)
        
        statusViewController.restartHandler = { [unowned self] in
            self.restartSession()
        }
        
//        StarLoader.shared.loadAllStars(withMode: .physical)
        
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]

        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.pause()
    }
    
    // MARK: - Restart btn clicked handler
    func restartSession() {
        statusViewController.cancelAllScheduledMessages()
        resetTracking()
    }
    
    func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        for node in sceneView.scene.rootNode.childNodes {
            node.removeFromParentNode()
        }
        sceneView.scene.rootNode.addChildNode(focusSquare)
        
        statusViewController.schedulePlaceObjectMessage(inSeconds: 7.5, messageType: .planeEstimation)
    }
    
    func setupCamera() {
        guard let camera = sceneView.pointOfView?.camera else {
            fatalError("Expected a valid `pointOfView` from the scene.")
        }
        
        camera.wantsHDR = true
    }
    
    var i = 0
    @IBAction func onBtnAddClick(_ sender: UIButton) {
        guard let focusPosition = focusSquare.lastPosition,
            focusSquare.state != .initializing else {
                statusViewController.showMessage("CANNOT PLACE OBJECT\nTry moving left or right.")
                return
        }
        
        addSolar(solarPosition: focusPosition)
    }
    
    func addSolar(solarPosition: float3) {
        displayObjectLoadingUI()
        DispatchQueue.global(qos: .background).async {
            var nodes = [SCNNode]()
            for i in 0..<StarLoader.shared.loadedStars.count {
                let star = StarLoader.shared.loadedStars[i]
                if i == 4 {
                    continue
                }
                if i == 0 {
                    star.simdPosition = solarPosition
                } else {
                    let angles = Physics.shared.getCurrentObitPos()
                    let radian = angles[i]
                    let orbitRadius = StarLoader.shared.orbitRadiusArray[i]
                    star.simdPosition = self.getWorldPosOf(solarPos: solarPosition, radian: radian, orbitRadius: orbitRadius)
                }
                nodes.append(star)
            }
            DispatchQueue.main.async {
                for node in nodes {
                    self.sceneView.scene.rootNode.addChildNode(node)
                }
                self.hideObjectLoadingUI()
            }
        }
    }
    
    func getWorldPosOf(solarPos: float3, radian: Double, orbitRadius: Double) -> float3 {
        let x = orbitRadius * cos(radian)
        let z = -orbitRadius * sin(radian)
        let relativePos = float3(Float(x), 0, Float(z))
        return relativePos + solarPos
    }
    
    
    // MARK: - Focus Square
    
    func updateFocusSquare(isObjectVisible: Bool) {
        if isObjectVisible {
            focusSquare.hide()
        } else {
            focusSquare.unhide()
            statusViewController.scheduleMessage("TRY MOVING LEFT OR RIGHT", inSeconds: 5.0, messageType: .focusSquare)
        }
        // Perform hit testing only when ARKit tracking is in a good state.
        if let camera = session.currentFrame?.camera, case .normal = camera.trackingState,
            let result = self.sceneView.smartHitTest(screenCenter) {
            updateQueue.async {
                self.sceneView.scene.rootNode.addChildNode(self.focusSquare)
                self.focusSquare.state = .detecting(hitTestResult: result, camera: camera)
            }
            statusViewController.cancelScheduledMessage(for: .focusSquare)
        } else {
            updateQueue.async {
                self.focusSquare.state = .initializing
                self.sceneView.pointOfView?.addChildNode(self.focusSquare)
            }
        }
    }
    
    func displayObjectLoadingUI() {
        spinner.startAnimating()
        
        btnAdd.setImage(UIImage(named: "buttonRing"), for: .normal)
        btnAdd.isEnabled = false
    }
    
    func hideObjectLoadingUI() {
        spinner.stopAnimating()
        
        btnAdd.setImage(UIImage(named: "add"), for: .normal)
        btnAdd.setImage(UIImage(named: "addPressed"), for: .highlighted)
        btnAdd.isEnabled = true
    }

}

extension ARSCNView {
    func smartHitTest(_ point: CGPoint,
                      infinitePlane: Bool = false,
                      objectPosition: float3? = nil,
                      allowedAlignments: [ARPlaneAnchor.Alignment] = [.horizontal, .vertical]) -> ARHitTestResult? {
        
        // Perform the hit test.
        let results = hitTest(point, types: [.existingPlaneUsingGeometry, .estimatedVerticalPlane, .estimatedHorizontalPlane])
        
        // 1. Check for a result on an existing plane using geometry.
        if let existingPlaneUsingGeometryResult = results.first(where: { $0.type == .existingPlaneUsingGeometry }),
            let planeAnchor = existingPlaneUsingGeometryResult.anchor as? ARPlaneAnchor, allowedAlignments.contains(planeAnchor.alignment) {
            return existingPlaneUsingGeometryResult
        }
        
        if infinitePlane {
            
            // 2. Check for a result on an existing plane, assuming its dimensions are infinite.
            //    Loop through all hits against infinite existing planes and either return the
            //    nearest one (vertical planes) or return the nearest one which is within 5 cm
            //    of the object's position.
            let infinitePlaneResults = hitTest(point, types: .existingPlane)
            
            for infinitePlaneResult in infinitePlaneResults {
                if let planeAnchor = infinitePlaneResult.anchor as? ARPlaneAnchor, allowedAlignments.contains(planeAnchor.alignment) {
                    if planeAnchor.alignment == .vertical {
                        // Return the first vertical plane hit test result.
                        return infinitePlaneResult
                    } else {
                        // For horizontal planes we only want to return a hit test result
                        // if it is close to the current object's position.
                        if let objectY = objectPosition?.y {
                            let planeY = infinitePlaneResult.worldTransform.translation.y
                            if objectY > planeY - 0.05 && objectY < planeY + 0.05 {
                                return infinitePlaneResult
                            }
                        } else {
                            return infinitePlaneResult
                        }
                    }
                }
            }
        }
        
        // 3. As a final fallback, check for a result on estimated planes.
        let vResult = results.first(where: { $0.type == .estimatedVerticalPlane })
        let hResult = results.first(where: { $0.type == .estimatedHorizontalPlane })
        switch (allowedAlignments.contains(.horizontal), allowedAlignments.contains(.vertical)) {
        case (true, false):
            return hResult
        case (false, true):
            // Allow fallback to horizontal because we assume that objects meant for vertical placement
            // (like a picture) can always be placed on a horizontal surface, too.
            return vResult ?? hResult
        case (true, true):
            if hResult != nil && vResult != nil {
                return hResult!.distance < vResult!.distance ? hResult! : vResult!
            } else {
                return hResult ?? vResult
            }
        default:
            return nil
        }
    }
}
