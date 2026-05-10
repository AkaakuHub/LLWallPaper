import SwiftUI

struct SettingsView: View {
  @ObservedObject var viewModel: AppViewModel

  var body: some View {
    ScrollView {
      Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 16, verticalSpacing: 10) {
        SectionHeader("Backend")
        TextFieldRow("Base URL", text: $viewModel.settings.backendBaseUrl, width: 420)

        SectionHeader("Auto Rotate")
        ToggleRow("Auto Rotate Enabled", isOn: $viewModel.settings.autoRotateEnabled)
        IntFieldRow("Interval (minutes)", value: $viewModel.settings.rotateIntervalMinutes)
        ToggleRow("Rotate on App Start", isOn: $viewModel.settings.rotateOnAppStart)

        SectionHeader("Random Rules")
        IntFieldRow("Recent Exclude Count", value: $viewModel.settings.recentExcludeCount)
        ToggleRow("Prefer Favorites", isOn: $viewModel.settings.preferFavorites)
        ToggleRow("Exclude Blocked", isOn: $viewModel.settings.excludeBlocked)
        ToggleRow(
          "Exclude duplicated 3rd evolution", isOn: $viewModel.settings.excludeThirdEvolution)
        ToggleRow("Exclude SR cards", isOn: $viewModel.settings.excludeSrCards)

        SectionHeader("Startup")
        ToggleRow("Start with macOS", isOn: $viewModel.settings.startWithMacOS)
        ToggleRow("Start minimized", isOn: $viewModel.settings.startMinimized)

        SectionHeader("Cache")
        IntFieldRow("Cache Max (MB)", value: $viewModel.settings.cacheMaxMb)

        SectionHeader("History")
        IntFieldRow("History Max Entries", value: $viewModel.settings.historyMaxEntries)

        GridRow {
          Text("")
          Button {
            viewModel.saveSettings()
          } label: {
            Label("Save Settings", systemImage: "square.and.arrow.down")
          }
        }
      }
      .padding(12)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

private struct SectionHeader: View {
  let title: String

  init(_ title: String) {
    self.title = title
  }

  var body: some View {
    GridRow {
      Text(title)
        .font(.headline)
        .padding(.top, 8)
      Text("")
    }
  }
}

private struct TextFieldRow: View {
  let label: String
  let text: Binding<String>
  let width: CGFloat

  init(_ label: String, text: Binding<String>, width: CGFloat) {
    self.label = label
    self.text = text
    self.width = width
  }

  var body: some View {
    GridRow {
      Text(label)
      TextField("", text: text)
        .textFieldStyle(.roundedBorder)
        .frame(width: width)
    }
  }
}

private struct IntFieldRow: View {
  let label: String
  let value: Binding<Int>

  init(_ label: String, value: Binding<Int>) {
    self.label = label
    self.value = value
  }

  var body: some View {
    GridRow {
      Text(label)
      TextField("", value: value, format: .number)
        .textFieldStyle(.roundedBorder)
        .frame(width: 160)
    }
  }
}

private struct ToggleRow: View {
  let label: String
  let isOn: Binding<Bool>

  init(_ label: String, isOn: Binding<Bool>) {
    self.label = label
    self.isOn = isOn
  }

  var body: some View {
    GridRow {
      Text(label)
      Toggle("", isOn: isOn)
        .labelsHidden()
    }
  }
}
