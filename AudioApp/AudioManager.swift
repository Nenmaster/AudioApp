//
//  AudioManager.swift
//  AudioApp
//
//  Created by Omar Mendivil on 11/6/25.
//

import Foundation
import AVFAudio

enum AudioError: Error {
    case unableToSetSession, unableToStop, unableToStoreRecording
}

class AudioManager: ObservableObject {
    var audioEngine: AVAudioEngine
    var audioFile: AVAudioFile?
    @Published var isRecording: Bool
    var recordingURL: URL?
    @Published var currentPower: Float = 0.0
    @Published var recordings: [URL] = []
    @Published var playerNode : AVAudioPlayerNode?
    @Published var isCurrentlyPlaying: URL?
    @Published var isPlayingNode: Bool = false
    private var count = 0

    init() {
        self.audioEngine = AVAudioEngine()
        self.audioFile = nil
        self.isRecording = false
        self.recordingURL = nil
    }

   
    func startSession() async throws {
        let audioSession = AVAudioSession.sharedInstance()
        
        if await AVAudioApplication.requestRecordPermission() {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker] )
            try audioSession.setActive(true)
        } else {
            print("User Denied recording")
        }
    }
    
    func createEngine() {
        let inputNode = audioEngine.inputNode
        inputNode.inputFormat(forBus: 0)
        
        audioEngine.prepare()
    }
    
    func startRecording() throws {
        audioEngine.stop()
        audioEngine.reset()
        
        let input = audioEngine.inputNode
        input.removeTap(onBus: 0)

        
        let format = input.inputFormat(forBus: 0)
        
        let fileURL = FileManager.default
                    .urls(for: .documentDirectory, in: .userDomainMask)[0]
                    .appendingPathComponent("recording_\(count).m4a")
        
        let file = try AVAudioFile(forWriting: fileURL, settings: format.settings)
        
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, time in
            try? file.write(from: buffer)
            let data = buffer.floatChannelData?[0]
            let frameLen = Int(buffer.frameLength)
            if let data = data {
                let rms = sqrt((0..<frameLen).reduce(0) { $0 + pow(data[$1],2)} / Float(frameLen))
                let avgPower = 20 * log10(rms)
                DispatchQueue.main.async {
                    self.currentPower = avgPower
                }
            }
        }
        
        try audioEngine.start()

        self.audioFile = file
        self.recordingURL = fileURL
        isRecording = true
        count += 1
        
        print("isRecording = \(isRecording)")
        print("recording started")
    }
    
    func loadRecording() throws {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let files = try FileManager.default.contentsOfDirectory(at: docs, includingPropertiesForKeys: nil)
            self.recordings = files.filter { $0.pathExtension == "m4a" }
        } catch {
            throw AudioError.unableToStoreRecording
        }
        
    }
    
    // test branch change 
    
    func stopRecording() {
        let input = audioEngine.inputNode
        input.removeTap(onBus: 0)
        
        audioEngine.stop()
        audioEngine.reset()
        isRecording = false
        audioFile = nil
        do {
            try loadRecording()
        } catch {
            print("Recoriding not load \(error)")
        }
        print("recording stopped")
        print("isRecordng = \(isRecording)")
    }
    
    func deleteRecording(url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
            count -= 1
            try loadRecording()
        } catch {
            print("Failed to delete")
        }
    }
    
    func playRecording(url: URL) throws {
        if let node = playerNode {
            if isCurrentlyPlaying != url {
                node.stop()
                audioEngine.detach(node)
                playerNode = nil
                isCurrentlyPlaying = nil
                isPlayingNode = false
            } else {
                if isPlayingNode {
                    node.pause()
                    isPlayingNode = false
                    isCurrentlyPlaying = nil
                } else {
                    node.play()
                    isPlayingNode = true
                    isCurrentlyPlaying = url
                }
                return
            }
        }
        
        let newNode = AVAudioPlayerNode()
        playerNode = newNode
        audioEngine.attach(newNode)
        let audioFile = try AVAudioFile(forReading: url)
        
        audioEngine.connect (
            newNode,
            to: audioEngine.mainMixerNode,
            format: audioFile.processingFormat
        )
        
        newNode.scheduleFile(audioFile, at: nil)
        
        if !audioEngine.isRunning {
            try audioEngine.start()
        }
        
        newNode.play()
        isCurrentlyPlaying = url
        isPlayingNode = true
    }
    
}

