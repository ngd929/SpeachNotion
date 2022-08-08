//
//  SpeachNotionApp.swift
//  SpeachNotion
//
//  Created by KhaiN on 8/7/22.
//

import SwiftUI

@main
struct SpeachNotionApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
