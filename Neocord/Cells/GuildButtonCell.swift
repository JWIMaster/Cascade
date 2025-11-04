import UIKit
import SwiftcordLegacy
import UIKitCompatKit
import SFSymbolsCompatKit

enum SidebarButtonType {
    case dms
    case guild(Guild)
}

class SidebarButtonCell: UICollectionViewCell {
    static let reuseID = "SidebarButtonCell"
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.layer.cornerRadius = 8
        iv.layer.masksToBounds = true
        iv.contentMode = .scaleAspectFill
        return iv
    }()
    
    private(set) var type: SidebarButtonType?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(with type: SidebarButtonType) {
        self.type = type
        
        switch type {
        case .dms:
            // Set a fixed DM icon (could be an image in assets)
            imageView.image = UIImage(named: "defaultavatar") // SF Symbol example
            imageView.backgroundColor = .clear
        case .guild(let guild):
            // Use your guild avatar cache
            GuildAvatarCache.shared.avatar(for: guild) { [weak self] image in
                DispatchQueue.main.async {
                    self?.imageView.image = image ?? UIImage(named: "defaultguild")
                }
            }
        }
    }
}
