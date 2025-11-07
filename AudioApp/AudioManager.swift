//
//  AudioManager.swift
//  AudioApp
//
//  Created by Omar Mendivil on 11/6/25.
//

import Foundation
import AVFAudio

enum AudioError: Error {
    case unableToSetSession
}

class AudioManager {
    var audioEngine: AVAudioEngine
    var audioFile: AVAudioFile?
    var isRecording: Bool
    var recordingURL: URL?
    
    init() {
        self.audioEngine = AVAudioEngine()
        self.audioFile = nil
        self.isRecording = false
        self.recordingURL = nil
    }

   
    func startSession() async throws {
        let audioSession = AVAudioSession.sharedInstance()
        
        if await AVAudioApplication.requestRecordPermission() {
            try audioSession.setCategory(.playAndRecord, mode: .default )
            try audioSession.setActive(true)
        } else {
            print("User Denied recording")
        }
    }
    
    func createEngine() {
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        
        audioEngine.prepare()
    }
}
