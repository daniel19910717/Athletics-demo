import SwiftUI

struct ArticleRow: View {
    let viewModel: ArticleViewModel
    
    var body: some View {
        GeometryReader { proxy in
            AsyncImage(url: viewModel.imageUrl!) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                } else {
                    Color.clear
                }
            }
            .overlay {
                Rectangle()
                    .fill(
                        Gradient(colors: [.clear, .black])
                    )
                    .opacity(0.65)
            }
            .overlay(alignment: .bottomLeading) {
                Text(viewModel.title)
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .padding([.bottom, .horizontal], 16)
            }
        }
        .frame(height: 240)
    }
}

#Preview {
    ArticleRow(
        viewModel: .init(
            article: .init(
                id: "1",
                title: "This is a placeholder title for article rows. This is a placeholder article title.",
                imageUrlString:
                    "https://cdn.theathletic.com/app/uploads/2023/11/06102929/GettyImages-1763970470-1024x683.jpg",
                body: "This is a test",
                createdAt: Date(),
                updatedAt: Date(),
                deletedAt: nil
            )
        )
    )
    .previewLayout(.sizeThatFits)
}
