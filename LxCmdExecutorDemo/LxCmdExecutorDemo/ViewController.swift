//
//  ViewController.swift
//  LxCmdExecutorDemo
//
//  Created by didi on 2017/9/10.
//  Copyright © 2017年 DeveloperLx. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        LxCmdExecutor.execute(cmd: "clang-format --version", outputAction: { output in
            print("output = \n" + output)
        }, errorAction: { error in
            print("error = \n" + error)
        }, terminationAction: { status in
            print("status = \n\(status)")
        })
    }


}

