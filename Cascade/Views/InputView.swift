import UIKit
import UIKitCompatKit
import UIKitExtensions
import SwiftcordLegacy
import SFSymbolsCompatKit


public class InputView: UIView, UITextViewDelegate {
    public weak var snapshotView: UIView?
    public let backgroundView: LiquidGlassView = {
        let bView = LiquidGlassView(blurRadius: 6, cornerRadius: 20, snapshotTargetView: nil, disableBlur: PerformanceManager.disableBlur)
        bView.translatesAutoresizingMaskIntoConstraints = false
        bView.solidViewColour = .discordGray.withAlphaComponent(0.8)
        bView.scaleFactor = PerformanceManager.scaleFactor
        bView.frameInterval = PerformanceManager.frameInterval
        return bView
    }()
    public var channel: TextChannel?
    public var tokenInputView: Bool?
    
    let buttonBackground = LiquidGlassView(blurRadius: 6, cornerRadius: 20, snapshotTargetView: nil, disableBlur: PerformanceManager.disableBlur)
    
    var replyMessage: Message?
    var editMessage: Message?
    
    public enum inputMode {
        case edit, reply, send
    }
    
    public let textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .clear
        textView.textColor = .white
        textView.font = UIFont.systemFont(ofSize: 18)
        textView.isScrollEnabled = false
        textView.contentInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        return textView
    }()
    
    
    
    public let sendButton = LargeHitAreaButton()
    
    public init(channel: TextChannel, snapshotView: UIView, tokenInputView: Bool = false) {
        super.init(frame: .zero)
        self.snapshotView = snapshotView
        self.channel = channel
        self.tokenInputView = tokenInputView
        setupSubviews()
        setupConstraints()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.snapshotView = nil
        self.channel = nil
        setupSubviews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupSubviews() {
        
        backgroundView.snapshotTargetView = snapshotView
        addSubview(backgroundView)
        
        textView.delegate = self
        backgroundView.addSubview(textView)
        
        //sendButton.setTitle("Send", for: .normal)
        sendButton.setImage(.init(systemName: "paperplane", tintColor: .white), for: .normal)
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        
        
        buttonBackground.scaleFactor = 0.25
        buttonBackground.snapshotTargetView = snapshotView
        buttonBackground.frameInterval = 6
        buttonBackground.solidViewColour = .discordGray.withAlphaComponent(0.8)
        addSubview(buttonBackground)
        buttonBackground.pinToCenter(of: sendButton)
        buttonBackground.heightAnchor.constraint(equalToConstant: 40).isActive = true
        buttonBackground.widthAnchor.constraint(equalToConstant: 40).isActive = true
        buttonBackground.isUserInteractionEnabled = false
        sendButton.sendSubviewToBack(buttonBackground)
        //Must use weak self or else the whole inputview gets retained 
        sendButton.addAction(for: .touchUpInside) { [weak self] in
            self?.sendMessageAction()
        }
        
        
        addSubview(sendButton)
        bringSubviewToFront(sendButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: self.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -60)
        ])
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: backgroundView.topAnchor),
            textView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor)
        ])
        
        sendButton.centerYAnchor.constraint(equalTo: textView.centerYAnchor).isActive = true
        sendButton.leadingAnchor.constraint(equalTo: textView.trailingAnchor, constant: 20).isActive = true
        sendButton.heightAnchor.constraint(equalTo: backgroundView.heightAnchor).isActive = true
        
        
    }
    
    public func editMessage(_ message: Message) {
        self.changeInputMode(to: .edit)
        self.editMessage = message
        self.textView.text = self.editMessage?.content
        self.textViewDidChange(self.textView)
    }
    
    public func replyToMessage(_ message: Message) {
        self.changeInputMode(to: .reply)
        self.replyMessage = message
    }
    
    public func changeInputMode(to mode: inputMode) {
        switch mode {
        case .reply:
            sendButton.removeAllActions()
            sendButton.addAction(for: .touchUpInside) { [weak self] in
                self?.replyMessageAction()
            }
        case .edit:
            sendButton.removeAllActions()
            sendButton.addAction(for: .touchUpInside) { [weak self] in
                self?.editMessageAction()
            }
        case .send:
            sendButton.removeAllActions()
            sendButton.addAction(for: .touchUpInside) { [weak self] in
                self?.sendMessageAction()
            }
        }
    }
    
    
    private func replyMessageAction() {
        self.sendButton.isUserInteractionEnabled = false
        
        guard let channel = self.channel, let dmVC = parentViewController as? DMViewController, let replyMessage = self.replyMessage else { return }
        
        let newMessage = Message(clientUser, ["content": self.textView.text])
        
        clientUser.reply(to: replyMessage, with: newMessage, in: channel) { error in
            self.textView.text = nil
            self.editMessage = nil
            self.changeInputMode(to: .send)
            self.sendButton.isUserInteractionEnabled = true
        }
    }
    
    private func sendMessageAction() {
        self.sendButton.isUserInteractionEnabled = false
        
        guard let channel = self.channel else { return }
        
        let message = Message(clientUser, ["content": self.textView.text])
        
        clientUser.send(message: message, in: channel) { [weak self] error in
            guard let self = self else { return }
            self.textView.text = nil
            self.textViewDidChange(self.textView)
            self.sendButton.isUserInteractionEnabled = true
        }
    }
    
    private func editMessageAction() {
        self.sendButton.isUserInteractionEnabled = false
        
        guard let channel = self.channel, let dmVC = parentViewController as? DMViewController, let editMessage = self.editMessage else { return }
        
        let newMessage = Message(clientUser, ["content": self.textView.text])
        
        clientUser.edit(message: editMessage, to: newMessage, in: channel) { error in
            self.textView.text = nil
            self.editMessage = nil
            self.changeInputMode(to: .send)
            self.sendButton.isUserInteractionEnabled = true
        }
    }
    
    
    public func textViewDidChange(_ textView: UITextView) {
        guard let dmVC = parentViewController as? DMViewController, let navBarHeight = dmVC.navigationController?.navigationBar.frame.height else { return }
        let maxHeight = dmVC.view.bounds.height - 50 - navBarHeight
        backgroundView.frameInterval = 60*60*60
        let width = textView.bounds.width > 0 ? textView.bounds.width : 100 // fallback
        let size = textView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        let clampedHeight = max(40, min(size.height, maxHeight))
        
        textView.isScrollEnabled = size.height > maxHeight
        
        if clampedHeight != self.bounds.height {
            self.invalidateIntrinsicContentSize()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.backgroundView.frameInterval = 6
        }
    }
    
    
    public override var intrinsicContentSize: CGSize {
        guard let dmVC = parentViewController as? DMViewController, let navBarHeight = dmVC.navigationController?.navigationBar.frame.height else { return .zero }
        let maxHeight = dmVC.view.bounds.height - 50 - navBarHeight
        let width = textView.bounds.width > 0 ? textView.bounds.width : 100
        let size = textView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        let height = max(40, min(size.height, maxHeight))
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }
}


public class LargeHitAreaButton: UIButton {
    var hitAreaInset: UIEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
    
    init(hitAreaInset: UIEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)) {
        self.hitAreaInset = hitAreaInset
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let largerFrame = bounds.inset(by: hitAreaInset)
        return largerFrame.contains(point)
    }
}

