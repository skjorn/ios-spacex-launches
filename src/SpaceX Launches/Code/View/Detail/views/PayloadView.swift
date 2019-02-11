//

import UIKit

class PayloadView: UIView {
    func configure(for payload: Payload, at index: Int) {
        let payloadNameFormat = NSLocalizedString("detail.payloadView.nameFormat", value: "%d. %@", comment: "Example: 1. Satellite")
        name.text = String(format: payloadNameFormat, index + 1, payload.id)
        type.text = payload.type
        orbitType.text = payload.orbitType
        customers.text = payload.customers.joined(separator: ", ")
        
        let massFormatter = MassFormatter()
        mass.text = payload.mass != nil
            ? massFormatter.string(fromValue: Double(payload.mass!), unit: .kilogram)
            : NSLocalizedString("general.notAvailable", value: "N/A", comment: "Not Available")
    }
    
    // MARK: - Outlets
        
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var type: UILabel!
    @IBOutlet weak var mass: UILabel!
    @IBOutlet weak var customers: UILabel!
    @IBOutlet weak var orbitType: UILabel!
}
