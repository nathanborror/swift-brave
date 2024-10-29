import Foundation

public actor Client {
    
    public static let defaultHost = URL(string: "https://api.search.brave.com/res/v1")!
    
    public let host: URL
    public let token: String
    
    internal(set) public var session: URLSession
    
    public init(session: URLSession = URLSession(configuration: .default), host: URL = defaultHost, token: String) {
        var host = host
        if !host.path.hasSuffix("/") {
            host = host.appendingPathComponent("")
        }
        self.host = host
        self.session = session
        self.token = token
    }
    
    public enum Error: Swift.Error, CustomStringConvertible {
        case requestError(String)
        case responseError(response: HTTPURLResponse, detail: String)
        case decodingError(response: HTTPURLResponse, detail: String)
        case unexpectedError(String)
        
        public var description: String {
            switch self {
            case .requestError(let detail):
                return "Request error: \(detail)"
            case .responseError(let response, let detail):
                return "Response error (Status \(response.statusCode)): \(detail)"
            case .decodingError(let response, let detail):
                return "Decoding error (Status \(response.statusCode)): \(detail)"
            case .unexpectedError(let detail):
                return "Unexpected error: \(detail)"
            }
        }
    }
    
    private struct ErrorResponse: Decodable {
        let error: String
    }
    
    enum Method: String, Hashable {
        case get = "GET"
        case post = "POST"
        case delete = "DELETE"
    }
    
    func fetch<T: Decodable>(_ method: Method, _ path: String, params: [String: Value]? = nil) async throws -> T {
        let url = host.appending(path: path)
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)

        var httpBody: Data? = nil
        switch method {
        case .get:
            if let params {
                var queryItems: [URLQueryItem] = []
                for (key, value) in params {
                    queryItems.append(URLQueryItem(name: key, value: value.description))
                }
                urlComponents?.queryItems = queryItems
            }
        case .post, .delete:
            if let params {
                let encoder = JSONEncoder()
                httpBody = try encoder.encode(params)
            }
        }

        guard let url = urlComponents?.url else {
            throw Error.requestError(
                #"Unable to construct URL with host "\#(host)" and path "\#(path)""#)
        }
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = method.rawValue

        print(url.absoluteString)
        
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        request.addValue(token, forHTTPHeaderField: "X-Subscription-Token")

        if let httpBody {
            request.httpBody = httpBody
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw Error.unexpectedError("Response is not HTTPURLResponse")
        }

        switch httpResponse.statusCode {
        case 200..<300:
            if T.self == Bool.self {
                // If T is Bool, we return true for successful response
                return true as! T
            } else if data.isEmpty {
                throw Error.responseError(response: httpResponse, detail: "Empty response body")
            } else {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds

                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    throw Error.decodingError(
                        response: httpResponse,
                        detail: "Error decoding response: \(error.localizedDescription)"
                    )
                }
            }
        default:
            if T.self == Bool.self {
                // If T is Bool, we return false for unsuccessful response
                return false as! T
            }

            if let errorDetail = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw Error.responseError(response: httpResponse, detail: errorDetail.error)
            }

            if let string = String(data: data, encoding: .utf8) {
                throw Error.responseError(response: httpResponse, detail: string)
            }

            throw Error.responseError(response: httpResponse, detail: "Invalid response")
        }
    }
}

extension Client {
    
    public struct SearchResponse: Codable, Sendable {
        public let type: String
        public let query: Query
        public let web: Search?
        public let videos: Videos?
        public let news: News?
        
        public struct Query: Codable, Sendable {
            public let original: String
        }
        
        public struct Search: Codable, Sendable {
            public let type: String
            public let results: [SearchResult]
            public let mutated_by_goggles: Bool?
            public let family_friendly: Bool?
        }
        
        public struct SearchResult: Codable, Sendable {
            public let type: String
            public let subtype: String
            public let url: URL
            public let title: String
            public let description: String
            public let profile: Profile
            public let thumbnail: Thumbnail?
            public let age: String?
            public let page_age: String?
            public let language: String
            public let family_friendly: Bool
            public let meta_url: MetaURL
            public let is_source_local: Bool
            public let is_source_both: Bool
            public let cluster_type: String?
            public let cluster: [Cluster]?
            
            public struct Profile: Codable, Sendable {
                public let name: String
                public let url: String
                public let long_name: String
                public let img: String
            }
            
            public struct Cluster: Codable, Sendable {
                public let title: String
                public let url: String
                public let description: String
                public let family_friendly: Bool
                public let is_source_local: Bool
                public let is_source_both: Bool
            }
        }
        
        // News
        
        public struct News: Codable, Sendable {
            public let type: String
            public let results: [NewsResult]
            public let mutated_by_goggles: Bool?
            public let family_friendly: Bool?
        }
        
        public struct NewsResult: Codable, Sendable {
            public let url: URL
            public let title: String
            public let description: String
            public let is_source_local: Bool
            public let is_source_both: Bool
            public let age: String?
            public let page_age: String?
            public let family_friendly: Bool
            public let breaking: Bool
            public let meta_url: MetaURL
            public let thumbnail: Thumbnail?
        }
        
        // Video
        
        public struct Videos: Codable, Sendable {
            public let type: String
            public let results: [VideoResult]
            public let mutated_by_goggles: Bool?
            public let family_friendly: Bool?
        }
        
        public struct VideoResult: Codable, Sendable {
            public let url: URL
            public let title: String
            public let description: String
            public let type: String
            public let meta_url: MetaURL
            public let thumbnail: Thumbnail?
            public let age: String?
            public let page_age: String?
        }
        
        // Shared
        
        public struct Thumbnail: Codable, Sendable {
            public let src: String
            public let original: String
            public let logo: Bool?
        }
        
        public struct MetaURL: Codable, Sendable {
            public let scheme: String
            public let netloc: String
            public let hostname: String
            public let favicon: String
            public let path: String
        }
    }
    
    public func search(query: String) async throws -> SearchResponse {
        let params: [String: Value] = ["q": .string(query)]
        return try await fetch(.get, "web/search", params: params)
    }
}
