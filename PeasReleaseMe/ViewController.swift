//
//  ViewController.swift
//  Peas Release Me
//
//  Created by Vikram Kriplaney on 22.09.17.
//  Copyright © 2017 Vikram Kriplaney. All rights reserved.
//

import UIKit

// Not a struct but rather a class, so we can keep them around and modify their quantities
class Product {
    let name: String
    let image: UIImage
    let unit: String
    let plural: String
    let price: Float
    var quantity: Int

    init(name: String, image: UIImage, unit: String, plural: String, price: Float, quantity: Int) {
        self.name = name
        self.image = image
        self.unit = unit
        self.plural = plural
        self.price = price
        self.quantity = quantity
    }
}

class ProductCell: UITableViewCell {
    @IBOutlet weak var productImageView: UIImageView!
    @IBOutlet weak var productNameLabel: UILabel!
    @IBOutlet weak var quantityStepper: UIStepper!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    weak var viewController: ViewController?

    static let priceFormatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.currencyCode = "USD"
        return nf
    }()

    var product: Product! {
        didSet {
            updateContents()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        quantityLabel.font = .monospacedDigitSystemFont(ofSize: quantityLabel.font.pointSize, weight: .bold)
    }

    func updateContents() {
        productImageView.image = product.image
        productNameLabel.text  = product.name
        quantityLabel.text = String(describing: product.quantity)
        let priceString = ProductCell.priceFormatter.string(from: NSNumber(value: product.price))!
        priceLabel.text = "\(priceString) a \(product.unit)"
    }

    @IBAction func quantityDidChange(stepper: UIStepper) {
        product.quantity = Int(stepper.value)
        updateContents()
        viewController?.quantityDidChange(on: self)
    }
}

class ViewController: UITableViewController {

    @IBOutlet weak var totalBarItem: UIBarButtonItem!

    let products = [
        Product(name: "Peas",  image: #imageLiteral(resourceName: "peas"), unit: "bag",    plural: "bags",    price: 0.95, quantity: 0),
        Product(name: "Eggs",  image: #imageLiteral(resourceName: "eggs"), unit: "dozen",  plural: "dozen",   price: 2.10, quantity: 0),
        Product(name: "Milk",  image: #imageLiteral(resourceName: "milk"), unit: "bottle", plural: "bottles", price: 1.30, quantity: 0),
        Product(name: "Beans", image: #imageLiteral(resourceName: "beans"), unit: "can",    plural: "cans",    price: 0.73, quantity: 0)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        let font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .medium)
        totalBarItem.setTitleTextAttributes([NSAttributedStringKey.font: font,
                                             NSAttributedStringKey.foregroundColor: UIColor.black], for: .disabled)
        updateTotal()
    }

    func quantityDidChange(on cell: ProductCell) {
        updateTotal()
    }

    func updateTotal() {
        let total = products.reduce(0, { partial, product in
            partial + product.price * Float(product.quantity)
        })
        totalBarItem.title = ProductCell.priceFormatter.string(from: NSNumber(value: total))
    }
}

// MARK: - UITableViewDataSource
extension ViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell", for: indexPath) as! ProductCell
        cell.product = products[indexPath.row]
        cell.viewController = self
        return cell
    }
}
