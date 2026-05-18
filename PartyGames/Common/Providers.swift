import Foundation

// MARK: - URL Session Provider

public protocol URLSessionProviding: Sendable {
    func data(from url: URL) async throws -> (Data, URLResponse)
}

public struct DefaultURLSessionProvider: URLSessionProviding {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func data(from url: URL) async throws -> (Data, URLResponse) {
        try await session.data(from: url)
    }
}

// MARK: - Key-Value Storage Provider

public protocol KeyValueStorageProviding: Sendable {
    func data(forKey key: String) -> Data?
    func set(_ data: Data?, forKey key: String)
}

public struct DefaultKeyValueStorageProvider: KeyValueStorageProviding {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func data(forKey key: String) -> Data? {
        defaults.data(forKey: key)
    }

    public func set(_ data: Data?, forKey key: String) {
        defaults.set(data, forKey: key)
    }
}
