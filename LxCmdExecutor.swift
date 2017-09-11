//
//  LxCmdExecutor.swift
//  LxCmdExecutorDemo
//
//  Created by didi on 2017/9/10.
//  Copyright © 2017年 DeveloperLx. All rights reserved.
//

import Cocoa

class LxCmdExecutor {

    public class func execute(cmd: String, outputAction: @escaping (String) -> Void, errorAction: @escaping (String) -> Void, terminationAction: @escaping (Int32) -> Void) {
        let cmdComponent = cmd.components(separatedBy: " ")
        if cmdComponent.count <= 0 {
            terminationAction(-1);
            return
        }
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            let name = cmdComponent.first!
            let arguments = Array(cmdComponent.dropFirst())
            
            if self.isExecutableFile(path: name) {
                let task = Process()
                task.launchPath = name
                task.arguments = arguments
                
                let inputPipe = Pipe()
                task.standardInput = inputPipe
                
                let input = FileHandle.standardInput
                input.waitForDataInBackgroundAndNotify()
                
                NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: input, queue: nil, using: {
                    notification in
                    let inputData = input.availableData
                    if inputData.count > 0 {
                        inputPipe.fileHandleForWriting.write(inputData)
                        input.waitForDataInBackgroundAndNotify()
                    } else {
                        inputPipe.fileHandleForWriting.closeFile()
                    }
                })
                
                let outputPipe = Pipe()
                task.standardOutput = outputPipe
                
                outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
                
                NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading, queue: nil) {
                    notification in
                    
                    let outputData = outputPipe.fileHandleForReading.availableData
                    if var outputString = String(data: outputData, encoding: String.Encoding.utf8) {
                        if outputString.hasSuffix("\n") {
                            let index = outputString.index(outputString.endIndex, offsetBy: -1)
                            outputString = outputString.substring(to: index)
                        }
                        DispatchQueue.main.async {
                            outputAction(outputString)
                        }
                    }
                    
                    outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
                }
                
                let errorPipe = Pipe()
                task.standardError = errorPipe
                
                errorPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
                
                NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: errorPipe.fileHandleForReading, queue: nil) {
                    notification in
                    
                    let errorData = outputPipe.fileHandleForReading.availableData
                    if let errorString = String(data: errorData, encoding: String.Encoding.utf8) {
                        DispatchQueue.main.async {
                            errorAction(errorString)
                        }
                    }
                    
                    errorPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
                }
                
                task.terminationHandler = { task in
                    DispatchQueue.main.async {
                        terminationAction(task.terminationStatus);
                    }
                }
                
                task.launch()
                task.waitUntilExit()
            } else {
                self.execute(cmd: "/usr/bin/which -a " + name + " | tail -n 1", outputAction: { output in

                }, errorAction: { error in
                
                }, terminationAction: { status in
                    
                })
            }
        }
    }
    
    private class func isExecutableFile(path: String) -> Bool {
        return FileManager.default.isExecutableFile(atPath: path)
    }
}
