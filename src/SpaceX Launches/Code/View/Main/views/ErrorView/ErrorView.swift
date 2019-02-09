//

import UIKit

class ErrorView: UIView {
    func configure(message: String) {
        self.message.text = message
    }
    
    @IBOutlet weak var message: UILabel!
}
