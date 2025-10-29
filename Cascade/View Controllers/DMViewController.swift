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
    
    let backgroundGradient = CAGradientLayer()
    let scrollView = UIScrollView()
    let containerView = UIView()
    var containerViewBottomConstraint: NSLayoutConstraint!
    
    var tapGesture: UITapGestureRecognizer!
    
    private var observers = [NSObjectProtocol]()
    
    var isKeyboardVisible = false
    
    let logger = LegacyLogger(fileName: "legacy_debug.txt")
    
    var dmStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 12
        stack.distribution = .fill
        stack.alignment = .fill
        return stack
    }()
    
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
        
        SetStatusBarBlackTranslucent()
        SetWantsFullScreenLayout(self, true)
        
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    func attachGatewayObservers() {
        guard let gateway = clientUser.gateway else { return }

        // Assign closures
        gateway.onMessageCreate = { [weak self] message in
            self?.createMessage(message)
        }
        gateway.onMessageUpdate = { [weak self] message in
            self?.updateMessage(message)
        }
        gateway.onMessageDelete = { [weak self] message in
            self?.deleteMessage(message)
        }
    }


    
    
    //Websocket create message function
    func createMessage(_ message: Message) {
        //Unwrap optionals and check if the stack already contains the message we are about to add
        if let messageID = message.id, let userID = message.author?.id, !messageIDsInStack.contains(messageID), self.dm?.id == message.channelID {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {return }
                self.dmStack.addArrangedSubview(MessageView(clientUser, message: message))
                self.messageIDsInStack.insert(messageID)
                
                //If it's a new user, add it to the list of users
                if !self.userIDsInStack.contains(userID) { self.userIDsInStack.insert(userID) }
                
                self.scrollView.layoutIfNeeded()
                //self.scrollToBottom(animated: true)
            }
        }
    }
    
    func deleteMessage(_ message: Message) {
        for view in dmStack.arrangedSubviews {
            if let messageView = view as? MessageView, messageView.message?.id == message.id {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction, .curveEaseInOut], animations: {
                        self.dmStack.removeArrangedSubview(messageView)
                        self.view.layoutIfNeeded()
                    }, completion: nil)
                }
            }
        }
    }
    
    func updateMessage(_ message: Message) {
        for view in dmStack.arrangedSubviews {
            if let messageView = view as? MessageView, messageView.message?.id == message.id {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction, .curveEaseInOut], animations: {
                        messageView.updateMessage(message)
                        self.view.layoutIfNeeded()
                    }, completion: nil)
                }
            }
        }
    }
    
    func setupKeyboardObservers() {
        let center = NotificationCenter.default
        
        observers.append(center.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] notification in
            self?.keyboardWillAppear(notification: notification as NSNotification)
        })
        
        observers.append(center.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] notification in
            self?.keyboardWillDisappear(notification: notification as NSNotification)
        })
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.isEnabled = false
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Make tap wait to see if hold activates
        if gestureRecognizer is UITapGestureRecognizer, otherGestureRecognizer is UILongPressGestureRecognizer {
            return true
        }
        return false
    }
    



    
    @objc private func dismissKeyboard() {
        print("tap")
        view.endEditing(true)
    }
    
    func setupSubviews() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        dmStack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(containerView)
        containerView.addSubview(scrollView)
        scrollView.addSubview(dmStack)
        
        containerView.alpha = 0
        
    }
    
    
    func scrollToMessage(withID messageID: Snowflake) {
        guard let navBarHeight = navigationController?.navigationBar.frame.height else { return }
        let padding: CGFloat = 10

        for view in dmStack.arrangedSubviews {
            guard let messageView = view as? MessageView, messageView.message?.id == messageID else { continue }

            self.view.layoutIfNeeded()
            scrollView.layoutIfNeeded()
            dmStack.layoutIfNeeded()

            // Convert messageView frame to scrollView coordinates
            let messageFrameInScroll = messageView.convert(messageView.bounds, to: scrollView)

            // Top of scrollView visible area (below navbar)
            let visibleTop = scrollView.contentOffset.y + navBarHeight + padding

            // Only scroll if message is above the visible area
            if messageFrameInScroll.minY < visibleTop {
                let newOffsetY = messageFrameInScroll.minY - navBarHeight - padding

                // Clamp to scrollable range
                let maxOffsetY = scrollView.contentSize.height - scrollView.bounds.height + scrollView.contentInset.bottom
                let clampedOffsetY = max(0, min(newOffsetY, maxOffsetY))

                scrollView.setContentOffset(CGPoint(x: 0, y: clampedOffsetY), animated: true)
            }
            return
        }
    }

    
    func takeMessageAction(_ message: Message) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        applyGaussianBlur(to: containerView.layer, radius: 12)
        let messageActionView = MessageActionView(clientUser, message, self.dm!)
        messageActionView.alpha = 0
        messageActionView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        view.addSubview(messageActionView)
        messageActionView.translatesAutoresizingMaskIntoConstraints = false
        messageActionView.pinToCenter(of: view)
        CATransaction.commit()
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
            messageActionView.alpha = 1
            messageActionView.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.containerView.isUserInteractionEnabled = false
            if let nav = UIApplication.shared.keyWindow?.rootViewController as? CustomNavigationController {
                nav.navBarOpacity = 0
            }
        }
    }

    
    func endMessageAction() {
        UIView.animate(withDuration: 0.3, animations: {
            for subview in self.view.subviews {
                if subview is MessageActionView {
                    subview.alpha = 0
                    subview.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                }
            }
            self.containerView.isUserInteractionEnabled = true
            self.containerView.layer.filters = nil
            
            if let nav = UIApplication.shared.windows.first?.rootViewController as? CustomNavigationController {
                nav.navBarOpacity = 1
            }
        }, completion: { _ in
            for subview in self.view.subviews {
                if subview is MessageActionView {
                    subview.removeFromSuperview()
                }
            }
        })
    }

    
    //REST API past 50 message get function
    func getMessages() {
        guard let dm = dm, let id = dm.id else { return }
        
        
        clientUser.getChannelMessages(for: id) { [weak self] messages, error in
            guard let self = self else { return }
            
            self.addMessagesToStack(messages)
            
            if !self.initialViewSetupComplete {
                self.setupInputView(for: dm)
            }
            
            //Fade on container
            if self.containerView.alpha == 0 {
                UIView.animate(withDuration: 0.35, delay: 0, options: [.curveEaseInOut]) {
                    self.containerView.alpha = 1
                }
            }
        }
    }
    
    //Add messages fetched via REST API to the stack
    func addMessagesToStack(_ messages: [Message]) {
        for message in messages {
            if let messageID = message.id, let userID = message.author?.id, !messageIDsInStack.contains(messageID) {
                let messageView = MessageView(clientUser, message: message)
                self.dmStack.addArrangedSubview(messageView)
                messageIDsInStack.insert(messageID)
                scrollView.layoutIfNeeded()
                scrollToBottom(animated: true)
                if !userIDsInStack.contains(userID) { userIDsInStack.insert(userID) }
            }
        }
    }
    
    func setupInputView(for dm: DMChannel) {
        textInputView = InputView(channel: dm, snapshotView: view)
        guard let textInputView = textInputView else {
            return
        }

        containerView.addSubview(textInputView)
        textInputView.translatesAutoresizingMaskIntoConstraints = false
        
        textInputView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20).isActive = true
        textInputView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        textInputView.widthAnchor.constraint(equalTo: containerView.widthAnchor, constant: -20).isActive = true
        
        view.layoutIfNeeded()
        scrollView.contentInset.bottom = textInputView.bounds.height + 10
        scrollView.contentInset.top = (navigationController?.navigationBar.frame.height)!
        
        scrollView.layoutIfNeeded()
        scrollToBottom(animated: false)
        
        initialViewSetupComplete = true
    }
    
    func setupConstraints() {
        dmStack.pinToEdges(of: scrollView, insetBy: .init(top: 20, left: 20, bottom: 20, right: 20))
        dmStack.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
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
    
    func animatedBackground() {
        backgroundGradient.frame = view.frame
        backgroundGradient.colors = [self.view.backgroundColor?.cgColor, self.view.backgroundColor?.cgColor]
        view.layer.insertSublayer(backgroundGradient, below: view.layer.superlayer)
        animateGradient()
    }
    
    func animateGradient(completion: (() -> Void)? = nil) {
        var avatarColors: [UIColor] = []
        var gradientColors: [CGColor] = []
        
        var dmRecipients: [User] = []
        
        if let dm = self.dm as? DM, let recipient = dm.recipient {
            dmRecipients.append(recipient)
        } else if let groupDM = self.dm as? GroupDM, let recipients = groupDM.recipients {
            for recipient in recipients {
                dmRecipients.append(recipient)
            }
        }
        
        for recipient in dmRecipients {
            AvatarCache.shared.avatar(for: recipient) { image, color in
                guard let color = color else { return }
                avatarColors.append(color)
            }
        }
        
        
        
        for color in avatarColors {
            gradientColors.append(color.cgColor)
            gradientColors.append(UIColor.random(around: color, variance: 0.1).cgColor)
        }
        
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.backgroundGradient.colors = gradientColors
            self?.animateGradient(completion: completion)
        }
        
        let animation = CABasicAnimation(keyPath: "colors")
        animation.duration = 3.0
        animation.toValue = gradientColors
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        backgroundGradient.add(animation, forKey: "colorChange")
        CATransaction.commit()
    }
    
    
    
    @objc private func keyboardWillAppear(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        containerViewBottomConstraint.constant = -keyboardFrame.cgRectValue.height
        
        UIView.animate(withDuration: 0.3) {
            self.tapGesture.isEnabled = true
            self.view.layoutIfNeeded()
            self.scrollView.layoutIfNeeded()
            self.scrollToBottom(animated: true)
            self.isKeyboardVisible = true
        }
    }
    
    @objc private func keyboardWillDisappear(notification: NSNotification) {
        containerViewBottomConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.tapGesture.isEnabled = false
            self.view.layoutIfNeeded()
            self.isKeyboardVisible = false
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view is UIControl || touch.view is UITextView {
            return false
        }
        return true
    }

    
    private var navigationBarHeight: CGFloat {
        if #available(iOS 7.0.1, *) {
            return navigationController?.navigationBar.frame.height ?? 0
        } else {
            return 0
        }
    }

}

import UIKit
import QuartzCore

public func applyGaussianBlur(to layer: CALayer, radius: CGFloat) {
    // Get the CAFilter class dynamically
    guard let CAFilterClass = NSClassFromString("CAFilter") as AnyObject as? NSObjectProtocol else {
        print("CAFilter not available")
        return
    }

    // Create a Gaussian blur filter
    let blurFilter = CAFilterClass.perform(NSSelectorFromString("filterWithName:"), with: "gaussianBlur")?.takeUnretainedValue()

    // Set the blur radius
    blurFilter?.perform(NSSelectorFromString("setValue:forKey:"), with: radius, with: "inputRadius")

    // Apply the filter to the layer
    layer.setValue([blurFilter as Any].compactMap { $0 }, forKey: "filters")
}
