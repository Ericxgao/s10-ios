//
//  RecorderController.swift
//  S10
//
//  Created by Tony Xiao on 6/18/15.
//  Copyright (c) 2015 S10. All rights reserved.
//

import Foundation
import SCRecorder

protocol ProducerDelegate : NSObjectProtocol {
    func producer(producer: ProducerViewController, didProduceVideo url: NSURL)
}

class ProducerViewController : UINavigationController {
    
    var recorderVC: RecorderViewController!
    var editorVC: EditorViewController!
    var currentFilter: SCFilter?
    weak var producerDelegate: ProducerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recorderVC = makeViewController(.Recorder) as! RecorderViewController
        editorVC = makeViewController(.Editor) as! EditorViewController
        recorderVC.delegate = self
        editorVC.delegate = self
        
        viewControllers = [recorderVC]
    }
}

extension ProducerViewController : RecorderDelegate {
    func recorder(recorder: RecorderViewController, didRecordSession session: SCRecordSession) {
        editorVC.recordSession = session
        currentFilter = recorder.previewView.selectedFilter
        editorVC.recordSessionFilter = currentFilter
        pushViewController(editorVC, animated: false)
    }
}

extension ProducerViewController : EditorDelegate {
    func editorDidCancel(editor: EditorViewController) {
        currentFilter = editorVC.filterView.selectedFilter
        recorderVC.previewView.selectedFilter = currentFilter
        popViewControllerAnimated(false)
    }
    
    func editor(editor: EditorViewController, didEditVideo outputURL: NSURL) {
        producerDelegate?.producer(self, didProduceVideo: outputURL)
    }
}
