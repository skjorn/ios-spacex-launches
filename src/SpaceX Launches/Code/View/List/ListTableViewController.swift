import UIKit

protocol ListFlowDelegate {
    func showDetail(withId id: Int)
}

class ListTableViewController: UITableViewController {

    var flowDelegate: ListFlowDelegate? = nil

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        flowDelegate?.showDetail(withId: indexPath.row)
    }
    
}
