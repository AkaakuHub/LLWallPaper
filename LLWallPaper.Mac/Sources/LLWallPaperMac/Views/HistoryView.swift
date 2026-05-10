import LLWallPaperMacCore
import SwiftUI

struct HistoryView: View {
  @ObservedObject var viewModel: AppViewModel

  var body: some View {
    VStack(spacing: 10) {
      HStack {
        Text("Base Path")
          .fontWeight(.semibold)
        Text(viewModel.historyBasePath)
          .lineLimit(1)
          .truncationMode(.middle)
          .foregroundStyle(.secondary)

        Spacer()

        Button {
          viewModel.refreshHistory()
        } label: {
          Label("Refresh", systemImage: "arrow.clockwise")
        }
      }

      HStack(alignment: .top, spacing: 16) {
        List(selection: $viewModel.selectedHistoryEntry) {
          HistoryHeaderRow()
          ForEach(viewModel.historyItems) { entry in
            HistoryRow(entry: entry)
              .tag(entry as HistoryEntry?)
          }
        }
        .listStyle(.inset)
        .frame(minWidth: 460)

        VStack(spacing: 12) {
          HistoryImagePreview(imageUrl: viewModel.selectedHistoryImageUrl)

          HStack {
            Button {
              viewModel.copySelectedHistoryImage()
            } label: {
              Label("Copy Image", systemImage: "doc.on.doc")
            }
            .disabled(!viewModel.hasSelectedHistoryImage)

            Button {
              viewModel.openSelectedHistoryDetail()
            } label: {
              Label("Open Detail", systemImage: "safari")
            }
            .disabled(viewModel.selectedHistoryEntry == nil)
          }

          SelectedHistoryDetails(entry: viewModel.selectedHistoryEntry)
          Spacer()
        }
        .frame(width: 360)
      }

      HStack {
        Button {
          Task {
            await viewModel.applySelectedHistoryEntry()
          }
        } label: {
          Label("Apply", systemImage: "checkmark.circle")
        }
        .disabled(viewModel.selectedHistoryEntry == nil)

        Button {
          viewModel.toggleSelectedHistoryFavorite()
        } label: {
          Label("Toggle Favorite", systemImage: "star")
        }
        .disabled(viewModel.selectedHistoryEntry == nil)

        Button {
          viewModel.toggleSelectedHistoryBlocked()
        } label: {
          Label("Toggle Blocked", systemImage: "nosign")
        }
        .disabled(viewModel.selectedHistoryEntry == nil)

        Spacer()

        Text(viewModel.historyStatusMessage)
          .foregroundStyle(.secondary)
      }
    }
    .padding(12)
  }
}

private struct HistoryHeaderRow: View {
  var body: some View {
    HStack {
      Text("At").frame(width: 150, alignment: .leading)
      Text("Key").frame(width: 80, alignment: .leading)
      Text("Character").frame(width: 130, alignment: .leading)
      Text("Card").frame(width: 140, alignment: .leading)
    }
    .font(.caption)
    .fontWeight(.semibold)
    .foregroundStyle(.secondary)
  }
}

private struct HistoryRow: View {
  let entry: HistoryEntry

  var body: some View {
    HStack {
      Text(entry.at.formatted(date: .numeric, time: .standard))
        .frame(width: 150, alignment: .leading)
      Text(entry.key)
        .frame(width: 80, alignment: .leading)
      Text(entry.characterName)
        .frame(width: 130, alignment: .leading)
      Text(entry.cardName)
        .frame(width: 140, alignment: .leading)
    }
    .lineLimit(1)
  }
}

private struct HistoryImagePreview: View {
  let imageUrl: URL?

  var body: some View {
    Group {
      if let imageUrl, let image = NSImage(contentsOf: imageUrl) {
        Image(nsImage: image)
          .resizable()
          .scaledToFit()
      } else {
        ZStack {
          Rectangle()
            .fill(Color.secondary.opacity(0.08))
          Text("No Image")
            .foregroundStyle(.secondary)
        }
      }
    }
    .frame(width: 332, height: 215)
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(Color.secondary.opacity(0.25))
    )
  }
}

private struct SelectedHistoryDetails: View {
  let entry: HistoryEntry?

  var body: some View {
    Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 8) {
      DetailRow(
        label: "Selected At", value: entry?.at.formatted(date: .numeric, time: .standard) ?? "")
      DetailRow(label: "Selected Key", value: entry?.key ?? "")
      DetailRow(label: "Selected Card", value: entry?.cardName ?? "")
      DetailRow(label: "Selected Character", value: entry?.characterName ?? "")
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct DetailRow: View {
  let label: String
  let value: String

  var body: some View {
    GridRow {
      Text(label)
        .fontWeight(.semibold)
      Text(value)
        .lineLimit(1)
    }
  }
}
