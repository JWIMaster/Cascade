//
//  MessageActionView.swift
//  MakingADiscordAPI
//
//  Created by JWI on 28/10/2025.
//

import UIKit
import UIKitCompatKit
import FoundationCompatKit
import SwiftcordLegacy
import UIKitExtensions
import OAStackView
import iOS6BarFix
import SFSymbolsCompatKit

class MessageActionView: UIView {
    let cancelButton: LiquidGlassView = {
        let glass = LiquidGlassView(blurRadius: 0, cornerRadius: 22, snapshotTargetView: nil, disableBlur: true)
        glass.translatesAutoresizingMaskIntoConstraints = false

        let button = LargeHitAreaButton(hitAreaInset: .init(top: -6, left: -30, bottom: -6, right: -30))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.setImage(UIImage(systemName: "xmark.circle.fill", tintColor: .white), for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 0, bottom: 6, right: 0)
        
        glass.addSubview(button)
        glass.bringSubviewToFront(button)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: glass.leadingAnchor, constant: 30),
            button.trailingAnchor.constraint(equalTo: glass.trailingAnchor, constant: -30),
            button.topAnchor.constraint(equalTo: glass.topAnchor, constant: 6),
            button.bottomAnchor.constraint(equalTo: glass.bottomAnchor, constant: -6)
        ])
        return glass
    }()

    
    let editButton: LiquidGlassView = {
        let glass = LiquidGlassView(blurRadius: 0, cornerRadius: 22, snapshotTargetView: nil, disableBlur: true)
        glass.translatesAutoresizingMaskIntoConstraints = false

        let button = LargeHitAreaButton(hitAreaInset: .init(top: -6, left: -30, bottom: -6, right: -30))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Edit", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.setImage(UIImage(systemName: "square.and.pencil", tintColor: .white), for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 0, bottom: 6, right: 0)
        
        glass.addSubview(button)
        glass.bringSubviewToFront(button)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: glass.leadingAnchor, constant: 30),
            button.trailingAnchor.constraint(equalTo: glass.trailingAnchor, constant: -30),
            button.topAnchor.constraint(equalTo: glass.topAnchor, constant: 6),
            button.bottomAnchor.constraint(equalTo: glass.bottomAnchor, constant: -6)
        ])
        return glass
    }()
    
    let replyButton: LiquidGlassView = {
        let glass = LiquidGlassView(blurRadius: 0, cornerRadius: 22, snapshotTargetView: nil, disableBlur: true)
        glass.translatesAutoresizingMaskIntoConstraints = false

        let button = LargeHitAreaButton(hitAreaInset: .init(top: -6, left: -30, bottom: -6, right: -30))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Reply", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.setImage(UIImage(systemName: "arrowshape.turn.up.right.circle", tintColor: .white), for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 0, bottom: 6, right: 0)
        
        glass.addSubview(button)
        glass.bringSubviewToFront(button)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: glass.leadingAnchor, constant: 30),
            button.trailingAnchor.constraint(equalTo: glass.trailingAnchor, constant: -30),
            button.topAnchor.constraint(equalTo: glass.topAnchor, constant: 6),
            button.bottomAnchor.constraint(equalTo: glass.bottomAnchor, constant: -6)
        ])
        return glass
    }()
    
    let deleteButton: LiquidGlassView = {
        let glass = LiquidGlassView(blurRadius: 0, cornerRadius: 22, snapshotTargetView: nil, disableBlur: true)
        glass.translatesAutoresizingMaskIntoConstraints = false
        glass.tintColorForGlass = UIColor(red: 232/255.0, green: 35/255.0, blue: 35/255.0, alpha: 0.4)
        let button = LargeHitAreaButton(hitAreaInset: .init(top: -6, left: -30, bottom: -6, right: -30))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Delete", for: .normal)
        button.setImage(UIImage(systemName: "trash.fill", tintColor: .white), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 0, bottom: 6, right: 0)
        button.sizeToFit()
        glass.addSubview(button)
        glass.bringSubviewToFront(button)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: glass.leadingAnchor, constant: 30),
            button.trailingAnchor.constraint(equalTo: glass.trailingAnchor, constant: -30),
            button.topAnchor.constraint(equalTo: glass.topAnchor, constant: 6),
            button.bottomAnchor.constraint(equalTo: glass.bottomAnchor, constant: -6)
        ])
        return glass
    }()
    
    
    let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    
    let glassView = LiquidGlassView(blurRadius: 0, cornerRadius: 22, snapshotTargetView: nil, disableBlur: true)
    var slClient: SLClient?
    var message: Message?
    var channel: TextChannel?
    var isInDM: Bool?
    
    public init(_ slClient: SLClient, _ message: Message, _ channel: TextChannel) {
        self.slClient = slClient
        self.message = message
        
        self.channel = channel
        
        self.isInDM = {
            return (channel.type == .dm || channel.type == .groupDM)
        }()
        
        super.init(frame: .zero)
        
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        setupStackView()
        setupSubviews()
        setupConstraints()
    }
    
    func setupButtons() {
        for subview in replyButton.subviews {
            if let button = subview as? UIButton {
                button.addAction(for: .touchUpInside) { [weak self] in
                    guard let self = self, let message = self.message, let channel = self.channel, let dmVC = self.parentViewController as? DMViewController else { return }
                    dmVC.textInputView?.replyToMessage(message)
                    dmVC.endMessageAction()
                }
            }
        }
        
        for subview in editButton.subviews {
            if let button = subview as? UIButton {
                button.addAction(for: .touchUpInside) { [weak self] in
                    guard let self = self, let dmVC = self.parentViewController as? DMViewController, let message = self.message else { return }
                    dmVC.textInputView?.editMessage(message)
                    dmVC.endMessageAction()
                }
            }
        }
        
        for subview in deleteButton.subviews {
            if let button = subview as? UIButton {
                button.addAction(for: .touchUpInside) { [weak self] in
                    self?.deleteAction(button: button)
                }
            }
        }
        
        for subview in cancelButton.subviews {
            if let button = subview as? UIButton {
                button.addAction(for: .touchUpInside) { [weak self] in
                    guard let self = self, let dmVC = self.parentViewController as? DMViewController else { return }
                    dmVC.endMessageAction()
                }
            }
        }
    }
    
    func setupSubviews() {
        guard let slClient = slClient, let isInDM = isInDM else {
            return
        }

        if isInDM && message?.author == slClient.clientUser {
            stackView.addArrangedSubview(replyButton)
            stackView.addArrangedSubview(editButton)
            stackView.addArrangedSubview(deleteButton)
            stackView.addArrangedSubview(cancelButton)
        } else if isInDM {
            stackView.addArrangedSubview(replyButton)
            stackView.addArrangedSubview(cancelButton)
        } else {
            stackView.addArrangedSubview(replyButton)
            stackView.addArrangedSubview(cancelButton)
        }
        stackView.sizeToFit()
        addSubview(glassView)
        glassView.addSubview(stackView)
    }
    
    
    func setupStackView() {
        
    }
    
    func deleteAction(button: UIButton) {
        guard let dmVC = parentViewController as? DMViewController, let message = self.message, let channel = self.channel, let slClient = self.slClient else { return }
        slClient.delete(message: message, in: channel) { error in
            
        }
        dmVC.endMessageAction()
    }
    
    
    func setupConstraints() {
        stackView.pinToCenter(of: glassView)
        stackView.pinToEdges(of: glassView, insetBy: .init(top: 20, left: 20, bottom: 20, right: 20))
        glassView.pinToCenter(of: self)
        glassView.pinToEdges(of: self)
    }
    
    public override func didMoveToSuperview() {
        setupButtons()
    }
}
