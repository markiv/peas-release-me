//
//  ViewController.swift
//  Peas Release Me
//
//  Created by Vikram Kriplaney on 22.09.17.
//  Copyright © 2017 Vikram Kriplaney. All rights reserved.
//

import UIKit


class GroceriesViewController: UITableViewController {
    let products = [
        Product(name: "Peas",  image: #imageLiteral(resourceName: "peas"), unit: "bag",    plural: "bags",    price: 0.95),
        Product(name: "Eggs",  image: #imageLiteral(resourceName: "eggs"), unit: "dozen",  plural: "dozen",   price: 2.10),
        Product(name: "Milk",  image: #imageLiteral(resourceName: "milk"), unit: "bottle", plural: "bottles", price: 1.30),
        Product(name: "Beans", image: #imageLiteral(resourceName: "beans"), unit: "can",    plural: "cans",    price: 0.73)
    ]

    @IBOutlet weak var totalBarItem: UIBarButtonItem!

    var currentTotal: Float {
        return products.reduce(0, { partial, product in
            partial + product.price * Float(product.quantity)
        })
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .medium)
        totalBarItem.setTitleTextAttributes([NSAttributedStringKey.font: font,
                                             NSAttributedStringKey.foregroundColor: UIColor.black], for: .disabled)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
        updateTotal()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let vc as CurrenciesViewController:
            vc.baseAmount = currentTotal
        default: break
        }
    }

    func quantityDidChange(on cell: ProductCell) {
        updateTotal()
    }

    func updateTotal() {
        totalBarItem.title = Currency.current.format(baseAmount: currentTotal)
    }
}

// MARK: - UITableViewDataSource
extension GroceriesViewController {
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


// Not a struct but rather a class, so we can keep instances around and modify their quantities
// TODO: Maybe separate quantity away from product?
class Product {
    let name: String
    let image: UIImage
    let unit: String
    let plural: String
    let price: Float
    var quantity = 0

    init(name: String, image: UIImage, unit: String, plural: String, price: Float) {
        self.name = name
        self.image = image
        self.unit = unit
        self.plural = plural
        self.price = price
    }
}

class ProductCell: UITableViewCell {
    @IBOutlet weak var productImageView: UIImageView!
    @IBOutlet weak var productNameLabel: UILabel!
    @IBOutlet weak var quantityStepper: UIStepper!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    weak var viewController: GroceriesViewController?

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
        let priceString = Currency.current.format(baseAmount: product.price) ?? "?"
        priceLabel.text = "\(priceString) a \(product.unit)"
    }

    @IBAction func quantityDidChange(stepper: UIStepper) {
        product.quantity = Int(stepper.value)
        updateContents()
        viewController?.quantityDidChange(on: self)
    }
}
