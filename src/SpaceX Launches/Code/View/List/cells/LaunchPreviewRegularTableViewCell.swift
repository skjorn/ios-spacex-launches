//

import UIKit

class LaunchPreviewRegularTableViewCell: LaunchPreviewTableViewCell {
    static let identifier = "LaunchPreviewRegular"
    
    override func configure(for launchPreview: LaunchPreview) {
        super.configure(for: launchPreview)

        let pictureUrl = URL(string: launchPreview.missionPatchUrl)!
        picture.af_setImage(withURL: pictureUrl)

        flightNumber.text = "#\(launchPreview.flightNumber)"
        mission.text = launchPreview.missionName
        launchDate.text = DateFormatter.localizedString(from: launchPreview.launchDate, dateStyle: .medium, timeStyle: .none)
        launchSite.text = launchPreview.launchSiteName
        
        if launchPreview.launchSuccess {
            status.text = "Success"
            status.textColor = UIColor(named: "Success")
        }
        else {
            status.text = "Failure"
            status.textColor = UIColor(named: "Failure")
        }
    }
    
    // MARK: - Outlets
    
    @IBOutlet weak var picture: UIImageView!
    @IBOutlet weak var flightNumber: UILabel!
    @IBOutlet weak var mission: UILabel!
    @IBOutlet weak var launchSite: UILabel!
    @IBOutlet weak var launchDate: UILabel!
    @IBOutlet weak var status: UILabel!
}
