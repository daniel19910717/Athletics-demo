import SwiftUI

struct ArticleDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let viewModel: ArticleViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerImage
                Text(viewModel.title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
                Text(viewModel.body)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineSpacing(5)
                    .textSelection(.enabled)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
            }
        }
        .background(Color(uiColor: .systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
            }
            ToolbarItem(placement: .principal) {
                Text("Articles")
                    .font(.headline)
                    .foregroundStyle(.black)
            }
        }
    }

    private var headerImage: some View {
        Color.secondary.opacity(0.15)
            .frame(height: 260)
            .frame(maxWidth: .infinity)
            .overlay {
                if let imageUrl = viewModel.imageUrl {
                    AsyncImage(url: imageUrl) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                    }
                }
            }
            .clipped()
            .accessibilityHidden(true)
    }
}

#Preview {
    NavigationStack {
        ArticleDetailView(
            viewModel: ArticleViewModel(
                article: Article(
                    id: "1",
                    title: "This is a placeholder title for the article detail view.",
                    imageUrlString: "https://cdn.theathletic.com/app/uploads/2023/11/06102929/GettyImages-1763970470-1024x683.jpg",
                    body: "This is a test article body.\n\nIt has a second paragraph.",
                    createdAt: Date(),
                    updatedAt: Date(),
                    deletedAt: nil,
                    author: nil,
                    league: nil,
                    team: nil
                )
            )
        )
    }
}
