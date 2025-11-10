//
//  DMsCollectionViewController.swift
//  MakingADiscordAPI
//
//  Created by JWI on 24/10/2025.
//

import UIKit
import SwiftcordLegacy
import UIKitExtensions
import UIKitCompatKit
import iOS6BarFix
import LiveFrost
import SFSymbolsCompatKit
import FoundationCompatKit

public typealias UIStackView = UIKitCompatKit.UIStackView


class ViewController: UIViewController {
    
    var dms: [DMChannel] {
        get {
            return Array(clientUser.dms.values).sorted { $0.lastMessageID?.rawValue ?? 0 > $1.lastMessageID?.rawValue ?? 0 }
        }
        set {
            for dm in newValue {
                if let id = dm.id {
                    clientUser.dms[id] = dm
                }
            }
        }
    }
    
    var orderedGuilds: [Guild] = []
    
    var guilds: [Guild] {
        get {
            return Array(clientUser.guilds.values)
        }
        set {
            for guild in newValue {
                if let id = guild.id {
                    clientUser.guilds[id] = guild
                }
            }
        }
    }
    
    var activeGuildChannels: [GuildChannel] = []
    
    var containerView = UIView()
    
    var offset: CGFloat {
        return UIApplication.shared.statusBarFrame.height+(self.navigationController?.navigationBar.frame.height)!
    }
    
    /*var sidebarButtons: [SidebarButtonType] {
        return [.dms] + orderedGuilds.map { .guild($0) }
    }*/
    
    var expandedFolderIDs: Set<String> {
        get {
            if let array = UserDefaults.standard.array(forKey: "expandedFolderIDs") as? [String] {
                return Set(array)
            }
            return []
        }
        set {
            let array = Array(newValue)
            UserDefaults.standard.set(array, forKey: "expandedFolderIDs")
            UserDefaults.standard.synchronize()
        }
    }
    
    /*var sidebarButtons: [SidebarButtonType] {
        var items: [SidebarButtonType] = [.dms]

        guard let folders = clientUser.clientUserSettings?.guildFolders else {
            items.append(contentsOf: orderedGuilds.map { .guild($0) })
            return items
        }

        for folder in folders {
            guard let guildIDs = folder.guildIDs else { continue }
            let guildsInFolder = orderedGuilds.filter { guildIDs.contains($0.id!) }

            // Skip folder if it only has 1 guild
            if guildsInFolder.count == 1 {
                items.append(.guild(guildsInFolder[0]))
                continue
            }

            // Determine if folder is expanded; default to false
            let folderID = folder.id?.description
            let isExpanded = UserDefaults.standard.bool(forKey: "\(folderID)") ?? false
            items.append(.folder(folder, isExpanded: isExpanded))

            // Append child guilds only if folder is expanded
            if isExpanded {
                items.append(contentsOf: guildsInFolder.map { .guild($0) })
            }
        }

        return items
    }*/
    
    var sidebarButtons: [SidebarButtonType] = []


    
    let activeContentView: UIView = {
        if ThemeEngine.enableGlass {
            switch device {
            case .a4:
                let bg = UIView()
                bg.backgroundColor = .discordGray.withIncreasedSaturation(factor: 0.3)
                return bg
            default:
                let glass = LiquidGlassView(blurRadius: 0, cornerRadius: 22, snapshotTargetView: nil, disableBlur: true)
                glass.tintColorForGlass = .discordGray.withAlphaComponent(0.5)
                return glass
            }
        } else {
            let bg = UIView()
            bg.backgroundColor = .discordGray.withIncreasedSaturation(factor: 0.3)
            return bg
        }
    }()
    
    lazy var dmCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 20, right: 10)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        cv.backgroundColor = .clear
        cv.delegate = self
        cv.dataSource = self
        cv.register(DMButtonCell.self, forCellWithReuseIdentifier: DMButtonCell.reuseID)
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    lazy var sidebarCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.delegate = self
        cv.dataSource = self
        cv.layer.cornerRadius = 18
        cv.register(SidebarButtonCell.self, forCellWithReuseIdentifier: SidebarButtonCell.reuseID)
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    lazy var channelsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 20, right: 10)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.delegate = self
        cv.dataSource = self
        cv.register(ChannelButtonCell.self, forCellWithReuseIdentifier: ChannelButtonCell.reuseID)
        cv.register(ChannelCategoryCell.self, forCellWithReuseIdentifier: "ChannelCategoryCell")

        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    var sidebarBackgroundView: UIView? = {
        if ThemeEngine.enableGlass {
            switch device {
            case .a4:
                let bg = UIView()
                bg.backgroundColor = .discordGray.withIncreasedSaturation(factor: 0.3)
                return bg
            default:
                let glass = LiquidGlassView(blurRadius: 0, cornerRadius: 22, snapshotTargetView: nil, disableBlur: true)
                glass.translatesAutoresizingMaskIntoConstraints = false
                glass.tintColorForGlass = .discordGray.withAlphaComponent(0.5)
                return glass
            }
        } else {
            let bg = UIView()
            bg.backgroundColor = .discordGray.withIncreasedSaturation(factor: 0.3)
            return bg
        }
    }()
    
    var toolbar = CustomToolbar()
    
    var animatedIndexPathsPerCollectionView: [UICollectionView: Set<IndexPath>] = [:]
    
    var activeGuild: Guild?
    
    var displayedChannels: [GuildChannel] = []
    
    var settingsContainerView = SettingsView()
    
    var mainContainerView = UIView()
    
    var settingsButton: UIButton = {
        let button1 = UIButton(type: .custom)
        button1.setTitle("Settings", for: .normal)
        button1.setImage(.init(systemName:"gear", tintColor: .white), for: .normal)
        return button1
    }()
    
    var mainMenuButton: UIButton = {
        let button2 = UIButton(type: .custom)
        button2.setTitle("Menu", for: .normal)
        button2.setImage(.init(systemName:"list.bullet.below.rectangle", tintColor: .white), for: .normal)
        return button2
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        clientUser.connect()
        //clientUser.clearCache()
        
        
        self.setupMainView()
        
    }
    
    func setupMainView() {
        title = "Direct Messages"
        view.backgroundColor = .discordGray
        
        guard let sidebarBackgroundView = sidebarBackgroundView else { return }
        
        clientUser.loadCache {
            
            self.setupOrderedGuilds()
            
            self.rebuildSidebarButtons()
            
            self.sidebarCollectionView.reloadData()
            self.dmCollectionView.reloadData()
            self.channelsCollectionView.reloadData()
            self.fetchDMs()
            self.fetchGuilds()
            
        }
        if #unavailable(iOS 7.0.1) {
            SetStatusBarBlackTranslucent()
            SetWantsFullScreenLayout(self, true)
        }
        view.addSubview(mainContainerView)
        mainContainerView.addSubview(containerView)
        
        mainContainerView.addSubview(settingsContainerView)
        settingsContainerView.translatesAutoresizingMaskIntoConstraints = false
        settingsContainerView.isHidden = true  // hide it initially
        
        containerView.addSubview(sidebarBackgroundView)
        
        containerView.addSubview(activeContentView)
        activeContentView.translatesAutoresizingMaskIntoConstraints = false
        sidebarBackgroundView.addSubview(sidebarCollectionView)
        
        
        
        view.addSubview(toolbar)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        
        setupConstraints()
        setupButtonActions()
        

        
        toolbar.setItems([UIButton(), mainMenuButton, settingsButton, UIButton()])
        
        if ThemeEngine.enableAnimations {
            activeContentView.springAnimation(scaleDuration: 0.5, bounceDuration: 0.4)
            toolbar.springAnimation(scaleDuration: 0.5, bounceDuration: 0.4)
            sidebarBackgroundView.springAnimation(scaleDuration: 0.5, bounceDuration: 0.4)
        }
        
        clientUser.onReady = {
            DispatchQueue.main.async {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                self.sidebarCollectionView.reloadData()
                self.dmCollectionView.reloadData()
                CATransaction.commit()
            }
        }
    }
    
    func setupButtonActions() {
        settingsButton.addAction(for: .touchUpInside) {
            self.settingsButton.isUserInteractionEnabled = false
            self.transition(from: self.containerView, to: self.settingsContainerView, direction: .left, in: self.mainContainerView, completionHandler: {
                self.mainMenuButton.isUserInteractionEnabled = true
            })
        }
        
        
        mainMenuButton.addAction(for: .touchUpInside) {
            self.mainMenuButton.isUserInteractionEnabled = false
            self.transition(from: self.settingsContainerView, to: self.containerView, direction: .right, in: self.mainContainerView, completionHandler: {
                self.settingsButton.isUserInteractionEnabled = true
            })
        }
    }
    
    func rebuildSidebarButtons() {
        var items: [SidebarButtonType] = [.dms]

        guard let folders = clientUser.clientUserSettings?.guildFolders else {
            items.append(contentsOf: orderedGuilds.map { .guild($0) })
            sidebarButtons = items
            return
        }

        for folder in folders {
            guard let guildIDs = folder.guildIDs else { continue }
            let guildsInFolder = orderedGuilds.filter { guildIDs.contains($0.id!) }

            // Skip showing folder if it has only one guild
            if guildsInFolder.count == 1 {
                items.append(.guild(guildsInFolder[0]))
                continue
            }
            
            if folder.id == nil || folder.id?.description == "" {
                let uuidString = UUID().uuidString
                let digitsString = uuidString.compactMap { $0.wholeNumberValue }.map(String.init).joined()
                folder.id = Int(digitsString.prefix(9))
            }
            
            let folderKey = folder.id?.description ?? ""
            let isExpanded = UserDefaults.standard.bool(forKey: folderKey)
            // Add the folder with its persisted expanded state
            items.append(.folder(folder, isExpanded: isExpanded))

            // If it’s expanded, add its guilds
            if isExpanded {
                items.append(contentsOf: guildsInFolder.map { .guild($0) })
            }
        }

        sidebarButtons = items
    }


    
    func refreshView() {
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
    }
    
    func setupConstraints() {
        guard let sidebarBackgroundView = sidebarBackgroundView else { return }

        // MARK: Toolbar layout
        if let customController = navigationController as? CustomNavigationController {
            NSLayoutConstraint.activate([
                toolbar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                toolbar.widthAnchor.constraint(equalToConstant: customController.navBarFrame.frame.width - 20),
                toolbar.heightAnchor.constraint(equalToConstant: customController.navBarFrame.frame.height)
            ])
            
            if #available(iOS 11.0, *) {
                view.addConstraint(toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10))
            } else {
                toolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10).isActive = true
            }
        }

        // MARK: Container view
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainContainerView.topAnchor.constraint(equalTo: view.topAnchor, constant: offset),
            mainContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainContainerView.bottomAnchor.constraint(equalTo: toolbar.topAnchor)
        ])
        
        containerView.pinToEdges(of: mainContainerView)
        
        settingsContainerView.pinToEdges(of: mainContainerView, insetBy: .init(top: 10, left: 10, bottom: 10, right: 10))


        // MARK: Sidebar
        sidebarBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sidebarBackgroundView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            sidebarBackgroundView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            sidebarBackgroundView.widthAnchor.constraint(equalToConstant: 64),
            sidebarBackgroundView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10)
        ])

        // MARK: Active content area
        activeContentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activeContentView.leadingAnchor.constraint(equalTo: sidebarBackgroundView.trailingAnchor, constant: 10),
            activeContentView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            activeContentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            activeContentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10)
        ])

        // MARK: Sidebar collection
        sidebarCollectionView.translatesAutoresizingMaskIntoConstraints = false
        sidebarCollectionView.pinToEdges(of: sidebarBackgroundView, insetBy: .init(top: 6, left: 6, bottom: 6, right: 6))
    }

    
    
    func showContentView(_ view: UIView) {
        activeContentView.subviews.forEach { $0.removeFromSuperview() }
        
        activeContentView.addSubview(view)
        view.layer.cornerRadius = 22
        view.translatesAutoresizingMaskIntoConstraints = false
        view.pinToEdges(of: activeContentView)
    }
    
    
   

    func flattenChannelsForDisplay() {
        guard let guild = activeGuild else { return }
        displayedChannels.removeAll()

        let textChannels = guild.channels.values.compactMap { $0 as GuildChannel }
            .filter { !($0 is GuildCategory) }

        // Get categories
        let categories = guild.channels.values.compactMap { $0 as? GuildCategory }

        // Sort categories based on the highest-positioned child channel
        let sortedCategories = categories.sorted { category1, category2 in
            let maxPos1 = textChannels.filter { $0.parentID == category1.id }.map { $0.position ?? 0 }.max() ?? 0
            let maxPos2 = textChannels.filter { $0.parentID == category2.id }.map { $0.position ?? 0 }.max() ?? 0
            return maxPos2 > maxPos1// higher channels first
        }

        for category in sortedCategories {
            displayedChannels.append(category)

            let channelsInCategory = textChannels.filter { $0.parentID == category.id }.sorted { ($0.position ?? 0) < ($1.position ?? 0) }

            displayedChannels.append(contentsOf: channelsInCategory)
        }

        // Add uncategorized channels at the end
        let uncategorized = textChannels
            .filter { $0.parentID == nil || categories.first(where: { $0.id == $0.parentID }) == nil }
            .sorted { ($0.position ?? 0) < ($1.position ?? 0) }

        displayedChannels.append(contentsOf: uncategorized)

        channelsCollectionView.reloadData()
    }


    enum SlideDirection {
        case left
        case right
    }
    
    func transition(from oldView: UIView?, to newView: UIView, direction: SlideDirection, in container: UIView, animated: Bool = true, completionHandler: @escaping () -> ()) {
        guard newView !== oldView else { return }
        
        oldView?.isHidden = false
        newView.isHidden = false
        
        let width = container.bounds.width
        let newOffset = direction == .left ? width : -width
        let oldOffset = direction == .left ? -width : width

        // Immediately set starting positions without jumping
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        newView.layer.transform = CATransform3DMakeTranslation(newOffset, 0, 0)
        newView.layer.opacity = 0
        oldView?.layer.transform = CATransform3DIdentity
        oldView?.layer.opacity = 1
        CATransaction.commit()
        
        let animations = {
            // Animate transform
            let transformAnimOld = CABasicAnimation(keyPath: "transform.translation.x")
            transformAnimOld.fromValue = 0
            transformAnimOld.toValue = oldOffset
            transformAnimOld.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            transformAnimOld.duration = 0.35
            oldView?.layer.add(transformAnimOld, forKey: "slideOut")
            oldView?.layer.transform = CATransform3DMakeTranslation(oldOffset, 0, 0)
            
            let transformAnimNew = CABasicAnimation(keyPath: "transform.translation.x")
            transformAnimNew.fromValue = newOffset
            transformAnimNew.toValue = 0
            transformAnimNew.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            transformAnimNew.duration = 0.35
            newView.layer.add(transformAnimNew, forKey: "slideIn")
            newView.layer.transform = CATransform3DIdentity
            
            // Animate opacity
            let opacityAnimOld = CABasicAnimation(keyPath: "opacity")
            opacityAnimOld.fromValue = 1
            opacityAnimOld.toValue = 0
            opacityAnimOld.duration = 0.35
            oldView?.layer.add(opacityAnimOld, forKey: "fadeOut")
            oldView?.layer.opacity = 0
            
            let opacityAnimNew = CABasicAnimation(keyPath: "opacity")
            opacityAnimNew.fromValue = 0
            opacityAnimNew.toValue = 1
            opacityAnimNew.duration = 0.35
            newView.layer.add(opacityAnimNew, forKey: "fadeIn")
            newView.layer.opacity = 1
        }
        
        let completion: () -> Void = {
            oldView?.isHidden = true
            container.bringSubviewToFront(newView)
            completionHandler()
        }
        
        if animated {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.35)
            CATransaction.setCompletionBlock(completion)
            animations()
            CATransaction.commit()
        } else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            animations()
            CATransaction.commit()
            completion()
        }
    }
}





