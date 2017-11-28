//
//  GLOscilloscopeView.swift
//  AudioTest
//
//  Created by Dan Weston on 11/27/17.
//  Copyright © 2017 moovel-NA. All rights reserved.
//

import Foundation
import GLKit

public class GLOscilloscopeView : NSObject, GLKViewDelegate {
    
    public var gldataBuffer: Array<Float>? = nil
    public var glamplitudeCorrection = CGFloat(1000.0)
    var pointArray = [CGPoint](repeating: CGPoint(), count: 512)
    
    public func glconvertToPointsInRect(_ rect: CGRect) {
        guard let inData = gldataBuffer else {return}
        let cgwidth = rect.width
        let cgheight = rect.height
        let inDataCGFloat = inData.map{CGFloat($0)}
        
        let stride = max(1, inData.count / 512)
        var pointIndex = 0
        
        // convert array of floats to array of CGPoint
        for (index, element) in inDataCGFloat.enumerated() {
            // we only want every nth element of the source array,
            // typically we are using less than all of the data points so that our performance won't suck
            if index % stride != 0 {
                continue
            }
            
            if pointIndex >= pointArray.count {
                break
            }
            
            // add some amplitude
            let ampedUp = element * glamplitudeCorrection
            //  add the offset to put 0 at the midpoint, vertically, in the window
            let y = ampedUp + (cgheight/2.0)
            // now figure the x coord
            let x = CGFloat(pointIndex) * (cgwidth/512)
            pointArray[pointIndex] = CGPoint(x: Double(x), y: Double(y))
            pointIndex = pointIndex + 1
        }
    }
    
    public func glkView(_ view: GLKView, drawIn rect: CGRect) {
        print("gl delegate called")
    }
}
