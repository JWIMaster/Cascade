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

public typealias UIStackView = UIKitCompatKit.UIStackView


class ViewController: UIViewController {
    
    var dms: [DMChannel] = []
    var guilds: [Guild] = []
    var activeGuildChannels: [GuildChannel] = []
    
    var containerView = UIView()
    
    var offset: CGFloat {
        if #available(iOS 6.0.1, *) {
            return UIApplication.shared.statusBarFrame.height+(self.navigationController?.navigationBar.frame.height)!
        } else {
            return UIApplication.shared.statusBarFrame.height*2+(self.navigationController?.navigationBar.frame.height)!
        }
    }
    
    var sidebarButtons: [SidebarButtonType] {
        return [.dms] + guilds.map { .guild($0) }
    }
    
    let activeContentView = UIView()
    
    lazy var dmCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 10, left: 20, bottom: 20, right: 20)
        
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
        layout.sectionInset = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        
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
        layout.sectionInset = UIEdgeInsets(top: 10, left: 20, bottom: 20, right: 20)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.delegate = self
        cv.dataSource = self
        cv.register(ChannelButtonCell.self, forCellWithReuseIdentifier: ChannelButtonCell.reuseID)
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    // In your ViewController
    lazy var channelsTableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain) // or .grouped
        tv.backgroundColor = .clear
        tv.delegate = self
        tv.dataSource = self
        tv.register(ChannelButtonCell.self, forCellReuseIdentifier: ChannelButtonCell.reuseID)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.separatorStyle = .none
        return tv
    }()

    
    var sidebarBackgroundView: UIView? = {
        switch device {
        case .a4:
            return UIView()
        default:
            let glass = LiquidGlassView(blurRadius: 0, cornerRadius: 22, snapshotTargetView: nil, disableBlur: true)
            glass.translatesAutoresizingMaskIntoConstraints = false
            return glass
        }
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Direct Messages"
        view.backgroundColor = .discordGray
        
        guard let sidebarBackgroundView = sidebarBackgroundView else { return }
        
        clientUser.setIntents(intents: .directMessages, .directMessagesTyping)
        clientUser.connect()
        if #unavailable(iOS 7.0.1) {
            SetStatusBarBlackTranslucent()
            SetWantsFullScreenLayout(self, true)
        }
        view.addSubview(containerView)
        containerView.addSubview(sidebarBackgroundView)
        
        containerView.addSubview(activeContentView)
        activeContentView.translatesAutoresizingMaskIntoConstraints = false
        sidebarBackgroundView.addSubview(sidebarCollectionView)
        
        setupConstraints()
        fetchDMs()
        fetchGuilds()
    }
    
    func setupConstraints() {
        guard let sidebarBackgroundView = sidebarBackgroundView else { return }
        containerView.pinToEdges(of: view, insetBy: .init(top: offset, left: 0, bottom: 0, right: 0))
        
        if #available(iOS 11.0, *) {
            let guide: UIKit.UILayoutGuide = containerView.safeAreaLayoutGuide
            view.addConstraint(.init(item: sidebarBackgroundView, attribute: .leading, relatedBy: .equal, toItem: containerView, attribute: .leading, multiplier: 1, constant: 10))
            view.addConstraint(.init(item: sidebarBackgroundView, attribute: .top, relatedBy: .equal, toItem: containerView, attribute: .top, multiplier: 1, constant: 10))
            view.addConstraint(.init(item: sidebarBackgroundView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 64))
            view.addConstraint(.init(item: sidebarBackgroundView, attribute: .bottom, relatedBy: .equal, toItem: guide, attribute: .bottom, multiplier: 1, constant: 0))
        } else {
            NSLayoutConstraint.activate([
                sidebarBackgroundView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
                sidebarBackgroundView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
                sidebarBackgroundView.widthAnchor.constraint(equalToConstant: 64),
                sidebarBackgroundView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
        }
        
        NSLayoutConstraint.activate([
            activeContentView.leadingAnchor.constraint(equalTo: sidebarBackgroundView.trailingAnchor),
            activeContentView.topAnchor.constraint(equalTo: containerView.topAnchor),
            activeContentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            activeContentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        sidebarCollectionView.pinToEdges(of: sidebarBackgroundView, insetBy: .init(top: 6, left: 6, bottom: 6, right: 6))
    }
    
    
    func fetchDMs() {
        clientUser.getSortedDMs { [weak self] dms, error in
            guard let self = self else { return }
            self.dms = dms
            self.dmCollectionView.reloadData()
        }
    }
    
    func fetchGuilds() {
        clientUser.getUserGuilds() { [weak self] guilds, error in
            guard let self = self else { return }
            for (_, guild) in guilds {
                self.guilds.append(guild)
            }
            self.sidebarCollectionView.reloadData()
        }
    }
    
    func fetchChannels(for guild: Guild, completion: @escaping () -> Void) {
        clientUser.getGuildChannels(for: guild.id!) { [weak self] channels, error in
            guard let self = self else { return }
            self.activeGuildChannels = channels
            self.groupChannelsByCategory()
            self.channelsCollectionView.reloadData()
            completion()
        }
    }
    
    
    func showContentView(_ view: UIView) {
        activeContentView.subviews.forEach { $0.removeFromSuperview() }
        
        activeContentView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        activeContentView.pinToEdges(of: view)
    }
    var activeGuild: Guild?
    
    var activeGuildChannelsByCategory: [GuildCategory: [GuildText]] = [:]
    var sortedCategoryKeys: [GuildCategory] = []

    
    func groupChannelsByCategory() {
        guard let guild = activeGuild else { return }

        // Reset dictionary
        var dict: [GuildCategory: [GuildText]] = [:]

        for channel in activeGuildChannels {
            guard let textChannel = channel as? GuildText else { continue }

            // If it has a parent category, use that; otherwise, use a placeholder category
            let category: GuildCategory
            if let parentCategory = textChannel.category {
                category = parentCategory
            } else {
                // Create a dummy "Uncategorized" category
                let uncategorized = GuildCategory(clientUser, [:])
                uncategorized.name = "Uncategorized"
                category = uncategorized
            }

            if dict[category] == nil {
                dict[category] = []
            }
            dict[category]?.append(textChannel)
        }

        // Sort channels within each category by position
        for (category, channels) in dict {
            dict[category] = channels.sorted { ($0.position ?? 0) < ($1.position ?? 0) }
        }

        self.activeGuildChannelsByCategory = dict
        self.sortedCategoryKeys = dict.keys.sorted { ($0.position ?? 0) < ($1.position ?? 0) }
        //channelsTableView.reloadData()
    }

}



