//
//  ViewController.swift
//  MusicVisualization
//
//  Created by 黃柏叡 on 2017/8/8.
//  Copyright © 2017年 黃柏叡. All rights reserved.
//

import UIKit
import AVFoundation
import Accelerate


class ViewController: UIViewController {
    
    @IBOutlet weak var visualizationView: VisualizationView!
    
    var magnitudes:[Float]?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        visualizationView.delegate = self
        visualizationView.enableMicrophone = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        var array: Array<Float> = []
        for i in 0..<10 {
            array.append(Float(i))
        }
        print(array)
//        var newArray: Array<Int> = []
//        for i in 0..<array.count {
//            if i % 2 == 0 {
//                newArray.append(array[i])
//            }
//            else{
//                newArray.insert(array[i], at: 0)
//            }
//        }
        let newArray = reIndexArray(array)
        print(newArray)
        
    }
    
    func reIndexArray(_ array: Array<Any>) -> Array<Any> {
        var newArray: Array<Any> = []
        for i in 0..<array.count {
            if i % 2 == 0 {
                newArray.append(array[i])
            }
            else{
                newArray.insert(array[i], at: 0)
            }
        }
        return newArray
    }
    
    func start() {
        visualizationView.start()
    }
    
    func stop() {
        visualizationView.stop()
    }
    
    @IBAction func control(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        sender.isSelected == true ? start() : stop()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension ViewController: VisualizationViewDelegate {
    func didRenderAudioFile(_ visualizationView: VisualizationView) {
        print("didRenderAudioFile")
    }
    
    func didStartPlayingAudio(_ visualizationView: VisualizationView) {
        print("didStartPlayingAudio")
    }
    
    func didStopPlayingAudio(_ visualizationView: VisualizationView) {
        print("didStopPlayingAudio")
    }
}
