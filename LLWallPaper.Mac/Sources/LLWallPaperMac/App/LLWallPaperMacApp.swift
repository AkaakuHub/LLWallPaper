import AppKit
import SwiftUI

@main
struct LLWallPaperMacApp: App {
  @StateObject private var viewModel = AppViewModel()
  @Environment(\.openWindow) private var openWindow

  var body: some Scene {
    WindowGroup("LLWallPaper", id: "main") {
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

    MenuBarExtra("LLWallPaper", systemImage: "photo.on.rectangle.angled") {
      Text("Current: \(viewModel.currentCardName) / \(viewModel.currentCharacterName)")
      Divider()
      Button("Open") {
        openMainWindow()
      }
      Button("Next") {
        Task {
          await viewModel.applyNext()
        }
      }
      Button(viewModel.isAutoEnabled ? "Pause" : "Resume") {
        viewModel.toggleAuto()
      }
      Divider()
      Button("Quit") {
        NSApplication.shared.terminate(nil)
      }
    }
  }

  private func openMainWindow() {
    openWindow(id: "main")
    NSApplication.shared.activate(ignoringOtherApps: true)
  }
}
