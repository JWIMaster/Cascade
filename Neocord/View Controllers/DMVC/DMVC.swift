//
//  DMView.swift
//  MakingADiscordAPI
//
//  Created by JWI on 19/10/2025.
//

import UIKit
import UIKitCompatKit
import FoundationCompatKit
import SwiftcordLegacy
import UIKitExtensions
import OAStackView
import iOS6BarFix
import LiveFrost


class DMViewController: UIViewController, UIGestureRecognizerDelegate {
    public var dm: DMChannel?
    var textInputView: InputView?
    var messageIDsInStack = Set<Snowflake>()
    var userIDsInStack = Set<Snowflake>()
    var initialViewSetupComplete = false
    var profileView: ProfileView?
    
    let backgroundGradient = CAGradientLayer()
    let scrollView = UIScrollView()
    let containerView = UIView()
    var containerViewBottomConstraint: NSLayoutConstraint!
    
    var tapGesture: UITapGestureRecognizer!
    
    var observers = [NSObjectProtocol]()
    
    var isKeyboardVisible = false
    
    let logger = LegacyLogger(fileName: "legacy_debug.txt")
    
    var messageStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 12
        stack.distribution = .fill
        stack.alignment = .fill
        return stack
    }()
    
    var profileBlur = LiquidGlassView(blurRadius: 12, cornerRadius: 0, snapshotTargetView: nil, disableBlur: false, filterOptions: [])
    
    public init(dm: DMChannel) {
        super.init(nibName: nil, bundle: nil)
        self.dm = dm
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        view.backgroundColor = .discordGray
        
        title = {
            if let dm = dm as? DM {
                return dm.recipient?.nickname ?? dm.recipient?.displayname ?? dm.recipient?.username
            } else if let dm = dm as? GroupDM {
                return dm.name
            } else {
                return "Unknown"
            }
        }()
        
        
        
        if #unavailable(iOS 7.0.1) {
            SetStatusBarBlackTranslucent()
            SetWantsFullScreenLayout(self, true)
        }
        
        setupKeyboardObservers()
        setupSubviews()
        setupConstraints()
        getMessages()
        attachGatewayObservers()
        animatedBackground()
        
        guard let gateway = clientUser.gateway else { return }
        
        gateway.onReconnect = { [weak self] in
            guard let self = self else { return }
            self.attachGatewayObservers()
        }
    }

    
    func setupSubviews() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        messageStack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(containerView)
        containerView.addSubview(scrollView)
        scrollView.addSubview(messageStack)
        
        containerView.alpha = 0
        
    }
    
    func setupConstraints() {
        messageStack.pinToEdges(of: scrollView, insetBy: .init(top: 20, left: 20, bottom: 20, right: 20))
        messageStack.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        scrollView.pinToEdges(of: containerView)
        scrollView.pinToCenter(of: containerView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor, constant: UIApplication.shared.statusBarFrame.height),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ])
        
        containerViewBottomConstraint = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        containerViewBottomConstraint.isActive = true
    }
    
    
    func scrollToBottom(animated: Bool) {
        let bottomOffset = CGPoint(x: 0,y: max(0, scrollView.contentSize.height - scrollView.bounds.height + scrollView.contentInset.bottom))
        scrollView.setContentOffset(bottomOffset, animated: animated)
    }

    
    var navigationBarHeight: CGFloat {
        return navigationController?.navigationBar.frame.height ?? 0
    }
    
  

}
