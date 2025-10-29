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

public typealias UIStackView = UIKitCompatKit.UIStackView


class ViewController: UIViewController {
    
    private var dms: [DMChannel] = []
    
    private var offset: CGFloat {
        if #available(iOS 7.0.1, *) {
            return UIApplication.shared.statusBarFrame.height+(self.navigationController?.navigationBar.frame.height)!
        } else {
            return UIApplication.shared.statusBarFrame.height*2+(self.navigationController?.navigationBar.frame.height)!
        }
    }
    
    private lazy var dmCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: offset, left: 20, bottom: 20, right: 20)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)

        cv.backgroundColor = .discordGray
        cv.delegate = self
        cv.dataSource = self
        cv.register(DMButtonCell.self, forCellWithReuseIdentifier: DMButtonCell.reuseID)
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Direct Messages"
        view.backgroundColor = dmCollectionView.backgroundColor
        
        clientUser.setIntents(intents: .directMessages, .directMessagesTyping)
        clientUser.connect()
        SetStatusBarBlackTranslucent()
        SetWantsFullScreenLayout(self, true)
        view.addSubview(dmCollectionView)
        
        NSLayoutConstraint.activate([
            dmCollectionView.topAnchor.constraint(equalTo: view.topAnchor),
            dmCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dmCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dmCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        fetchDMs()
    }
    
    private func fetchDMs() {
        clientUser.getSortedDMs { [weak self] dms, error in
            guard let self = self else { return }
            self.dms = dms
            self.dmCollectionView.reloadData() // only visible cells will render
        }
    }
}

// MARK: - Collection View
extension ViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dms.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dm = dms[indexPath.item]
        let cell = dmCollectionView.dequeueReusableCell(withReuseIdentifier: DMButtonCell.reuseID, for: indexPath) as! DMButtonCell
        cell.configure(with: dm)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let dm = dms[indexPath.item]
        switch dm.type {
        case .dm:
            navigationController?.pushViewController(DMViewController(dm: dm as! DM), animated: true)
        case .groupDM:
            navigationController?.pushViewController(DMViewController(dm: dm as! GroupDM), animated: true)
        default: break
        }
    }
    
    // Cell sizing
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = dmCollectionView.bounds.width - 40 // section insets
        return CGSize(width: width, height: 50)
    }
}

