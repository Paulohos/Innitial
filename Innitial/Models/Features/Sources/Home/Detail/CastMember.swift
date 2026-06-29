//
//  CastMember.swift
//  Features
//

/// A cast member shown in "Elenco principal". This data isn't part of the movie
/// detail endpoint — it'll be fetched from the credits endpoint later.
struct CastMember: Identifiable, Hashable {
    let id: Int
    let name: String
    let profilePath: String?
}

#if DEBUG
extension CastMember {
    static let mock: [CastMember] = (0..<6).map {
        CastMember(id: $0, name: "Sandra Bullock", profilePath: nil)
    }
}
#endif
