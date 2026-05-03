import SwiftUI

@main
struct SottoApp: App {
    @StateObject private var model = AppModel()

    init() {
        SottoFont.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup("Sotto") {
            ContentView()
                .environmentObject(model)
                .preferredColorScheme(.dark)
                .frame(width: 520, height: 860)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 520, height: 860)
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
