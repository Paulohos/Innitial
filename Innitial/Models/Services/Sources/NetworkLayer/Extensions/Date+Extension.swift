import Foundation

extension Date {
    /// Formatter for the wire date format, e.g. "2023-07-21T17:19:29.744Z".
    ///
    /// Built once and reused — `DateFormatter` is expensive to allocate. We use the
    /// `en_US_POSIX` locale, which is the correct choice for fixed-format strings:
    /// it ignores the device's 12h/24h and calendar settings, so the output is stable
    /// regardless of region. The time zone is pinned to UTC because the server always
    /// sends and receives dates at UTC 0.
    private static let utcFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    /// Renders the date in the wire format the server expects, in UTC 0.
    func convertToUTC() -> String {
        Date.utcFormatter.string(from: self)
    }
}
