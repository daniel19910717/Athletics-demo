import SwiftUI

struct ReturnToTopButton: View {
    var body: some View {
        Button(action: {}) {
            Circle()
                .fill(.white)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "chevron.up")
                        .foregroundColor(.black)
                )
        }
    }
}

#Preview {
    ReturnToTopButton()
        .previewLayout(.sizeThatFits)
}
