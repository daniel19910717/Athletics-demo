import SwiftUI

enum ArticleFilterKind: String, Identifiable {
    case league
    case author
    case team

    var id: String { rawValue }

    var title: String {
        switch self {
        case .league: "League"
        case .author: "Author"
        case .team: "Team"
        }
    }
}

struct FilterOption: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String?
}

struct ArticleFilterBar: View {
    let leagueTitle: String
    let authorTitle: String
    let teamTitle: String
    let leagueActive: Bool
    let authorActive: Bool
    let teamActive: Bool
    let showsReset: Bool
    let onLeague: () -> Void
    let onAuthor: () -> Void
    let onTeam: () -> Void
    let onReset: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: leagueTitle,
                    isActive: leagueActive,
                    accessibilityName: "League",
                    action: onLeague
                )
                FilterChip(
                    title: authorTitle,
                    isActive: authorActive,
                    accessibilityName: "Author",
                    action: onAuthor
                )
                FilterChip(
                    title: teamTitle,
                    isActive: teamActive,
                    accessibilityName: "Team",
                    action: onTeam
                )
                if showsReset {
                    Button("Reset", action: onReset)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(.background)
    }
}

private struct FilterChip: View {
    let title: String
    let isActive: Bool
    let accessibilityName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(isActive ? Color(uiColor: .systemBackground) : Color.primary)
            .background(isActive ? Color.primary : Color.clear, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(Color.primary.opacity(isActive ? 0 : 0.2), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isActive ? "\(accessibilityName), \(title)" : "Filter by \(accessibilityName)")
    }
}

struct FilterPickerView: View {
    let title: String
    let note: String?
    let options: [FilterOption]
    let selection: String?
    let isLoaded: Bool
    let onSelect: (String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Group {
                if !isLoaded {
                    ProgressView("Loading")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredOptions.isEmpty {
                    ContentUnavailableView(
                        "No \(title)s",
                        systemImage: "line.3.horizontal.decrease.circle",
                        description: Text(emptyDescription)
                    )
                } else {
                    List {
                        if let note {
                            Text(note)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        allRow
                        ForEach(filteredOptions) { option in
                            optionRow(option)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search \(title.lowercased())s")
            .autocorrectionDisabled()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var allRow: some View {
        Button {
            choose(nil)
        } label: {
            rowLabel(title: "All \(title)s", subtitle: nil, isSelected: selection == nil)
        }
        .buttonStyle(.plain)
    }

    private func optionRow(_ option: FilterOption) -> some View {
        Button {
            choose(option.id)
        } label: {
            rowLabel(
                title: option.title,
                subtitle: option.subtitle,
                isSelected: option.id == selection
            )
        }
        .buttonStyle(.plain)
    }

    private func rowLabel(title: String, subtitle: String?, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundStyle(.primary)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
            }
        }
        .contentShape(Rectangle())
    }

    private var filteredOptions: [FilterOption] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return options }
        return options.filter { option in
            option.title.localizedStandardContains(query)
                || option.subtitle?.localizedStandardContains(query) == true
        }
    }

    private var emptyDescription: String {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            return "Nothing is available to filter by."
        }
        return "No matches for “\(query)”."
    }

    private func choose(_ id: String?) {
        onSelect(id)
        dismiss()
    }
}

#Preview {
    ArticleFilterBar(
        leagueTitle: "NFL",
        authorTitle: "Author",
        teamTitle: "Team",
        leagueActive: true,
        authorActive: false,
        teamActive: false,
        showsReset: true,
        onLeague: {},
        onAuthor: {},
        onTeam: {},
        onReset: {}
    )
}
