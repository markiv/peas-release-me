//
//  ShopViewController.swift
//  Peas Release Me
//
//  Created by Vikram Kriplaney on 22.09.17.
//  Copyright © 2017 Vikram Kriplaney. All rights reserved.
//

import UIKit


class ShopViewController: UITableViewController {
    let products = [
        Product(name: "Peas",  image: #imageLiteral(resourceName: "peas"), unit: "bag",    plural: "bags",    price: 0.95),
        Product(name: "Eggs",  image: #imageLiteral(resourceName: "eggs"), unit: "dozen",  plural: "dozen",   price: 2.10),
        Product(name: "Milk",  image: #imageLiteral(resourceName: "milk"), unit: "bottle", plural: "bottles", price: 1.30),
        Product(name: "Beans", image: #imageLiteral(resourceName: "beans"), unit: "can",    plural: "cans",    price: 0.73)
    ]

    @IBOutlet weak var totalBarItem: UIBarButtonItem!
    @IBOutlet weak var cartBarItem: UIBarButtonItem!

    var animator: UIDynamicAnimator!
    var pull: UIFieldBehavior!

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
        navigationItem.rightBarButtonItem?.title = (Currency.current.countryFlag ?? "") + Currency.current.currencyCode
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
        animateDropIntoCart(cell.productImageView)
    }

    func animateDropIntoCart(_ original: UIView?) {
        guard let original = original, let snapshot = original.snapshotView(afterScreenUpdates: false) else { return }
        guard let window = view.window else { return }
        guard cartBarItem.responds(to: #selector(getter: UIInteraction.view)), let cart = cartBarItem.value(forKey: "view") as? UIView else { return }

        if animator == nil {
            animator = UIDynamicAnimator(referenceView: window)
            pull = UIFieldBehavior.radialGravityField(position: CGPoint(x: 300, y: 400))
            pull.strength = 100
//            pull.animationSpeed = 5
            pull.action = {
                self.pull.items.forEach { item in
                    let d = self.pull.position.y - item.center.y
                    if d < -50 || item.center.x < 0 {
                        self.pull.removeItem(item)
                        (item as? UIView)?.removeFromSuperview()
                    }
                    let scale = max(0.2, min(2*d/window.frame.height, 1))
                    item.transform = CGAffineTransform(scaleX: scale, y: scale)
                    (item as? UIView)?.alpha = scale
                    self.animator.updateItem(usingCurrentState: item)
                    print(d)
                }
            }
            animator.addBehavior(pull)
        }
        snapshot.frame.origin = original.convert(.zero, to: window)
        window.addSubview(snapshot)

//        let snap = UISnapBehavior(item: snapshot, snapTo: cart.convert(.zero, to: window))
//        snap.damping = 0
//        animator.addBehavior(snap)

//        let dynamic = UIDynamicItemBehavior(items: [snapshot])
//        dynamic.resistance = 100
//        dynamic.friction = 100
//        animator.addBehavior(dynamic)

        pull.position = cart.convert(.zero, to: window)
        pull.addItem(snapshot)
        animator.addBehavior(pull)

        let push = UIPushBehavior(items: [snapshot], mode: .instantaneous)
        push.pushDirection = CGVector(dx: 0, dy: -1)
        push.setTargetOffsetFromCenter(UIOffset(horizontal: 1, vertical: -1), for: snapshot)
        animator.addBehavior(push)

    }

    func updateTotal() {
        totalBarItem.title = Currency.current.format(baseAmount: currentTotal)
    }
}

// MARK: - UITableViewDataSource
extension ShopViewController {
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
    weak var viewController: ShopViewController?

    var product: Product! {
        didSet {
            updateContents()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        quantityLabel.font = .monospacedDigitSystemFont(ofSize: quantityLabel.font.pointSize, weight: .medium)
        productImageView.layer.borderColor = UIColor.lightGray.cgColor
        priceLabel.numberOfLines = 2
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

