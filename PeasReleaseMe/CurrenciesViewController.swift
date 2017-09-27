//
//  CurrenciesViewController.swift
//  PeasReleaseMe
//
//  Created by Vikram Kriplaney on 24.09.17.
//  Copyright © 2017 Vikram Kriplaney. All rights reserved.
//

import UIKit


class CurrenciesViewController: UIViewController {

    @IBOutlet weak var currencyPicker: UIPickerView!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    var currencies: [Currency] = []
    var baseAmount: Float = 1.0

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        CurrencyLayerAPI().getLiveQuotes { result in
            switch result {
            case .success(let liveQuotes):
                self.currencies = liveQuotes.currencies.sorted { $0.currencyCode < $1.currencyCode }
                self.update(timestamp: liveQuotes.timestamp)
            case .failure(let error):
                self.show(error: error)
            }
            self.updateView()
        }
    }

    func updateView() {
        DispatchQueue.main.async {
            self.spinner.stopAnimating()
            self.currencyPicker.reloadAllComponents()
            if let row = self.currencies.index(of: Currency.current) {
                self.currencyPicker.selectRow(row, inComponent: 0, animated: false)
            }
            self.updateAmount()
        }
    }

    func updateAmount() {
        amountLabel.text = Currency.current.format(baseAmount: baseAmount)
    }

    func update(timestamp: Date) {
        DispatchQueue.main.async {
            self.timestampLabel.text = "Live Quotes updated "
                + DateFormatter.localizedString(from: timestamp, dateStyle: .long, timeStyle: .long)
            self.timestampLabel.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }

    func show(error: Error) {        
        let alert = UIAlertController(title: "Oops", message:
            "There was a problem updating our exchange rates. Please try again later.\n\n(\(error.localizedDescription))",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
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
        guard row < currencies.count else { return }
        Currency.current = currencies[row]
        updateAmount()
    }
}
