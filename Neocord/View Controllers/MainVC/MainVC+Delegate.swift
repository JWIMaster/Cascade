//
//  MainVC+Delegate.swift
//  Cascade
//
//  Created by JWI on 2/11/2025.
//

import UIKit
import SwiftcordLegacy
import UIKitExtensions
import UIKitCompatKit
import iOS6BarFix
import LiveFrost

// MARK: - Collection View
extension ViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == dmCollectionView {
            return dms.count
        } else if collectionView == sidebarCollectionView {
            return sidebarButtons.count
        } else if collectionView == channelsCollectionView {
            return activeGuildChannels.count
        } else {
            fatalError()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == dmCollectionView {
            let dm = dms[indexPath.item]
            let cell = dmCollectionView.dequeueReusableCell(withReuseIdentifier: DMButtonCell.reuseID, for: indexPath) as! DMButtonCell
            cell.configure(with: dm)
            return cell
        } else if collectionView == sidebarCollectionView {
            let cell = sidebarCollectionView.dequeueReusableCell(withReuseIdentifier: SidebarButtonCell.reuseID, for: indexPath) as! SidebarButtonCell
            cell.configure(with: sidebarButtons[indexPath.item])
            return cell
        } else if collectionView == channelsCollectionView {
            let channel = activeGuildChannels[indexPath.item]
            let cell = channelsCollectionView.dequeueReusableCell(withReuseIdentifier: ChannelButtonCell.reuseID, for: indexPath) as! ChannelButtonCell
            cell.configure(with: channel)
            return cell
        } else {
            fatalError()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == dmCollectionView {
            let dm = dms[indexPath.item]
            switch dm.type {
            case .dm:
                navigationController?.pushViewController(DMViewController(dm: dm as! DM), animated: true)
            case .groupDM:
                navigationController?.pushViewController(DMViewController(dm: dm as! GroupDM), animated: true)
            default: break
            }
        } else if collectionView == sidebarCollectionView {
            let button = sidebarButtons[indexPath.item]
            
            switch button {
            case .dms:
                showContentView(dmCollectionView)
                dmCollectionView.reloadData()
                self.title = "Direct Messages"
                guard let navigation = self.navigationController as? CustomNavigationController else {
                    return
                }
                navigation.updateTitle(for: self)
                
            case .guild(let guild):
                self.showContentView(self.channelsCollectionView)
                channelsCollectionView.reloadData()
                
                fetchChannels(for: guild) { [weak self] in
                    guard let self = self else { return }
                    self.channelsCollectionView.reloadData()
                }
                
                clientUser.getFullGuild(guild) { guild, error in
                    for (_,guild) in guild {
                        self.activeGuild = guild
                        self.title = self.activeGuild?.name ?? "Unknown Guild"
                        guard let navigation = self.navigationController as? CustomNavigationController else {
                            return
                        }
                        navigation.updateTitle(for: self)
                    }
                }
            }
        } else if collectionView == channelsCollectionView {
            let channel = activeGuildChannels[indexPath.item]
            navigationController?.pushViewController(GuildTextViewController(channel: channel as! GuildText), animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == dmCollectionView {
            let width = dmCollectionView.bounds.width - 20
            return CGSize(width: width, height: 50)
        } else if collectionView == sidebarCollectionView {
            return CGSize(width: sidebarCollectionView.bounds.width-10, height: sidebarCollectionView.bounds.width-10)
        } else if collectionView == channelsCollectionView {
            let width = channelsCollectionView.bounds.width - 20
            return CGSize(width: width, height: 50)
        } else {
            fatalError()
        }
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sortedCategoryKeys.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let category = sortedCategoryKeys[section]
        return activeGuildChannelsByCategory[category]?.count ?? 0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sortedCategoryKeys[section].name
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let category = sortedCategoryKeys[indexPath.section]
        let channel = activeGuildChannelsByCategory[category]![indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ChannelButtonCell.reuseID, for: indexPath) as! ChannelButtonCell
        cell.configure(with: channel)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let category = sortedCategoryKeys[indexPath.section]
        let channel = activeGuildChannelsByCategory[category]![indexPath.row]
        navigationController?.pushViewController(GuildTextViewController(channel: channel), animated: true)
    }
}

