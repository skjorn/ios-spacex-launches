//

import UIKit
import AlamofireImage

class LaunchPreviewCompactTableViewCell: LaunchPreviewTableViewCell {
    static let identifier = "LaunchPreviewCompact"

    override func layoutSubviews() {
        super.layoutSubviews()
        
        // This is needed due to a bug with named colors in storyboards:
        // https://procrastinative.ninja/2018/07/16/debugging-ios-named-colors/
        // https://openradar.appspot.com/radar?id=4980463923888128
        status.textColor = statusColor
    }
    
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
        
        statusColor = status.textColor
    }
    
    // MARK: - Outlets
    
    @IBOutlet weak var picture: UIImageView!
    @IBOutlet weak var flightNumber: UILabel!
    @IBOutlet weak var mission: UILabel!
    @IBOutlet weak var launchDate: UILabel!
    @IBOutlet weak var launchSite: UILabel!
    @IBOutlet weak var status: UILabel!
    
    private var statusColor: UIColor = UIColor.black
}
