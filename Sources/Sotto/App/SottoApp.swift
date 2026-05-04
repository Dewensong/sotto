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
                .frame(width: model.currentDocument == nil ? 520 : 1320, height: model.currentDocument == nil ? 760 : 860)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 520, height: 760)
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
