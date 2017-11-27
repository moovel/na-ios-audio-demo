//
//  OcciliscopeView.swift
//  AudioTest
//
//  Created by Dan Weston on 11/26/17.
//  Copyright © 2017 moovel-NA. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

class OscilloscopeView : UIView {
 
    public var dataBuffer: Array<Float>? = nil
    public var amplitudeCorrection = CGFloat(1000.0)
    var pointArray = [CGPoint](repeating: CGPoint(), count: 4096)
    
    public func convertToPointsInRect(_ rect: CGRect) {
        guard let inData = dataBuffer else {return}
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
            let ampedUp = element * amplitudeCorrection
            // first add the offset to put 0 at the midpoint, vertically, in the window
            let y = ampedUp + (cgheight/2.0)
            // now figure the x coord
            let x = CGFloat(index) * (cgwidth/cgcount)
            //pointArray[index].x = x
            //pointArray[index].y = y
            pointArray[index] = CGPoint(x: Double(x), y: Double(y))
        }
    }
    
    override func draw(_ rect: CGRect) {
        //print("draw in rect, length: \(dataBuffer?.count ?? 0)")
        guard let inData = dataBuffer else {return}
        self.convertToPointsInRect(rect)
        
        if let context = UIGraphicsGetCurrentContext() {
            context.setLineWidth(1.0)
            context.setShouldAntialias(false)
            context.setFillColor(UIColor.black.cgColor)
            context.beginPath()
            for (index, element) in pointArray.enumerated() {
                if index == 0 {
                    context.move(to: element)
                }
                if index >= inData.count {
                    break
                    
                }
                context.addLine(to: element)
            }
            context.strokePath()
        }
    }
}
