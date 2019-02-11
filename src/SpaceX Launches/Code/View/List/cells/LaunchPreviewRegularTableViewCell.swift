//

import UIKit

class LaunchPreviewRegularTableViewCell: LaunchPreviewTableViewCell {
    static let identifier = "LaunchPreviewRegular"
    
    override func configure(for launchPreview: LaunchPreview) {
        super.configure(for: launchPreview)

        let pictureUrl = URL(string: launchPreview.missionPatchUrl)!
        picture.af_setImage(withURL: pictureUrl)

        let flightNumberFormat = NSLocalizedString("general.flightNumberFormat", value: "#%d", comment: "#999")
        flightNumber.text = String(format: flightNumberFormat, launchPreview.flightNumber)
        mission.text = launchPreview.missionName
        launchDate.text = DateFormatter.localizedString(from: launchPreview.launchDate, dateStyle: .medium, timeStyle: .none)
        launchSite.text = launchPreview.launchSiteName
        
        if launchPreview.launchSuccess {
            status.text = NSLocalizedString("general.success", value: "Success", comment: "")
            status.textColor = UIColor(named: "Success")
        }
        else {
            status.text = NSLocalizedString("general.failure", value: "Failure", comment: "")
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
