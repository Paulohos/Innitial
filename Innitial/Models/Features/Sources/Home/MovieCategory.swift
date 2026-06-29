//
//  MovieCategory.swift
//  Features
//

/// A movie list category shown on Home. Used as the navigation value for the
/// "Ver todos" full-list screen and to title each section.
enum MovieCategory: Hashable {
    case popular
    case topRated
    case nowPlaying
    case upcoming

    var title: String {
        switch self {
        case .popular: "Mais populares"
        case .topRated: "Mais bem avaliados"
        case .nowPlaying: "Em cartaz"
        case .upcoming: "Em breve"
        }
    }
}
