//
//  ContentView.swift
//  SpeachNotion
//
//  Created by KhaiN on 8/7/22.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Note.created, ascending: true)],
        animation: .default)
    private var notes: FetchedResults<Note>

    @State private var recording = false
    @ObservedObject private var mic = MicrophoneMonitor(numberOfSamples: 30)
    private var speechManager = SpeechManager()
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                List {
                    ForEach(notes) { note in
                        NavigationLink {
                            Text("Note created at \(note.created!, formatter: noteFormatter)")
                        } label: {
                            Text(note.title ?? "???")
                            //Text(note.created!, formatter: noteFormatter)
                        }
                    }
                    .onDelete(perform: deleteNotes)
                }
                .navigationTitle("My Notes")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    ToolbarItem {
                        Button(action: addNote) {
                            Label("Add Note", systemImage: "plus")
                        }
                    }
                }
                //Text("Select a note")
                
                VStack {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.black.opacity(0.7))
                        .padding()
                        .overlay(
                            VStack {
                                visualizerView()
                            }
                        )
                        .opacity(recording ? 1 : 0)
                
                    microphoneButton()
                }
            }
            .onAppear {
                speechManager.checkPermissions()
            }
        }
    }
    
    private func microphoneButton() -> some View {
        Button(action: addNote) {
            Circle()
                .frame(width: 80, height: 80)
                .foregroundColor(.blue)
                .overlay(
                    Image(systemName: recording ? "stop.fill" : "mic.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .foregroundColor(.white)
                )
        }.buttonStyle(Style())
    }
    
    private struct Style: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 1.25 : 1.0)
                .animation(.easeInOut(duration: 1), value: 1.0)
                .padding(.bottom, 20)
        }
    }
    
    private func normalizeSoundLevel(level: Float) -> CGFloat {
        let level = max(0.2, CGFloat(level) + 50) / 2 // between 0.1 and 25
        
        return CGFloat(level * (100 / 25)) // scaled to max at 300 (our height of our bar)
    }
    
    private func visualizerView() -> some View {
       return VStack {
            HStack(spacing: 4) {
                ForEach(mic.soundSamples, id: \.self) { level in
                    SoundLevelView(value: self.normalizeSoundLevel(level: level))
                }
            }
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
        speechManager.isRecording.toggle()
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

    private func deleteNotes(offsets: IndexSet) {
        withAnimation {
            offsets.map { notes[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let noteFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//    }
//}
