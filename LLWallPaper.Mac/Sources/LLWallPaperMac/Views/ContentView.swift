import LLWallPaperMacCore
import SwiftUI

struct ContentView: View {
  @ObservedObject var viewModel: AppViewModel

  var body: some View {
    VStack(spacing: 14) {
      CurrentWallpaperView(viewModel: viewModel)
      TabView {
        CardsView(viewModel: viewModel)
          .tabItem {
            Label("Cards", systemImage: "rectangle.grid.2x2")
          }
        SettingsView(viewModel: viewModel)
          .tabItem {
            Label("Settings", systemImage: "gearshape")
          }
        HistoryView(viewModel: viewModel)
          .tabItem {
            Label("History", systemImage: "clock.arrow.circlepath")
          }
      }
    }
    .padding(16)
  }
}
