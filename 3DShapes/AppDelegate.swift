//
//  AppDelegate.swift
//  3DShapes
//
//  Created by MainWaffle on 3/28/15.
//  Copyright (c) 2015 MainWaffle. All rights reserved.
//

import Cocoa
import SceneKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, SCNSceneRendererDelegate {
    
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var pressLabel: NSTextField!
    @IBOutlet weak var numPointsField: NSTextField!
    let calcQueue = DispatchQueue(label: "calcQueue", qos: DispatchQoS.userInteractive, attributes: DispatchQueue.Attributes.concurrent, autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit, target: nil)
    let arrayQueue = DispatchQueue(label: "arrayQueue")
    var coordinateArray: Array<SCNVector3> = []
    var indices: [Int] = []
    @IBOutlet weak var mainScene: SCNView!
    
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        NSColor.green.set()
    }
    
    func drawArt(window: NSView) {
        let numPoints = (self.numPointsField.stringValue as NSString).doubleValue
        if numPoints > 0 {
            
            let r: CGFloat = 1
            
            self.coordinateArray.removeAll()
            
            for theta: Double in stride(from: 0 as Double, through: M_PI, by: Double(M_PI) / numPoints * 2) {
                DispatchQueue.concurrentPerform(iterations: Int(numPoints), execute: { (n: Int) in
                    let phi = M_PI * Double(2) / Double(numPoints) * Double(n)
                    let newVector = SCNVector3Make(r * CGFloat(sin(theta)) * CGFloat(cos(phi)), r * CGFloat(sin(theta)) * CGFloat(sin(phi)), r * CGFloat(cos(theta)))
                    self.arrayQueue.sync(execute: { () -> Void in
                        self.coordinateArray.append(newVector)
                    })
                })
                
            }
            
            calcQueue.async(qos: DispatchQoS.userInteractive, flags: DispatchWorkItemFlags.barrier, execute: {
                
                let mainNode = SCNNode()
                
                for coord1 in self.coordinateArray
                {
                    let junkNode1: SCNNode = SCNNode()
                    junkNode1.position = coord1
                    
                    for coord2 in self.coordinateArray
                    {
                        let junkNode2: SCNNode = SCNNode()
                        junkNode2.position = coord2
                        let newNode = self.lineBetweenNodeA(junkNode1, nodeB: junkNode2)
                        
                        mainNode.addChildNode(newNode)
                        
                    }
                }
                
                DispatchQueue.main.sync(execute: { () -> Void in
                    
                    mainNode.childNodes.forEach({ (node) in
                        let colorMaterial = SCNMaterial()
                        colorMaterial.diffuse.contents = NSColor.red
                        
                        node.geometry!.firstMaterial = colorMaterial
                    })
                    
                    self.mainScene.autoenablesDefaultLighting = true
                    self.mainScene.allowsCameraControl = true
                    let resultScene = SCNScene()
                    resultScene.rootNode.addChildNode(mainNode.flattenedClone())
                    self.mainScene.scene = resultScene
                })
            })
        }
    }
    
    func lineBetweenNodeA(_ nodeA: SCNNode, nodeB: SCNNode) -> SCNNode
    {
        let positions: [Float] = [Float(nodeA.position.x), Float(nodeA.position.y), Float(nodeA.position.z), Float(nodeB.position.x), Float(nodeB.position.y), Float(nodeB.position.z)]
        let positionData = Data(bytes: positions, count: MemoryLayout<Float>.size*positions.count)
        let indices: [Int32] = [0, 1]
        let indexData = Data(bytes: indices, count: MemoryLayout<Int32>.size * indices.count)
        
        let source = SCNGeometrySource(data: positionData, semantic: SCNGeometrySource.Semantic.vertex, vectorCount: indices.count, usesFloatComponents: true, componentsPerVector: 3, bytesPerComponent: MemoryLayout<Float>.size, dataOffset: 0, dataStride: MemoryLayout<Float>.size * 3)
        let element = SCNGeometryElement(data: indexData, primitiveType: SCNGeometryPrimitiveType.line, primitiveCount: indices.count, bytesPerIndex: MemoryLayout<Int32>.size)
        
        let line = SCNGeometry(sources: [source], elements: [element])
        return SCNNode(geometry: line)
    }
    
    @IBAction func drawPushed(sender: NSButton)
    {
        //self.mainScene.backgroundColor = NSColor.blackColor()
        sender.isEnabled = false
        self.drawArt(window: self.mainScene)
        sender.isEnabled = true
    }
    
    @IBAction func buttonPressed(sender: NSButton)
    {
        self.pressLabel.stringValue=sender.integerValue.description
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification)
    {
        self.window.delegate = self
        // Insert code here to initialize your application
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool
    {
        return true;
    }
    
    func xy_values(angle: CGFloat, currentWindow: AnyObject?) -> (CGFloat, CGFloat)
    {
        var cur_size: CGFloat = window.frame.height
        if window.frame.width < window.frame.height {
            cur_size = window.frame.width
        }
        let compensated_x = sin(angle / CGFloat(180.0) * CGFloat(M_PI)) * (cur_size - 60) / 2 + window.frame.width / 2
        let compensated_y = cos(angle / CGFloat(180.0) * CGFloat(M_PI)) * (cur_size - 60) / 2 + window.frame.height / 2
        return (compensated_x, compensated_y)
    }
}
