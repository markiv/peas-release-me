//
//  CurrencyAPI.swift
//  Peas Release Me
//
//  Created by Vikram Kriplaney on 22.09.17.
//  Copyright © 2017 Vikram Kriplaney. All rights reserved.
//

import Foundation

/// A generic API we could potentially reuse
public class GenericAPI {

    enum ApiResult<T> {
        case success(T)
        case failure(Error)
    }
    static let bundle = Bundle.init(for: GenericAPI.self)
    let decoder = JSONDecoder()

    /// Simply gets any Decodable object from any URL
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

    /// Represents CurrencyLayer's full response
    struct LiveQuotes: Decodable {
        let timestamp: Date
        let source: String
        let quotes: [String: Float]
    }

    /// A more convenient representation for our display purposes
    struct Currency: Decodable {
        let currencyCode: String
        let exchangeRate: Float

        init(quoteCode: String, exchangeRate: Float) {
            self.currencyCode = String(quoteCode.suffix(3))
            self.exchangeRate = exchangeRate
        }
    }

    enum CurrencyAPIError: Error {
        case badURL
        case missingAPIKey
    }

    static let baseURL = URL(string: "http://apilayer.net/api/")!
    /// The API key from our Info.plist
    static let apiKey = bundle.object(forInfoDictionaryKey: "CurrencyLayerAPIKey") as? String

    func getLiveQuotes(completion: @escaping (ApiResult<LiveQuotes>) -> ()) {
        // Build our endpoint URL (would have been a lot simpler to just hardwire it)
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

extension CurrencyLayerAPI.Currency {
    /// A lookup table loaded lazily (and synchronously) from our bundle
    public static let currencyNames: [String: String]? = {
        guard let url = GenericAPI.bundle.url(forResource: "currency-names", withExtension: "json"),
        let data = try? Data(contentsOf: url, options: []) else {
            return nil
        }
        return try? JSONDecoder().decode([String: String].self, from: data)
    }()

    /// Gets the currency's name from our lookup table
    public var currencyName: String? {
        return CurrencyLayerAPI.Currency.currencyNames?[currencyCode]
    }

    /// Gets an emoji flag for the currency, e.g. "🇨🇭"
    public var countryFlag: String? {
        // Exceptions to the rule (Bitcoins are not from Bhutan!)

        guard currencyCode != "BTC" else { return "\u{20BF}" } // the new Bitcoin character in Unicode 10 (iOS 11)
        guard !currencyCode.hasPrefix("X") else { return nil }

        let countryCode = currencyCode.prefix(2) // according to ISO 4217
        let unicodeBase: UInt32 = 0x1F1E6 - 65 // Regional Indicator Symbol Letter [A]
        var emoji = ""
        for scalar in countryCode.unicodeScalars {
            if let scalar = UnicodeScalar(unicodeBase + scalar.value) {
                emoji.append(String(describing: scalar))
            }
        }
        return emoji
    }

    /// Converts and formats a base amount (in USD)
    public func format(baseAmount: Float) -> String? {
        let formatter = NumberFormatter()
        formatter.currencyCode = currencyCode
        formatter.numberStyle = .currency
        formatter.usesSignificantDigits = true
        formatter.minimumSignificantDigits = 4

        // Some local currency symbols NumberFormatter doesn't yet know about (https://www.unicode.org/charts/PDF/Unicode-10.0/U100-20A0.pdf)
        switch currencyCode {
        case "BTC": formatter.currencySymbol = "\u{20BF}" // the new Bitcoin character in Unicode 10 (iOS 11)
        case "THB": formatter.currencySymbol = "฿" // Baht, not Bitcoin
        case "NGN": formatter.currencySymbol = "₦"
        case "RUB": formatter.currencySymbol = "₽"
        case "GEL": formatter.currencySymbol = "₾"
        case "PHP": formatter.currencySymbol = "₱"
        case "PYG": formatter.currencySymbol = "₲"
        case "GHC": formatter.currencySymbol = "₵"
        case "KZT": formatter.currencySymbol = "₸"
        case "UAH": formatter.currencySymbol = "₴"
        case "TRY": formatter.currencySymbol = "₺"
        case "AZN": formatter.currencySymbol = "₼"
        case "LAK": formatter.currencySymbol = "₭"
        case "MNT": formatter.currencySymbol = "₮"
        case "CRC", "SVC": formatter.currencySymbol = "₡"
        default: break
        }
        return formatter.string(from: NSNumber(value: exchangeRate * baseAmount))
    }
}
