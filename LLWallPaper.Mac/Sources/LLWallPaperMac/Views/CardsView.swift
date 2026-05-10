import LLWallPaperMacCore
import SwiftUI

struct CardsView: View {
  @ObservedObject var viewModel: AppViewModel

  var body: some View {
    VStack(spacing: 10) {
      HStack {
        TextField("Search", text: $viewModel.cardSearchText)
          .textFieldStyle(.roundedBorder)
          .frame(maxWidth: 420)

        Spacer()

        Button {
          Task {
            await viewModel.fetchCardsWithRetry()
          }
        } label: {
          Label("Fetch", systemImage: "arrow.clockwise")
        }
      }

      List(selection: $viewModel.selectedCard) {
        CardHeaderRow(viewModel: viewModel)
        ForEach(viewModel.filteredCards) { card in
          CardRow(
            card: card,
            characterName: CharacterMap.name(for: card.id),
            isFavorite: viewModel.isFavorite(card.id),
            isBlocked: viewModel.isBlocked(card.id)
          )
          .tag(card as CardItem?)
        }
      }
      .listStyle(.inset)

      HStack {
        Button {
          Task {
            await viewModel.applySelectedCard()
          }
        } label: {
          Label("Apply", systemImage: "checkmark.circle")
        }
        .disabled(viewModel.selectedCard == nil)

        Button {
          viewModel.toggleSelectedFavorite()
        } label: {
          Label("Toggle Favorite", systemImage: "star")
        }
        .disabled(viewModel.selectedCard == nil)

        Button {
          viewModel.toggleSelectedBlocked()
        } label: {
          Label("Toggle Blocked", systemImage: "nosign")
        }
        .disabled(viewModel.selectedCard == nil)

        Spacer()

        Text(viewModel.cardStatusMessage)
          .foregroundStyle(.secondary)
      }
    }
    .padding(12)
  }
}

private struct CardHeaderRow: View {
  @ObservedObject var viewModel: AppViewModel

  var body: some View {
    HStack {
      SortButton("ID", column: .id, width: 160, viewModel: viewModel)
      SortButton("Name", column: .name, width: 280, viewModel: viewModel)
      SortButton("Character", column: .characterName, width: 150, viewModel: viewModel)
      SortButton("Favorite", column: .favorite, width: 80, viewModel: viewModel)
      SortButton("Blocked", column: .blocked, width: 80, viewModel: viewModel)
    }
    .font(.caption)
    .fontWeight(.semibold)
    .foregroundStyle(.secondary)
  }
}

private struct SortButton: View {
  let title: String
  let column: CardSortColumn
  let width: CGFloat
  @ObservedObject var viewModel: AppViewModel

  init(_ title: String, column: CardSortColumn, width: CGFloat, viewModel: AppViewModel) {
    self.title = title
    self.column = column
    self.width = width
    self.viewModel = viewModel
  }

  var body: some View {
    Button {
      viewModel.sortCards(by: column)
    } label: {
      HStack(spacing: 4) {
        Text(title)
        if viewModel.cardSortColumn == column {
          Image(systemName: viewModel.cardSortAscending ? "chevron.up" : "chevron.down")
        }
      }
      .frame(width: width, alignment: .leading)
    }
    .buttonStyle(.plain)
  }
}

private struct CardRow: View {
  let card: CardItem
  let characterName: String
  let isFavorite: Bool
  let isBlocked: Bool

  var body: some View {
    HStack {
      Text(card.id).frame(width: 160, alignment: .leading)
      Text(card.name).frame(width: 280, alignment: .leading)
      Text(characterName).frame(width: 150, alignment: .leading)
      Text(isFavorite ? "True" : "False").frame(width: 80, alignment: .leading)
      Text(isBlocked ? "True" : "False").frame(width: 80, alignment: .leading)
    }
    .lineLimit(1)
  }
}
