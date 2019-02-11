//

import UIKit

class LaunchPreviewTableViewCell: UITableViewCell {
    func configure(for launchPreview: LaunchPreview) {
        launchId = launchPreview.flightNumber
    }
    
    private(set) var launchId: Int = -1
}
