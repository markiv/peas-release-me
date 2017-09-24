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

    func testCurrencyNames() {
        XCTAssert(CurrencyLayerAPI.currencyNames?["USD"] == "United States Dollar", "Failed to load currency names")
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

