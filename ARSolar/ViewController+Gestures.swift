//
//  ViewController+Gestures.swift
//  ARSolar
//
//  Created by Yichao Wu on 2018/6/16.
//  Copyright © 2018年 Yichao Wu. All rights reserved.
//

import ARKit

extension ViewController {
    func addGestures() {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinchGesture(_:)))
        self.sceneView.addGestureRecognizer(pinch)
    }
    
    @objc func pinchGesture(_ sender: UIPinchGestureRecognizer) {
        if solarSceneLoaded {
            self.scale *= sender.scale
            self.scaleNode(self.solarGroupNode, self.scale)
            sender.scale = 1
        }
    }
    
    func scaleNode(_ node: SCNNode, _ scale: CGFloat) {
        node.scale = SCNVector3(scale, scale, scale)
        for child in node.childNodes {
            scaleNode(child, scale)
        }
    }
}
