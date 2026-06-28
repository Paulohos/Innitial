import Foundation

private extension NetworkService {

    /// The main back-end interface for `async` `NetworkService` calls. This specific function is marked  `private`, but it handles all the relevant logic.
    /// The actual `public` calls below just wrap this in an logging block, and allows `AsyncCallBuilder` to generate the list of `failures`.
    ///
    /// - Parameters:
    ///   - endpoint: Which endpoint to call
    ///   - body: Body object
    ///   - success: The success status matcher
    ///   - shouldRetundDefaultError: If `true` it won't return the error retrieved from server, but  a `DefaultError` object
    ///   - retryOn401: If true, we will retry on 401 as long as `success` and `failures`
    /// - Returns: The decoded valid API response.
    private func callAsync(
        endpoint: Endpoint,
        body: Data?,
        additionalSettings: [AdditionalSettings],
        shouldReturnDefaultError: Bool
    ) async throws -> Data {
        let actuallyRetryOn401 =
            endpoint.requiresAccessToken

        let (status, data) = try await request(for: endpoint, body: body, retryOn401: actuallyRetryOn401, additionalSettings: additionalSettings, shouldReturnDefaultError: shouldReturnDefaultError)

        switch status {
        case 200...299:
            return data
        default:
            var errorHandle: Error
            do {
                /// This implementation limits the reusability of the framework across different projects.
                /// To enable reuse, adjustments in this section are necessary.
                /// Specifically, we must ensure the generation of the appropriate error object or directly return the `data`.
                /// This project adheres to a standard error structure for errors falling within the range of 400 to 499,
                /// such as {code: 123, title: "Oops... something went wrong", message: "Email or password invalid"}.
                var defaultError = try sharedJSONDecoder.decode(DefaultError.self, from: data)
                // Preserve the server's business error code (e.g. 123 = "invalid password").
                // Only fall back to the HTTP status when the body didn't carry one.
                if defaultError.code == .zero {
                    defaultError.code = status
                }
                errorHandle = NetworkServiceError.defaultError(defaultError)
            } catch {
                errorHandle = handleErrorReturns(
                    shouldReturnDefaultError,
                    errorReturn: unhandledStatusError(status, data: data),
                    statusCode: status
                )
            }
            throw errorHandle
        }
    }

    private func wrapInErrorLogger<R>(for endpoint: Endpoint, function: () async throws -> R) async throws -> R {
        do {
            let value = try await function()
            logger.debug("\(String(describing: endpoint)) 🌐 Call succeeded! ✅")
            return value
        } catch is CancellationError {
            logger.notice("\(String(describing: endpoint)) 🌐 CancellationError ❌")
            throw NetworkServiceError.cancelledRequest
        }
        catch {
            logger.error("\(String(describing: endpoint)) 🌐 Call failed with error: \(error) ❌")
            throw error
        }
    }

}

// MARK: Actual Public Methods
extension NetworkService {
    public func call<Return: Decodable>(
        endpoint: Endpoint,
        body: (any Encodable)? = nil,
        additionalSettings: [AdditionalSettings] = [],
        shouldReturnDefaultError: Bool = true
    ) async throws -> Return {
        try await wrapInErrorLogger(for: endpoint) {
            let data = try await callAsync(
                endpoint: endpoint,
                body: try body?.asData(),
                additionalSettings: additionalSettings,
                shouldReturnDefaultError: shouldReturnDefaultError
            )

            do {
                return try sharedJSONDecoder.decode(Return.self, from: data)
            } catch {
                throw handleErrorReturns(
                    shouldReturnDefaultError,
                    errorReturn: NetworkServiceError.jsonParsingFailure
                )
            }
        }
    }

    public func call(
        endpoint: Endpoint,
        body: (any Encodable)? = nil,
        additionalSettings: [AdditionalSettings] = [],
        shouldReturnDefaultError: Bool = true
    ) async throws {
        try await wrapInErrorLogger(for: endpoint) {
            _ = try await callAsync(
                endpoint: endpoint,
                body: try body?.asData(),
                additionalSettings: additionalSettings,
                shouldReturnDefaultError: shouldReturnDefaultError
            )
        }
    }
}
