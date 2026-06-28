import Foundation

extension Encodable {
    /// Encodes the value into JSON `Data`.
    ///
    /// Throws `NetworkServiceError.bodyEncodingFailure` instead of silently
    /// returning `nil`, so an unencodable body fails the request loudly rather
    /// than being sent as a request with no body.
    func asData() throws -> Data {
        do {
            return try sharedJSONEncoder.encode(self)
        } catch {
            throw NetworkServiceError.bodyEncodingFailure(error)
        }
    }
}
