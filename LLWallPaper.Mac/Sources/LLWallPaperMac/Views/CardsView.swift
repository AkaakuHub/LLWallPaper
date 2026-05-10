import LLWallPaperMacCore
import SwiftUI

struct CardsView: View {
  @ObservedObject var viewModel: AppViewModel

  private var selectedCardId: Binding<CardItem.ID?> {
    Binding(
      get: {
        viewModel.selectedCard?.id
      },
      set: { selectedId in
        viewModel.selectedCard = selectedId.flatMap { id in
          viewModel.filteredCards.first { $0.id == id }
        }
      }
    )
  }

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

      Table(viewModel.filteredCards, selection: selectedCardId) {
        TableColumn("ID") { card in
          Text(card.id)
        }
        .width(min: 120, ideal: 160)

        TableColumn("Name") { card in
          Text(card.name)
        }
        .width(min: 260, ideal: 360)

        TableColumn("Character") { card in
          Text(CharacterMap.name(for: card.id))
        }
        .width(min: 120, ideal: 150)

        TableColumn("Favorite") { card in
          Text(viewModel.isFavorite(card.id) ? "True" : "False")
        }
        .width(min: 80, ideal: 90)

        TableColumn("Blocked") { card in
          Text(viewModel.isBlocked(card.id) ? "True" : "False")
        }
        .width(min: 80, ideal: 90)
      }

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
