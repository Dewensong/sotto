import SwiftUI

@main
struct SottoApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("Sotto") {
            ContentView()
                .environmentObject(model)
                .preferredColorScheme(.dark)
                .frame(minWidth: 1080, minHeight: 720)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(after: .newItem) {
                Button("准备上场") {
                    model.createDocumentFromInput()
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(model.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}
