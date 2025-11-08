//
//  ContentView.swift
//  AudioApp
//
//  Created by Omar Mendivil on 11/6/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var audioEngine = AudioManager()
    
    var body: some View {
        VStack {
            Rectangle()
                .fill(Color.red)
                .frame(width: 300, height: CGFloat(max(10, 100 + audioEngine.currentPower)))
                .animation(.easeOut(duration: 0.1), value: audioEngine.currentPower)
            
            if !audioEngine.isRecording {
                Image(systemName: "play.circle")
                .font(.system(size: 100))
                .onTapGesture {
                    Task {
                        do {
                            try await audioEngine.startSession()
                            try audioEngine.startRecording()
                            print("tapped")

                        }catch {
                            print("Audio error \(error)")
                        }
                    }
                }
            } else if audioEngine.isRecording {
               Image(systemName: "pause.circle")
                .font(.system(size: 100))
                .onTapGesture {
                    audioEngine.stopRecording()
                    print("stop tap")
                }
            }
            
        }
        
    }
    

}

#Preview {
    ContentView()
}
