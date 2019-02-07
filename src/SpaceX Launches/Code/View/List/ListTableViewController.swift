//

import UIKit
import RxSwift
import RxCocoa

protocol ListFlowDelegate {
    func showDetail(withId id: Int)
}

// FIXME: no data view
// FIXME: manual refresh
// FIXME: error message
// FIXME: loading
class ListTableViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // These are set by default to self. We let Rx manage the table view, so these need to be cleared.
        tableView.delegate = nil
        tableView.dataSource = nil
        
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main, using: handleDidEnterBackground)
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main, using: handleWillEnterForeground)
        NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main, using: handleOrientationDidChange)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        bindData()
        requestLaunches.onNext(false)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        flowDelegate?.showDetail(withId: indexPath.row)
    }
    
    var flowDelegate: ListFlowDelegate? = nil
    
    var viewModel: ListViewModel? = nil {
        didSet {
            if let viewModel = viewModel {
                let requestLaunchesSignal = requestLaunches.asSignal(onErrorSignalWith: Signal.empty())
                let input = ListViewModel.Input(requestLaunches: requestLaunchesSignal)
                viewModel.transform(input: input)
            }
        }
    }
    
    // MARK: - Private implementation
    
    private func handleDidEnterBackground(_ notification: Notification) {
        launchesDisposeBag = nil
    }
    
    private func handleWillEnterForeground(_ notification: Notification) {
        bindData()
        requestLaunches.onNext(false)
    }
    
    private func handleOrientationDidChange(_ notification: Notification) {
        tableView.reloadData()
    }
    
    private func bindData() {
        guard launchesDisposeBag == nil else {
            return
        }
        
        launchesDisposeBag = DisposeBag()
        
        viewModel!.output?.launches
            .asObservable()
            .map({ $0.data ?? [] })
            .bind(to: tableView.rx.items) { tableView, row, element in
                let identifier = self.traitCollection.horizontalSizeClass == .regular
                    ? LaunchPreviewRegularTableViewCell.identifier
                    : LaunchPreviewCompactTableViewCell.identifier
                let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as! LaunchPreviewTableViewCell
                cell.configure(for: element)
                return cell
            }
            .disposed(by: launchesDisposeBag!)
    }
    
    private var launchesDisposeBag: DisposeBag? = nil
    private var requestLaunches = PublishSubject<Bool>()
}
