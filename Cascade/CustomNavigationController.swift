import UIKit
import UIKitCompatKit
import UIKitExtensions

public class CustomNavigationController: UINavigationController {

    private let customNavBar: LiquidGlassView = {
        let glassView = LiquidGlassView(blurRadius: 6, cornerRadius: 12, snapshotTargetView: nil, disableBlur: PerformanceManager.disableBlur)
        glassView.frameInterval = PerformanceManager.frameInterval
        glassView.scaleFactor = PerformanceManager.scaleFactor
        glassView.solidViewColour = UIColor(red: 0.2, green: 0.2, blue: 0.22, alpha: 0.8)
        glassView.translatesAutoresizingMaskIntoConstraints = false
        return glassView
    }()
    
    weak var snapshotTargetView: UIView?
    
    public var navBarFrame: UIView = UIView()

    private let titleLabel = UILabel()
    private let backButton = UIButton(type: .custom)

    public var navBarOpacity: CGFloat {
        get { customNavBar.alpha }
        set { customNavBar.alpha = max(0, min(1, newValue)) } // clamp 0–1
    }
    
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        // Hide the default navbar
        navBarFrame = UIView(frame: navigationBar.frame)
        setNavigationBarHidden(true, animated: false)
        isNavigationBarHidden = true

        // Add LiquidGlassView
        view.addSubview(customNavBar)
        view.bringSubviewToFront(customNavBar)
        layoutCustomNavBar()


        // Setup title and back button
        setupTitleAndBack()

        // Update navbar whenever top VC changes
        delegate = self
        updateTitle(for: topViewController)
        updateBackButton(for: topViewController)
    }

    private func layoutCustomNavBar() {
        customNavBar.widthAnchor.constraint(equalToConstant: navBarFrame.frame.width*0.9).isActive = true
        customNavBar.heightAnchor.constraint(equalToConstant: navBarFrame.frame.height).isActive = true
        customNavBar.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        customNavBar.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 22).isActive = true
    }

    private func setupTitleAndBack() {
        // Title label
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textColor = .white
        titleLabel.backgroundColor = .clear
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        customNavBar.addSubview(titleLabel)

        // Back button
        backButton.setTitle("Back", for: .normal)
        backButton.setTitleColor(.white, for: .normal)
        backButton.backgroundColor = .clear
        backButton.translatesAutoresizingMaskIntoConstraints = false
        customNavBar.addSubview(backButton)
        backButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: customNavBar.centerXAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: customNavBar.bottomAnchor, constant: -10),
            backButton.leadingAnchor.constraint(equalTo: customNavBar.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: customNavBar.centerYAnchor)
        ])
    }

    @objc private func goBack() {
        popViewController(animated: true)
    }

    private func updateTitle(for viewController: UIViewController?) {
        titleLabel.text = viewController?.title
        //titleLabel.setIsHidden(viewController == viewControllers.first, animated: true)
    }

    private func updateBackButton(for viewController: UIViewController?) {
        //backButton.isHidden = viewController == viewControllers.first
        backButton.setIsHidden(viewController == viewControllers.first, animated: true)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        guard let superview = self.view.superview else { return }
        self.snapshotTargetView = superview
        self.customNavBar.snapshotTargetView = snapshotTargetView
    }
    
    private func updateNavBar(for viewController: UIViewController?) {
        guard let viewController = viewController else { return }

        let isRoot = (viewController == viewControllers.first)
        let newTitle = viewController.title ?? ""

        titleLabel.isHidden = false
        titleLabel.text = newTitle
        titleLabel.alpha = 0

        if isRoot {
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
                self.backButton.alpha = 0
                self.titleLabel.alpha = 1
            } completion: { _ in
                self.backButton.isHidden = true
            }
        } else {
            self.backButton.isHidden = false
            self.backButton.alpha = 0
            self.titleLabel.alpha = 0
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
                self.backButton.alpha = 1
                self.titleLabel.alpha = 1
            }
        }
    }





}

// MARK: - UINavigationControllerDelegate
extension CustomNavigationController: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        updateNavBar(for: viewController)
    }
}


public extension UIView {
    func setIsHidden(_ hidden: Bool, animated: Bool) {
        if animated {
            if self.isHidden && !hidden {
                self.alpha = 0.0
                self.isHidden = false
            }
            UIView.animate(withDuration: 0.25, animations: {
                self.alpha = hidden ? 0.0 : 1.0
            }) { (complete) in
                self.isHidden = hidden
            }
        } else {
            self.isHidden = hidden
        }
    }
}
