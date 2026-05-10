import SwiftUI

struct CurrentWallpaperView: View {
  @ObservedObject var viewModel: AppViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 6) {
          Text("Current Wallpaper")
            .font(.headline)
          FlowDetails(items: [
            ("Name", viewModel.currentCardName),
            ("Character", viewModel.currentCharacterName),
            ("ID", viewModel.currentCardId),
            ("Source", viewModel.currentSource),
          ])
          Text(viewModel.statusText)
            .foregroundStyle(.secondary)
        }

        Spacer(minLength: 16)

        HStack {
          Button {
            Task {
              await viewModel.applyNext()
            }
          } label: {
            Label("Next", systemImage: "forward.fill")
          }

          Button {
            viewModel.toggleAuto()
          } label: {
            Label(
              viewModel.isAutoEnabled ? "Pause" : "Resume",
              systemImage: viewModel.isAutoEnabled ? "pause.fill" : "play.fill"
            )
          }
        }
      }

      HStack {
        Button {
          viewModel.toggleCurrentFavorite()
        } label: {
          Label("Toggle Favorite", systemImage: viewModel.currentIsFavorite ? "star.fill" : "star")
        }
        .disabled(viewModel.currentCard == nil)

        Button {
          viewModel.toggleCurrentBlocked()
        } label: {
          Label("Toggle Blocked", systemImage: viewModel.currentIsBlocked ? "nosign" : "circle")
        }
        .disabled(viewModel.currentCard == nil)
      }
    }
    .padding(12)
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(Color.secondary.opacity(0.25))
    )
  }
}

private struct FlowDetails: View {
  let items: [(String, String)]

  var body: some View {
    HStack(spacing: 14) {
      ForEach(items, id: \.0) { label, value in
        HStack(spacing: 3) {
          Text("\(label):")
            .fontWeight(.semibold)
          Text(value)
            .lineLimit(1)
        }
      }
    }
  }
}
