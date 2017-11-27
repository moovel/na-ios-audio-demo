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
    var pointArray = [CGPoint](repeating: CGPoint(), count: 4096)
    
    func glconvertToPointsInRect(_ rect: CGRect) {
        guard let inData = gldataBuffer else {return}
        let cgwidth = rect.width
        let cgheight = rect.height
        let cgcount = CGFloat(min(inData.count,pointArray.count))
        let inDataCGFloat = inData.map{CGFloat($0)}
        
        // convert array of floats to array of CGPoint
        for (index, element) in inDataCGFloat.enumerated() {
            if index >= pointArray.count {
                break
            }
            
            // add some amplitude
            let ampedUp = element * glamplitudeCorrection
            // first add the offset to put 0 at the midpoint, vertically, in the window
            let y = ampedUp + (cgheight/2.0)
            // now figure the x coord
            let x = CGFloat(index) * (cgwidth/cgcount)
            //pointArray[index].x = x
            //pointArray[index].y = y
            pointArray[index] = CGPoint(x: Double(x), y: Double(y))
        }
    }
    
    public func glkView(_ view: GLKView, drawIn rect: CGRect) {
        print("gl delegate called")
    }
}
