import UIKit
import SwiftcordLegacy
import UIKitCompatKit
import SFSymbolsCompatKit

// MARK: - Sidebar Button Types
enum SidebarButtonType {
    case dms
    case guild(Guild)
    case folder(GuildFolder, isExpanded: Bool) // Add folder type with expansion state
}

// MARK: - Sidebar Button Cell
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

    private let expandIcon: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .center
        return iv
    }()

    private(set) var type: SidebarButtonType?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        contentView.addSubview(expandIcon)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            expandIcon.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            expandIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            expandIcon.widthAnchor.constraint(equalToConstant: 16),
            expandIcon.heightAnchor.constraint(equalToConstant: 16)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with type: SidebarButtonType) {
        self.type = type
        expandIcon.isHidden = true // default hidden

        switch type {
        case .dms:
            imageView.image = UIImage(named: "defaultavatar")
            imageView.backgroundColor = .clear

        case .guild(let guild):
            GuildAvatarCache.shared.avatar(for: guild) { [weak self] image in
                DispatchQueue.main.async {
                    self?.imageView.image = image ?? UIImage(named: "defaultguild")
                }
            }

        case .folder(let folder, let isExpanded):
            imageView.image = UIImage(systemName: "folder.fill") // SF Symbol for folder
            imageView.tintColor = folder.color ?? .gray
            expandIcon.isHidden = false
            expandIcon.image = UIImage(systemName: isExpanded ? "chevron.down" : "chevron.right")
            expandIcon.tintColor = .gray
        }
    }
}
