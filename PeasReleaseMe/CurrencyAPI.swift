//
//  CurrencyModel.swift
//  Peas Release Me
//
//  Created by Vikram Kriplaney on 22.09.17.
//  Copyright © 2017 Vikram Kriplaney. All rights reserved.
//

import Foundation

/// A generic API we can potentially reuse
public class GenericAPI {

    enum ApiResult<T> {
        case success(T)
        case failure(Error)
    }
    static let bundle = Bundle.init(for: GenericAPI.self)
    let decoder = JSONDecoder()

    /// Simply gets any decodable object from any URL
    func get<T>(from url: URL, completion: @escaping (ApiResult<T>) -> ()) where T: Decodable {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data, let value = try? self.decoder.decode(T.self, from: data) {
                completion(.success(value))
            }
        }.resume()
    }
}

/// Wraps the API for getting live currency quotes
public class CurrencyLayerAPI: GenericAPI {

    /// Represents CurrencyLayer's response
    struct LiveQuotes: Decodable {
        let timestamp: Date
        let source: String
        let quotes: [String: Float]
    }

    enum CurrencyAPIError: Error {
        case badURL
        case missingAPIKey
    }

    public static let currencyNames: [String: String]? = {
        guard let url = GenericAPI.bundle.url(forResource: "currency-names", withExtension: "json"),
        let data = try? Data(contentsOf: url, options: []) else {
            return nil
        }
        return try? JSONDecoder().decode([String: String].self, from: data)
    }()

    static let baseURL = URL(string: "http://apilayer.net/api/")!
    /// The API key from our Info.plist
    static let apiKey = bundle.object(forInfoDictionaryKey: "CurrencyLayerAPIKey") as? String

    func getLiveQuotes(completion: @escaping (ApiResult<LiveQuotes>) -> ()) {
        guard let apiKey = CurrencyLayerAPI.apiKey else {
            completion(.failure(CurrencyAPIError.missingAPIKey))
            return
        }
        guard let endpoint: URL = (URL(string: "live", relativeTo: CurrencyLayerAPI.baseURL).flatMap {
            var components = URLComponents(url: $0, resolvingAgainstBaseURL: true)
            components?.queryItems = [URLQueryItem(name: "access_key", value: apiKey)]
            return components?.url
        }) else {
            completion(.failure(CurrencyAPIError.badURL))
            return
        }

        decoder.dateDecodingStrategy = .secondsSince1970 // CurrencyLayer uses Unix timestamps
        // After all that fancy URL building, this one-liner actually does the real work 😎
        get(from: endpoint, completion: completion)
    }
}
