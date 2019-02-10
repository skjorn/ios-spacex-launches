//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

// MARK: - Flow Delegate

protocol ListFlowDelegate {
    func showDetail(withId id: Int)
    func showError(message: String)
}

// MARK: - Table section model

struct ListTableSectionModel {
    var header: String
    var items: [LaunchPreview]
}

extension ListTableSectionModel: SectionModelType {
    typealias Item = LaunchPreview
    
    init(original: ListTableSectionModel, items: [LaunchPreview]) {
        self = original
        self.items = items
    }
}

// MARK: - View Controller

class ListTableViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // These are set by default to self. We let Rx manage the table view, so these need to be cleared.
        tableView.delegate = nil
        tableView.dataSource = nil
        
        dataSource = RxTableViewSectionedReloadDataSource<ListTableSectionModel>(
            configureCell: { [weak self] dataSource, tableView, indexPath, launchPreview in
                let identifier = self?.traitCollection.horizontalSizeClass == .regular
                    ? LaunchPreviewRegularTableViewCell.identifier
                    : LaunchPreviewCompactTableViewCell.identifier
                let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as! LaunchPreviewTableViewCell
                cell.configure(for: launchPreview)
                return cell
            },
            
            titleForHeaderInSection: { dataSource, index in
                guard index < dataSource.sectionModels.count else {
                    return nil
                }
                
                return dataSource.sectionModels[index].header
            }
        )
        
        refreshControl?.addTarget(self, action: #selector(handleRefresh(sender:)), for: .valueChanged)

        addSortMenu()
        
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main, using: handleDidEnterBackground)
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main, using: handleWillEnterForeground)
        NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main, using: handleOrientationDidChange)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        bindData()
        requestLaunches.onNext(false)
        
        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                guard let self = self else {
                    return
                }
                
                let cell = self.tableView.cellForRow(at: indexPath) as? LaunchPreviewTableViewCell
                if let cell = cell {
                    self.flowDelegate?.showDetail(withId: cell.launchId)
                }
            })
            .disposed(by: onscreenDisposeBag)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        onscreenDisposeBag = DisposeBag()
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
    
    @objc private func handleRefresh(sender: UIRefreshControl) {
        requestLaunches.onNext(true)
        sender.endRefreshing()
    }
    
    private func bindData() {
        guard launchesDisposeBag == nil else {
            return
        }
        
        launchesDisposeBag = DisposeBag()
        
        // Table items

        viewModel!.output?.launches
            .asObservable()
            .filter({ !$0.hasError })
            .map({ [weak self] in
                guard let self = self else {
                    return []
                }
                
                return sortLaunches(for: self.viewModel!.sortKey, using: $0.data ?? [])
            })
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: launchesDisposeBag!)
        
        // Loading indicators, error and empty data view
        
        viewModel!.output?.launches
            .asObservable()
            .subscribe(onNext: { [weak self] lce in
                guard let self = self else {
                    return
                }
                
                if lce.loading {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = true
                }
                else {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                
                if lce.hasError {
                    self.flowDelegate?.showError(message: "Failed to download data")
                }
                
                guard lce.data == nil || lce.data!.isEmpty else {
                    self.tableView.backgroundView = nil
                    return
                }
                
                if lce.loading {
                    self.tableView.backgroundView = UIView.loadFromNib(named: Loader.nameOfClass)
                }
                else {
                    self.tableView.backgroundView = UIView.loadFromNib(named: EmptyView.nameOfClass)
                }
            })
            .disposed(by: launchesDisposeBag!)
    }
    
    private func addSortMenu() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Sort", style: .plain, target: nil, action: nil)
        navigationItem.rightBarButtonItem!.rx.tap
            .subscribe(onNext: { [weak self] in
                let menu = UIAlertController(title: "Sort By", message: nil, preferredStyle: .actionSheet)
                
                menu.addAction(
                    UIAlertAction(title: "Launch Date", style: .default) { [weak self] _ in
                        self?.viewModel!.sortKey = .launchDate
                        self?.requestLaunches.onNext(false)
                    }
                )
                
                menu.addAction(
                    UIAlertAction(title: "Launch Site", style: .default) { [weak self] _ in
                        self?.viewModel!.sortKey = .launchSite
                        self?.requestLaunches.onNext(false)
                    }
                )
                
                menu.addAction(
                    UIAlertAction(title: "Rocket Name", style: .default) { [weak self] _ in
                        self?.viewModel!.sortKey = .rocketName
                        self?.requestLaunches.onNext(false)
                    }
                )
                
                menu.addAction(
                    UIAlertAction(title: "Launch Status", style: .default) { [weak self] _ in
                        self?.viewModel!.sortKey = .launchStatus
                        self?.requestLaunches.onNext(false)
                    }
                )
                
                menu.addAction(
                    UIAlertAction(title: "Cancel", style: .cancel)
                )
                
                self?.present(menu, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }
    
    private var launchesDisposeBag: DisposeBag? = nil
    private var requestLaunches = PublishSubject<Bool>()
    private var onscreenDisposeBag = DisposeBag()
    private var disposeBag = DisposeBag()
    private var dataSource: RxTableViewSectionedReloadDataSource<ListTableSectionModel>! = nil
}
