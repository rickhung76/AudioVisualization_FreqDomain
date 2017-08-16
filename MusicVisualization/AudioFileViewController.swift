//
//  AudioFileViewController.swift
//  MixerSwift
//
//  Created by 黃柏叡 on 2017/8/9.
//  Copyright © 2017年 Bruce. All rights reserved.
//

import UIKit
import AVFoundation
import Accelerate

class AudioFileViewController: UIViewController {
    
    @IBOutlet weak var visualizationView: VisualizationView!
    
    @IBOutlet weak var visualizationView2: VisualizationView!

    override func viewDidLoad() {
        super.viewDidLoad()
        visualizationView.initAudioEngineManager()
        visualizationView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        visualizationView2.initAudioEngineManager()
        visualizationView2.delegate = self
    }
    
    @IBAction func control(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            guard let fileURL = Bundle.main.url(forResource: "testAudio2", withExtension: "mp3") else {
                print("could not read sound file")
                return
            }
            visualizationView.audioURL = fileURL
            visualizationView.playAudio()
        }
        else {
            visualizationView.stopAudio()
        }
    }
    
    @IBAction func control2(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            guard let fileURL = Bundle.main.url(forResource: "testAudio", withExtension: "mp3") else {
                print("could not read sound file")
                return
            }
            visualizationView2.audioURL = fileURL
            visualizationView2.playAudio()
        }
        else {
            visualizationView2.stopAudio()
        }
    }
}

extension AudioFileViewController: VisualizationViewDelegate {
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
