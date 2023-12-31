//
//  ValueCoordinator
//
//  Created by Max Sol on 05/06/2022.
//

import UIKit
import ValueCoordinator

class ViewController: UIViewController {

    @Coordinated private var text = "111"

    private let label = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()

        $text.onUpdate = { [weak self] in
            let labelText = "Coordinated value: \($0)"
            print(labelText)
            self?.label.text = labelText
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showChild()
        }
    }

    private func showChild() {
        let vc = buildChildVC()

        // Binding
        vc.$text = $text
    }
}

class ChildViewController: UIViewController {

    @ValueProviding var text = "222"

    private let titleLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.text = "333"
        }
    }

}

extension ViewController {

    private func setupUI() {
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func buildChildVC() -> ChildViewController {
        // Show child view controller and give it control over the coordinated property
        let vc = ChildViewController()
        addChild(vc)
        view.addSubview(vc.view)
        vc.view.frame = CGRect(x: 24, y: view.frame.height - 200, width: view.frame.width - 48, height: 200)
        vc.didMove(toParent: self)

        // Dismiss child view controller. Control over the coordinated property is returned to initial controller automatically
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
        }

        return vc
    }

}

extension ChildViewController {

    private func setupUI() {
        view.backgroundColor = .gray

        titleLabel.text = "Child VC"
        view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

}
