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

        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        $text.onUpdate = { [weak self] in
            let labelText = "Coordinated value: \($0)"
            print(labelText)
            self?.label.text = labelText
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showChild()
        }
    }

    private func showChild() {
        // Show child view controller and give it control over the coordinated property
        let vc = ChildViewController()
        addChild(vc)
        view.addSubview(vc.view)
        vc.view.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 200)
        vc.didMove(toParent: self)

        // Binding
        vc.$text = $text

        // Dismiss child view controller. Control over the coordinated property is returned to initial controller automatically
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
        }
    }
}

class ChildViewController: UIViewController {

    @ValueProviding var text = "222"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .blue

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.text = "333"
        }
    }

}
