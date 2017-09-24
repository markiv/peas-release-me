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

    /// Simply gets any decodable object from any URL
    func get<T>(from url: URL, completion: @escaping (ApiResult<T>) -> ()) where T: Decodable {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data, let value = try? JSONDecoder().decode(T.self, from: data) {
                completion(.success(value))
            }
        }.resume()
    }
}

public class CurrencyLayerAPI: GenericAPI {

    struct LiveQuotes: Decodable {
        let source: String
        let quotes: [String: Float]
    }

    enum CurrencyAPIError: Error {
        case badURL
        case missingAPIKey
    }

    struct Config {
        static let baseUrl = URL(string: "http://apilayer.net/api/")!
        static let apiKey = "2f1b6ecd6365d706410395de50736c2d"
    }

    func getLiveQuotes(completion: @escaping (ApiResult<LiveQuotes>) -> ()) {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "CurrencyLayerAPIKey") as? String else {
            completion(.failure(CurrencyAPIError.missingAPIKey))
            return
        }
        guard let endpoint = URL(string: "live", relativeTo: Config.baseUrl),
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: true) else {
            completion(.failure(CurrencyAPIError.badURL))
            return
        }
        components.queryItems = [URLQueryItem(name: "access_key", value: apiKey)]
        guard let url = components.url else {
            completion(.failure(CurrencyAPIError.badURL))
            return
        }

        get(from: url, completion: completion)
    }

}

