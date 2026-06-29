//
//  HomeHeader.swift
//  Features
//

import SwiftUI
import DesignSystem

/// The Home greeting: a large title on the left and the user's avatar on the right.
struct HomeHeader: View {
    var avatarURL: URL?

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text("O que você quer assistir hoje?")
                .textStyle(.largeTitle)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            AvatarView(imageURL: avatarURL, size: 52)
        }
    }
}
