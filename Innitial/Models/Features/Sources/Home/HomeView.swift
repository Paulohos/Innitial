//
//  SwiftUIView.swift
//  Features
//
//  Created by Paulo Henrique Oliveira Souza on 28/06/26.
//

import SwiftUI
import DesignSystem

struct HomeView: View {
    @State var viewModel: HomeViewModel
    
    var body: some View {
        Text("Hello, World!")
            .appBackground()
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel())
}
