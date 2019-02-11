//

import UIKit
import RxSwift
import RxCocoa

class DetailViewController: UIViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel!.transform(input: ()).launchDetail.asObservable()
            .subscribe(onNext: { [weak self] lce in
                guard let self = self else {
                    return
                }
                
                if lce.loading {
                    self.loader.isHidden = false
                }
                else {
                    self.loader.isHidden = true
                    if lce.hasError {
                        self.errorMessage.isHidden = false
                    }
                    else {
                        self.configureContent(for: lce.data!)
                        self.contentView.isHidden = false
                    }
                }
            })
            .disposed(by: disposeBag)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // This is needed due to a bug with named colors in storyboards:
        // https://procrastinative.ninja/2018/07/16/debugging-ios-named-colors/
        // https://openradar.appspot.com/radar?id=4980463923888128
        if let statusColor = statusColor {
            launchStatus.textColor = statusColor
        }
    }
    
    var viewModel: DetailViewModel? = nil
    
    // MARK: - Outlets
    
    @IBOutlet weak var loader: UIActivityIndicatorView!
    @IBOutlet weak var errorMessage: UILabel!
    @IBOutlet weak var contentView: UIScrollView!
    
    @IBOutlet weak var missionName: UILabel!
    @IBOutlet weak var missionPatchPicture: UIImageView!
    @IBOutlet weak var flightNumber: UILabel!
    @IBOutlet weak var launchDate: UILabel!
    @IBOutlet weak var launchSite: UILabel!
    @IBOutlet weak var rocketName: UILabel!
    @IBOutlet weak var rocketType: UILabel!
    @IBOutlet weak var launchStatus: UILabel!
    @IBOutlet weak var descriptionView: UITextView!
    @IBOutlet weak var payload: UIStackView!
    
    // MARK: - Private implementation
    
    private func configureContent(for launchDetail: Launch) {
        missionName.text = launchDetail.missionName
        launchSite.text = launchDetail.launchSiteName
        rocketName.text = launchDetail.rocket.name
        rocketType.text = launchDetail.rocket.type
        
        let flightNumberFormat = NSLocalizedString("general.flightNumberFormat", value: "#%d", comment: "#999")
        flightNumber.text = String(format: flightNumberFormat, launchDetail.flightNumber)
        
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        let utcDateFormat = NSLocalizedString("general.utcDateFormat", value: "%@ UTC", comment: "January 1, 2019 20:00 UTC")
        launchDate.text = String(format: utcDateFormat, formatter.string(from: launchDetail.launchDate))
        
        if launchDetail.launchSuccess {
            launchStatus.text = NSLocalizedString("general.success", value: "Success", comment: "")
            launchStatus.textColor = UIColor(named: "Success")
        }
        else {
            launchStatus.text = NSLocalizedString("general.failure", value: "Failure", comment: "")
            launchStatus.textColor = UIColor(named: "Failure")
        }
        statusColor = launchStatus.textColor

        descriptionView.text = launchDetail.description
        descriptionView.isHidden = launchDetail.description.isEmpty
        
        let pictureUrl = URL(string: launchDetail.missionPatchUrl)!
        missionPatchPicture.af_setImage(withURL: pictureUrl)
        
        if launchDetail.rocket.payload.count > 0 {
            for (index, payloadItem) in launchDetail.rocket.payload.enumerated() {
                let payloadView = PayloadView.loadFromNib(named: PayloadView.nameOfClass) as! PayloadView
                payloadView.configure(for: payloadItem, at: index)
                payload.addArrangedSubview(payloadView)
            }
        }
        else {
            payload.isHidden = true
        }
    }
    
    private var disposeBag = DisposeBag()
    private var statusColor: UIColor? = nil
}
