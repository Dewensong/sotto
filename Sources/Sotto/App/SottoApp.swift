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

            CommandMenu("Prompt") {
                Button("打开提词") {
                    model.openTeleprompter()
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .disabled(model.session == nil)

                Button(model.session?.isPlaying == true ? "暂停" : "播放") {
                    model.togglePlayback()
                }
                .keyboardShortcut(.space, modifiers: [])
                .disabled(model.session == nil)

                Button("上一句") {
                    model.previousSentence()
                }
                .keyboardShortcut(.leftArrow, modifiers: [.command])
                .disabled(model.session == nil)

                Button("下一句") {
                    model.nextSentence()
                }
                .keyboardShortcut(.rightArrow, modifiers: [.command])
                .disabled(model.session == nil)

                Divider()

                Button("从头开始") {
                    model.restartSession()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .disabled(model.session == nil)

                Divider()

                Button("中央偏上") {
                    model.setPromptPosition(.upperCenter)
                }
                .keyboardShortcut("1", modifiers: [.command, .option])

                Button("靠近摄像头") {
                    model.setPromptPosition(.cameraNear)
                }
                .keyboardShortcut("2", modifiers: [.command, .option])

                Divider()

                Button("跳到开头") {
                    model.jumpToSentence(at: 0)
                }
                .keyboardShortcut(.upArrow, modifiers: [.command])
                .disabled(model.session == nil)

                Button("跳到结尾") {
                    if let count = model.session?.document.sentences.count, count > 0 {
                        model.jumpToSentence(at: count - 1)
                    }
                }
                .keyboardShortcut(.downArrow, modifiers: [.command])
                .disabled(model.session == nil)

                Divider()

                Button("长稿导航") {
                    model.toggleSentencePicker()
                }
                .keyboardShortcut("j", modifiers: [.command])
                .disabled(model.session == nil)

                Divider()

                Button("退出提词") {
                    model.closeTeleprompter()
                }
                .keyboardShortcut(.escape, modifiers: [])
                .disabled(model.session == nil)
            }
        }
    }
}
