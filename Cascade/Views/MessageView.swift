//
//  MessageView.swift
//  MakingADiscordAPI
//
//  Created by JWI on 18/10/2025.
//

import Foundation
import UIKit
import UIKitCompatKit
import UIKitExtensions
import SwiftcordLegacy
import TSMarkdownParser
import FoundationCompatKit



public class MessageView: UIView, UIGestureRecognizerDelegate {
    let messageContent: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 6
        stack.distribution = .equalSpacing
        return stack
    }()
    var messageText = UILabel()
    var messageAttachments: UIImageView?
    var authorAvatar: UIImageView = UIImageView()
    public var averageAvatarColor: UIColor?
    let authorName = UILabel()
    let timestamp = UILabel()
    let edited = UILabel()
    let messageBackground: UIView? = {
        switch device {
        case .a4:
            return UIView()
        default:
            return LiquidGlassView(blurRadius: 0, cornerRadius: 22, snapshotTargetView: nil, disableBlur: true)
        }
    }()
    var slClient: SLClient?
    var message: Message?
    var reply: ReplyMessage?
    var replyView: ReplyMessageView?
    var isClientUser: Bool?
    var markdownParser: TSMarkdownParser = TSMarkdownParser.standard()
    
    static let markdownQueue: DispatchQueue = DispatchQueue(label: "com.jwi.markdownrender", attributes: .concurrent, target: .global(qos: .userInitiated))
    
    static let avatarQueue: DispatchQueue = DispatchQueue(label: "com.jwi.avatarQueue", attributes: .concurrent, target: .global(qos: .userInitiated))
    
    public init(_ slClient: SLClient, message: Message) {
        super.init(frame: .zero)
        self.slClient = slClient
        self.message = message
        self.isClientUser = {
            return message.author == slClient.clientUser
        }()
        self.setup()
    }
    
    
    private func setup() {
        setupText()
        setupBackground()
        setupAuthorName()
        setupAuthorAvatar()
        setupEdited()
        setupTimestamp()
        setupGestureRecogniser()
        setupReply()
        setupSubviews()
        setupContraints()
        setupAttachments()
    }
    
    private func setupSubviews() {
        guard let messageBackground = messageBackground else { return }
        
        if let replyView = replyView {
            replyView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(replyView)
        }
        
        
        messageContent.addArrangedSubview(messageText)
        addSubview(messageContent)
        addSubview(messageBackground)
        sendSubviewToBack(messageBackground)
        addSubview(authorName)
        addSubview(timestamp)
        addSubview(edited)
        addSubview(authorAvatar)
    }
    
    private func setupText() {
        messageText.translatesAutoresizingMaskIntoConstraints = false
        
        messageText.text = "\(message?.content ?? "unknown")"
        messageText.backgroundColor = .clear
        messageText.textColor = .white
        messageText.lineBreakMode = .byWordWrapping
        messageText.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 80
        messageText.numberOfLines = 0
        messageText.sizeToFit()
        
        MessageView.markdownQueue.async { [weak self] in
            guard let self = self else { return }
            let parsed = self.markdownParser.attributedString(fromMarkdown: "\(self.message?.content ?? "unknown")")
            
            DispatchQueue.main.async {
                
                self.messageText.attributedText = parsed
                self.messageText.sizeToFit()
                self.setNeedsLayout()
                self.layoutIfNeeded()
                
                // Give Auto Layout a short delay to settle before scrolling
                guard let parentVC = self.parentViewController else { return }
                if let dmVC = parentVC as? DMViewController {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        dmVC.scrollToBottom(animated: true)
                    }
                }
                
            }
        }
    }
    
    private func setupBackground() {
        guard let messageBackground = messageBackground else { return }
        
        messageBackground.translatesAutoresizingMaskIntoConstraints = false
        messageBackground.isUserInteractionEnabled = false
        
        if let messageBackground = messageBackground as? LiquidGlassView {
            messageBackground.shadowOpacity = 0.3
            messageBackground.shadowRadius = 6
            messageBackground.solidViewColour = .discordGray
        } else {
            messageBackground.backgroundColor = .discordGray
        }
        
        messageBackground.sizeToFit()
    }
    
    private func setupAuthorName() {
        authorName.text = message?.author?.nickname ?? message?.author?.displayname ?? message?.author?.username
        authorName.font = .boldSystemFont(ofSize: 14)
        authorName.textColor = .white
        authorName.backgroundColor = .clear
        authorName.translatesAutoresizingMaskIntoConstraints = false
        authorName.sizeToFit()
    }
    
    private func setupEdited() {
        edited.text = {
            guard let message = message else {
                return ""
            }

            if message.edited {
                return "(edited)"
            } else {
                return ""
            }
        }()
        edited.font = .systemFont(ofSize: 10)
        edited.textColor = .gray
        edited.backgroundColor = .clear
        edited.translatesAutoresizingMaskIntoConstraints = false
        edited.sizeToFit()
    }
    
    private func setupReply() {
        guard let replyMessage = message?.replyMessage, let slClient = self.slClient else { return }
        self.replyView = ReplyMessageView(slClient, reply: replyMessage)
    }
    
    private func setupAuthorAvatar() {
        guard let author = message?.author else { return }
        
        authorAvatar = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        authorAvatar.translatesAutoresizingMaskIntoConstraints = false
        
        AvatarCache.shared.avatar(for: author) { [weak self] image, color in
            guard let self = self, let image = image, let color = color else { return }
            
            MessageView.avatarQueue.async {
                let resized = image.resizeImage(image, targetSize: CGSize(width: 30, height: 30))
                
                DispatchQueue.main.async {
                    self.authorAvatar.image = resized
                    self.authorAvatar.contentMode = .scaleAspectFit
                    self.authorAvatar.layer.shadowPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 30, height: 30), cornerRadius: 15).cgPath
                    self.authorAvatar.layer.shadowRadius = 6
                    self.authorAvatar.layer.shadowOpacity = 0.5
                    self.authorAvatar.layer.shadowColor = UIColor.black.cgColor
                    self.authorAvatar.layer.shouldRasterize = true
                    self.authorAvatar.layer.rasterizationScale = UIScreen.main.scale
                    
                    if let messageBackground = self.messageBackground as? LiquidGlassView {
                        messageBackground.tintColorForGlass = color.withIncreasedSaturation(factor: 1.4).withAlphaComponent(0.4)
                        messageBackground.shadowColor = color.withIncreasedSaturation(factor: 1.4).withAlphaComponent(1).cgColor
                        messageBackground.shadowOpacity = 0.6
                        messageBackground.setNeedsLayout()
                    } else {
                        self.messageBackground?.backgroundColor = color.withIncreasedSaturation(factor: 1.4)
                        self.messageBackground?.setNeedsLayout()
                    }
                }
            }
        }
    }
    
    
    private func setupTimestamp() {
        guard let messageTimestamp = message?.timestamp else { return }
        let formatter = DateFormatter()
        let calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_AU_POSIX")
        formatter.dateStyle = {
            if calendar.isDateInToday(messageTimestamp) || calendar.isDateInYesterday(messageTimestamp) {
                return .none
            } else {
                return .short
            }
        }()
        
        formatter.timeStyle = .short
        
        timestamp.text = {
            if calendar.isDateInYesterday(messageTimestamp) {
                return String("Yesterday at ").appending(formatter.string(from: messageTimestamp))
            } else {
                return formatter.string(from: messageTimestamp)
            }
        }()
        
        timestamp.font = .systemFont(ofSize: 12)
        timestamp.textColor = .white
        timestamp.backgroundColor = .clear
        timestamp.translatesAutoresizingMaskIntoConstraints = false
        timestamp.sizeToFit()
    }
    
    private func getAttachment(attachment: Attachment) {
        guard let attachmentWidth = attachment.width, let attachmentHeight = attachment.height else { return }
        
        let aspectRatio = attachmentWidth / attachmentHeight
        let width = UIScreen.main.bounds.width-40
        let height = width / aspectRatio
        let scaledSize = CGSize(width: width, height: height)
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        self.messageAttachments = imageView
        
        self.messageContent.addArrangedSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: self.messageContent.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: self.messageContent.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1/aspectRatio)
        ])
        
        attachment.fetch { [weak self] attachment in
            guard let self = self, let image = attachment as? UIImage else { return }
            DispatchQueue.global(qos: .userInitiated).async {
                autoreleasepool {
                    let resizedImage = image.resizeImage(image, targetSize: scaledSize)
                    DispatchQueue.main.async {
                        imageView.image = resizedImage
                    }
                }
            }
        }
    }
    
    //MARK: TODO cannot fix multi attachments on iOS 6 it is slow as hell for some reason
    private func setupAttachments() {
        guard let message = message else {
            return
        }
        
        if #available(iOS 7.0.1, *) {
            setupAttachments7()
        } else {
            guard let firstAttachment = message.attachments.first else { return }
            getAttachment(attachment: firstAttachment)
        }
    }
    
    private func setupAttachments7() {
        guard let message = message else { return }
        let attachments = message.attachments
        guard !attachments.isEmpty else { return }
        var index = 0
        
        //Stack of all the attachments
        let attachmentStack = UIStackView()
        attachmentStack.axis = .vertical
        attachmentStack.spacing = 8
        attachmentStack.distribution = .fillEqually
        attachmentStack.translatesAutoresizingMaskIntoConstraints = false
        
        while index < attachments.count {
            //Stack for row of 2 attachments
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 8
            rowStack.distribution = .fillEqually
            rowStack.translatesAutoresizingMaskIntoConstraints = false
            
            // Add up to 2 attachments per row
            for increment in 0...1 where index + increment < attachments.count {
                let attachment = attachments[index + increment]
                
                guard let attachmentWidth = attachment.width, let attachmentHeight = attachment.height else { return }
                
                let aspectRatio = attachmentWidth / attachmentHeight
                let width = (UIScreen.main.bounds.width-40)/2
                let height = width / aspectRatio
                let scaledSize = CGSize(width: width, height: height)
                
                let imageView = UIImageView()
                imageView.contentMode = .scaleAspectFit
                imageView.translatesAutoresizingMaskIntoConstraints = false
                
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageClick))
                tapGesture.cancelsTouchesInView = false
                tapGesture.delegate = self
                imageView.addGestureRecognizer(tapGesture)
                imageView.isUserInteractionEnabled = true
                rowStack.addArrangedSubview(imageView)
                
                //Set height or else behaves poorly
                imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1/aspectRatio).isActive = true
                
                // Fetch image async
                attachment.fetch { [weak imageView] attachment in
                    guard let imageView = imageView, let image = attachment as? UIImage else { return }
                    DispatchQueue.global(qos: .userInitiated).async {
                        autoreleasepool {
                            let resizedImage = image.resizeImage(image, targetSize: scaledSize)
                            DispatchQueue.main.async {
                                imageView.image = resizedImage
                                imageView.backgroundColor = .clear
                            }
                        }
                    }
                }
            }
            attachmentStack.addArrangedSubview(rowStack)
            //Move onto next pair
            index += 2
        }
        self.messageContent.addArrangedSubview(attachmentStack)
    }
    
    private func setupGestureRecogniser() {
        let tapGesture = UILongPressGestureRecognizer(target: self, action: #selector(messageAction))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        self.addGestureRecognizer(tapGesture)
        self.isUserInteractionEnabled = true
    }
    
    @objc private func imageClick(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended, let imageView = gesture.view as? UIImageView, let image = imageView.image else { return }
        
        let newImageView = UIImageView(image: image)
        newImageView.contentMode = .scaleAspectFit
        newImageView.translatesAutoresizingMaskIntoConstraints = false
        
        let vc = AttachmentViewController(attachment: newImageView)
        self.parentViewController?.navigationController?.pushViewController(vc, animated: true)
    }
    
    
    
    @objc private func messageAction(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let dmVC = parentViewController as? DMViewController else { return }
        dmVC.takeMessageAction(self.message!)
    }
    
    
    
    private func setupContraints() {
        guard let messageBackground = messageBackground else { return }
        
        if let replyView = replyView {
            NSLayoutConstraint.activate([
                replyView.topAnchor.constraint(equalTo: self.topAnchor),
                replyView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 6),
                replyView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -6)
            ])
            messageBackground.topAnchor.constraint(equalTo: replyView.bottomAnchor, constant: 6).isActive = true
        } else {
            messageBackground.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        }

        
        NSLayoutConstraint.activate([
            messageBackground.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            messageBackground.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            messageBackground.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            
            
            messageContent.topAnchor.constraint(equalTo: messageBackground.topAnchor, constant: 20),
            messageContent.leadingAnchor.constraint(equalTo: messageBackground.leadingAnchor, constant: 20),
            messageContent.trailingAnchor.constraint(equalTo: messageBackground.trailingAnchor, constant: -20),
            messageContent.bottomAnchor.constraint(equalTo: messageBackground.bottomAnchor, constant: -6),
            
            
            authorName.topAnchor.constraint(equalTo: messageBackground.topAnchor, constant: 4),
            authorName.leadingAnchor.constraint(equalTo: messageContent.leadingAnchor),
            
            edited.centerYAnchor.constraint(equalTo: authorName.centerYAnchor),
            edited.leadingAnchor.constraint(equalTo: authorName.trailingAnchor, constant: 4),
            
            timestamp.centerYAnchor.constraint(equalTo: authorName.centerYAnchor),
            timestamp.trailingAnchor.constraint(equalTo: messageContent.trailingAnchor)
        ])
        
        NSLayoutConstraint.activate([
            authorAvatar.topAnchor.constraint(equalTo: authorName.topAnchor),
            authorAvatar.trailingAnchor.constraint(equalTo: messageContent.leadingAnchor, constant: -4)
        ])
    }
    
    public func updateMessage(_ message: Message) {
        self.messageText.text = message.content
        self.edited.text = "(edited)"
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.slClient = nil
        self.message = nil
        self.isClientUser = nil
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
    }
}









