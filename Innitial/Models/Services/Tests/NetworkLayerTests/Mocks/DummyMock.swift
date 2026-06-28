import Foundation

/// `{"dummy": "dummy"}` — a valid body for `Dummy`.
let dummyMock = Data("""
{ "dummy": "dummy" }
""".utf8)

struct Dummy: Codable, Equatable {
    var dummy: String
}

/// `{}` — decodes into `NoReply`, but not into `DefaultError` (missing title/message).
let emptyMock = Data("{}".utf8)

struct NoReply: Decodable {}

/// A well-formed server error body (decodes into `DefaultError`).
let defaultErrorMock = Data("""
{
  "code": 123,
  "title": "Server title",
  "message": "Server message"
}
""".utf8)
