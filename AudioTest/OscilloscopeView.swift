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
    let pointArraySize = 512
    // fixed size array of points that we will plot
    var pointArray = [CGPoint](repeating: CGPoint(), count: 512)
    
    public func convertToPointsInRect(_ rect: CGRect) {
        guard let inData = dataBuffer else {return}
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
            let ampedUp = element * amplitudeCorrection
            //  add the offset to put 0 at the midpoint, vertically, in the window
            let y = ampedUp + (cgheight/2.0)
            // now figure the x coord
            let x = CGFloat(pointIndex) * (cgwidth/512)
            pointArray[pointIndex] = CGPoint(x: Double(x), y: Double(y))
            pointIndex = pointIndex + 1
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
