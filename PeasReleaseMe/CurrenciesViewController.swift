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
    var currencies: [Currency] = []
    var baseAmount: Float = 1.0

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        CurrencyLayerAPI().getLiveQuotes { result in
            if case .success(let liveQuotes) = result {
                self.currencies = liveQuotes.currencies.sorted { $0.currencyCode < $1.currencyCode }
                DispatchQueue.main.async {
                    self.currencyPicker.reloadAllComponents()
                    if let row = self.currencies.index(of: Currency.current) {
                        self.currencyPicker.selectRow(row, inComponent: 0, animated: false)
                    }
                    self.updateAmount()
                }
            }
        }
    }

    func updateAmount() {
        amountLabel.text = Currency.current.format(baseAmount: baseAmount)
    }
}

extension CurrenciesViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return currencies.count
    }
}

extension CurrenciesViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let currency = currencies[row]
        return [currency.currencyCode, currency.countryFlag, currency.currencyName].flatMap{$0}.joined(separator: " ")
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        Currency.current = currencies[row]
        updateAmount()
    }
}
