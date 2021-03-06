//

import UIKit

extension UIView {
    static public func loadFromNib(named className: String) -> UIView? {
        let nib = UINib(nibName: className, bundle: nil)
        return nib.instantiate(withOwner: nil, options: nil).first as? UIView
    }
}
