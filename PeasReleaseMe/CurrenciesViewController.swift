//
//  CurrenciesViewController.swift
//  PeasReleaseMe
//
//  Created by Vikram Kriplaney on 24.09.17.
//  Copyright © 2017 Vikram Kriplaney. All rights reserved.
//

import UIKit

func emojiFlag(_ countryCode: String) -> String {
    let kBase: UInt32 = 0x1F1E6 - 65
    let code = countryCode.uppercased()
    var emoji = ""
    for scalar in code.unicodeScalars {
        if let scalar = UnicodeScalar(kBase + scalar.value) {
            emoji.append(String(describing: scalar))
        }
    }
    return emoji
}


class CurrenciesViewController: UIViewController {
    @IBOutlet weak var currencyPicker: UIPickerView!
    @IBOutlet weak var amountLabel: UILabel!
    var liveQuotes: CurrencyLayerAPI.LiveQuotes?
    var quoteCodes: [String] = []
    var baseAmount: Float = 1.0

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        CurrencyLayerAPI().getLiveQuotes { result in
            if case .success(let liveQuotes) = result {
                self.liveQuotes = liveQuotes
                self.quoteCodes = Array(liveQuotes.quotes.keys).sorted()
                print(liveQuotes.timestamp)
                DispatchQueue.main.async {
                    self.currencyPicker.reloadAllComponents()
                    self.updateAmount()
                }
            }
        }
    }

    func updateAmount() {
        let row = currencyPicker.selectedRow(inComponent: 0)
        let quoteCode = quoteCodes[row]
        let rate = liveQuotes?.quotes[quoteCode] ?? 1
        let currency = CurrencyLayerAPI.Currency(quoteCode: quoteCode, exchangeRate: rate)
        amountLabel.text = currency.format(baseAmount: baseAmount)
    }
}



extension CurrenciesViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return liveQuotes?.quotes.count ?? 0
    }
}

extension CurrenciesViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let quoteCode = quoteCodes[row]
        let currency = CurrencyLayerAPI.Currency(quoteCode: quoteCode, exchangeRate: 1)
        return [currency.currencyCode, currency.countryFlag, currency.currencyName].flatMap{$0}.joined(separator: " ")
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        updateAmount()
    }
}
