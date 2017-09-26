//
//  CurrenncyApiTests.swift
//  PeasReleaseMeTests
//
//  Created by Vikram Kriplaney on 23.09.17.
//  Copyright © 2017 Vikram Kriplaney. All rights reserved.
//

import XCTest
@testable import PeasReleaseMe

class CurrenncyApiTests: XCTestCase {
    let api = CurrencyLayerAPI()

    func testCurrency() {
        // Measure how long it takes to load and parse the bundled JSON
        var currency: Currency?
        measure {
            currency = .current
            XCTAssert(currency?.currencyCode == "USD", "Wrong code for default currency")
        }

        let usd = Currency.current
        XCTAssert(usd.currencyCode == "USD", "Wrong code for default currency")
        XCTAssert(usd.currencyName == "United States Dollar", "Wrong name for default currency")
        XCTAssert(usd.countryFlag == "🇺🇸", "Wrong flag for default currency")
        XCTAssert(usd.exchangeRate == 1.0, "Wrong rate for default currency")
        XCTAssert(usd.format(baseAmount: 1) == "$1.00", "Wrong formatting")

        let chf = Currency(quoteCode: "USDCHF", exchangeRate: 1.1)
        XCTAssert(chf.currencyCode == "CHF", "Wrong code for currency")
        XCTAssert(chf.currencyName == "Swiss Franc", "Wrong name for currency")
        XCTAssert(chf.countryFlag == "🇨🇭", "Wrong flag for currency")
        XCTAssert(chf.format(baseAmount: 1) == "CHF1.10", "Wrong formatting")
    }

    func testLiveQuotes() {
        let gotLiveQuotes = expectation(description: "Got live quotes")
        api.getLiveQuotes { result in
            if case .success(let quotes) = result {
                XCTAssert(quotes.source == "USD", "Source currency is not USD 🙁")
                gotLiveQuotes.fulfill()
            } else if case .failure(let error) = result {
                XCTFail(String(describing: error))
            } else {
                XCTFail("Unknown failure")
            }
        }
        waitForExpectations(timeout: 10)
    }
}

