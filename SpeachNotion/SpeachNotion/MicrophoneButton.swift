//
//  MicrophoneButton.swift
//  SpeachNotion
//
//  Created by KhaiN on 8/8/22.
//

import SwiftUI

struct MicrophoneButton: View {
//    let onStart: () -> Void
//    let onStop: () -> Void
    @Environment(\.managedObjectContext) private var viewContext
    @State private var recording = false
    @ObservedObject private var mic = MicrophoneMonitor(numberOfSamples: 30)
    private var speechManager = SpeechManager()

    var body: some View {
        ToggleButton(onDown: startRecording, onUp: stopRecording) {
            Circle()
                .frame(width: 80, height: 80)
                .foregroundColor(.blue)
                .overlay(
                    Image(systemName: "mic.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .foregroundColor(.white)
                )
        }.buttonStyle(Style())
    }

    private func startRecording() {
        //self.onStart()
        self.addNote()
    }

    private func stopRecording() {
        //self.onStop()
        speechManager.isRecording.toggle()
    }

    private struct Style: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 1.25 : 1.0)
                .animation(.easeInOut)
        }
    }
    
    private func addNote() {
        if speechManager.isRecording {
            self.recording = false
            mic.stopMonitoring()
            speechManager.stopRecording()
        } else {
            self.recording = true
            mic.startMonitoring()
            speechManager.start { (speechText) in
                guard let text = speechText, !text.isEmpty else {
                    self.recording = false
                    return
                }
                
                DispatchQueue.main.async {
                    withAnimation {
                        let newNote = Note(context: viewContext)
                        newNote.id = UUID()
                        newNote.title = text
                        newNote.created = Date()

                        do {
                            try viewContext.save()
                        } catch {
                            let nsError = error as NSError
                            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                        }
                    }
                }
            }
        }
        //speechManager.isRecording.toggle()
//        withAnimation {
//            let newItem = Note(context: viewContext)
//            newItem.created = Date()
//
//            do {
//                try viewContext.save()
//            } catch {
//                // Replace this implementation with code to handle the error appropriately.
//                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//                let nsError = error as NSError
//                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
//            }
//        }
    }
}

