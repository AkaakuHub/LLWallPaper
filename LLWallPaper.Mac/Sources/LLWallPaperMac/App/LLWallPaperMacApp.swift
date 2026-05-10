import AppKit
import SwiftUI

@main
struct LLWallPaperMacApp: App {
  @StateObject private var viewModel = AppViewModel()

  var body: some Scene {
    WindowGroup("LLWallPaper") {
      ContentView(viewModel: viewModel)
        .frame(minWidth: 920, minHeight: 620)
        .task {
          await viewModel.initialize()
          if viewModel.settings.startMinimized {
            NSApplication.shared.hide(nil)
          }
        }
    }
    .windowResizability(.contentMinSize)
    .commands {
      CommandGroup(after: .appInfo) {
        Button("Apply Next Wallpaper") {
          Task {
            await viewModel.applyNext()
          }
        }
        .keyboardShortcut("n", modifiers: [.command])
      }
    }
  }
}
