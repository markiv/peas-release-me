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

    func quantityDidChange(on cell: ProductCell, change: Int) {
        updateTotal()
        if change > 0 {
            animateDropIntoCart(cell.productImageView)
        }
    }

    func updateTotal() {
        totalBarItem.title = Currency.current.format(baseAmount: currentTotal)
    }

    func animateDropIntoCart(_ original: UIView?) {
        guard let original = original, let snapshot = original.snapshotView(afterScreenUpdates: false) else { return }
        guard let window = view.window else { return }
        guard cartBarItem.responds(to: #selector(getter: UIInteraction.view)), let cart = cartBarItem.value(forKey: "view") as? UIView else { return }

        if animator == nil {
            animator = UIDynamicAnimator(referenceView: window)
            // A field that pulls objects towards the cart
            pull = UIFieldBehavior.radialGravityField(position: CGPoint(x: 300, y: 400))
            pull.strength = 200
            pull.action = {
                self.pull.items.forEach { item in
                    let d = sqrt(pow(self.pull.position.x - item.center.x, 2) + pow(self.pull.position.y - item.center.y, 2))
                    if d < 100 {
                        // Close enough. Now snap it into place.
                        let snap = UISnapBehavior(item: item, snapTo: self.pull.position)
                        snap.damping = 0.3
                        self.animator.addBehavior(snap)
                        self.pull.removeItem(item)
                        if let v = item as? UIView {
                            // Set up a delayed fade and shrink
                            UIView.animate(withDuration: 0.5, delay: 0.7, options: .curveEaseInOut, animations: {
                                let p = v.center
                                v.frame.size = CGSize(width: 1, height: 1)
                                v.center = p
                                v.alpha = 0
                            }, completion: { complete in
                                self.animator.removeBehavior(snap) // clean up when done
                                v.removeFromSuperview()
                            })
                        }
                    }
                }
            }
            animator.addBehavior(pull)
        }

        // Make snapshot a centered miniature of the original
        snapshot.frame.origin = original.convert(.zero, to: window)
        snapshot.frame = CGRect(x: snapshot.frame.origin.x + 20, y: snapshot.frame.origin.y + 20, width: 40, height: 40)
        window.addSubview(snapshot)

        // Update the gravity field's position to be a little above center of our shopping cart
        pull.position = cart.convert(CGPoint(x: cart.frame.width/2, y: cart.frame.height/2 - 20), to: window)
        pull.addItem(snapshot)

        // Give the item a random kick
        let push = UIPushBehavior(items: [snapshot], mode: .instantaneous)
        push.pushDirection = CGVector(dx: 0, dy: -CGFloat(arc4random_uniform(5))/10)
        push.setTargetOffsetFromCenter(UIOffset(horizontal: 1, vertical: -CGFloat(arc4random_uniform(5))), for: snapshot)
        animator.addBehavior(push)
        push.action = {
            if !push.active {
                self.animator.removeBehavior(push) // clean up when done
            }
        }
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
        let change = Int(stepper.value) - product.quantity
        product.quantity = Int(stepper.value)
        updateContents()
        viewController?.quantityDidChange(on: self, change: change)
    }
}

