import AppKit
import SwiftUI

@main
struct LLWallPaperMacApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  @StateObject private var viewModel = AppViewModel()
  @State private var didRunStartup = false
  @Environment(\.openWindow) private var openWindow
  private let startupUpdateController = StartupUpdateController()

  var body: some Scene {
    WindowGroup("LLWallPaper", id: "main") {
      ContentView(viewModel: viewModel)
        .frame(minWidth: 920, minHeight: 620)
        .task {
          if didRunStartup {
            return
          }
          didRunStartup = true

          await viewModel.initialize()
          if viewModel.settings.startMinimized {
            NSApplication.shared.hide(nil)
          }
          await startupUpdateController.checkForUpdatesOnStartup()
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

    MenuBarExtra {
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
    } label: {
      Image(nsImage: MenuBarIcon.image)
    }
  }

  private func openMainWindow() {
    openWindow(id: "main")
    NSApplication.shared.activate(ignoringOtherApps: true)
  }
}
