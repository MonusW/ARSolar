//
//  Physics.swift
//  ARSolar
//
//  Created by Yichao Wu on 2018/6/15.
//  Copyright © 2018年 Yichao Wu. All rights reserved.
//

import ARKit

class Physics {
    
    // Index:
    // sun   mercury  venus  earch  moon
    // mars  jupiter  saturn uranus neptune
    // Radius of planet   real unit: km
    let realRadius: [CGFloat] = [695500, 2440,  6051.9, 6378.1, 1738.14,
                                 3398,   71492, 60268,  25559,  24788]

//    let timeAnchor = "2000-01-01 00:00:00"
//    let timestampAnchor: TimeInterval = 946656000
    let timeAnchor = "2018-06-01 00:00:00"
    let timestampAnchor: TimeInterval = 1527782400
    
    // 2000/1/1 00:00:00 position angle of every planet  unit: anglular
    // From https://www.heavens-above.com
//    let orbitPosition = [0, 252.8, 182.3, 100.4, 100,
//                         0, 44.49, 46.3,  216.5, 303.9]
    let orbitPosition = [0, 40.9, 157.7, 250.2, 128.5,
                          270.4, 229.0, 274.5, 29.1, 344.4]
    
    // Period of revolution, unit: day
    let orbitPeriod = [0, 87.7, 224.701, 365.0, 27.32,
                       686.98, 4328.9, 10799.2384, 30778.014, 60191.91456]
    
    // Rotation period,  unit: day
    let rotationPeriod = [25.05, 58.6535, -243.02, 0.9973, 27.32,
                          1.026, 0.41007, 0.4394, 0.7183, 0.6653]
    
    static let shared = Physics()
    
    private var orbigAngleSpeed: [Double]!
    private var rotationAngleSpeed: [Double]!
    
    private init() {
        orbigAngleSpeed = orbitPeriod.map({ (period) -> Double in
            if period == 0 {
                return 0
            } else {
                return 360 / (period*24*60*60)
            }
        })
        rotationAngleSpeed = rotationPeriod.map({ (period) -> Double in
            return  360 / (period*24*60*60)
        })
    }
    
    func getCurrentObitPos() -> [Double] {
        let time = Date()
        return getObitPosition(ofTime: time)
    }
    
    func getObitPosition(ofTime time: Date) -> [Double] {
        let timestampDiff = time.timeIntervalSince1970 - timestampAnchor
        
        var newPos = [Double]()
        for i in 0..<orbitPosition.count {
            let pos = orbitPosition[i] + orbigAngleSpeed[i] * timestampDiff
            newPos.append(pos.toRadian())
        }
        return newPos
    }
    
}

extension Double {
    // Translate an angular to radian
    // return (0-2*PI)
    func toRadian() -> Double {
        var angle = self.truncatingRemainder(dividingBy: 360)
        if angle < 0 {
            angle += 360
        }
        return angle/180 * Double.pi
    }
    // Translate an radian to angular
    // return (0-360)
    func toAngular() -> Double {
        var radian = self.truncatingRemainder(dividingBy: 2 * Double.pi)
        if radian < 0 {
            radian += 2 * Double.pi
        }
        return radian/Double.pi * 180
    }
}
