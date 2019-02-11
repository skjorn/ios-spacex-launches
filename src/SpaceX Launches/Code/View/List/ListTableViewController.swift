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
        addSearchBar()

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
                let searchDriver = requestSearch.asDriver(onErrorDriveWith: Driver.empty())
                let input = ListViewModel.Input(requestLaunches: requestLaunchesSignal, search: searchDriver)
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
                    let errorMessage = NSLocalizedString("list.listTableViewController.downloadError", value: "Failed to download data", comment: "")
                    self.flowDelegate?.showError(message: errorMessage)
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
        
        // Initialize search
        
        requestSearch.onNext(navigationItem.searchController?.searchBar.text)
    }
    
    private func addSortMenu() {
        let sortButtonLabel = NSLocalizedString("list.listTableViewController.sortButton", value: "Sort", comment: "Navigation button label")
        let sortTitle = NSLocalizedString("list.listTableViewController.sortTitle", value: "Sort By", comment: "Action sheet title")
        let launchDateLabel = NSLocalizedString("list.listTableViewController.launchDateLabel", value: "Launch Date", comment: "Action label")
        let launchSiteLabel = NSLocalizedString("list.listTableViewController.launchSiteLabel", value: "Launch Site", comment: "Action label")
        let rocketNameLabel = NSLocalizedString("list.listTableViewController.rocketNameLabel", value: "Rocket Name", comment: "Action label")
        let launchStatusLabel = NSLocalizedString("list.listTableViewController.launchStatusLabel", value: "Launch Status", comment: "Action label")
        let cancelLabel = NSLocalizedString("list.listTableViewController.cancelLabel", value: "Cancel", comment: "Action label")

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: sortButtonLabel, style: .plain, target: nil, action: nil)
        navigationItem.rightBarButtonItem!.rx.tap
            .subscribe(onNext: { [weak self] in
                let menu = UIAlertController(title: sortTitle, message: nil, preferredStyle: .actionSheet)
                
                menu.addAction(
                    UIAlertAction(title: launchDateLabel, style: .default) { [weak self] _ in
                        self?.viewModel!.sortKey = .launchDate
                        self?.requestLaunches.onNext(false)
                    }
                )
                
                menu.addAction(
                    UIAlertAction(title: launchSiteLabel, style: .default) { [weak self] _ in
                        self?.viewModel!.sortKey = .launchSite
                        self?.requestLaunches.onNext(false)
                    }
                )
                
                menu.addAction(
                    UIAlertAction(title: rocketNameLabel, style: .default) { [weak self] _ in
                        self?.viewModel!.sortKey = .rocketName
                        self?.requestLaunches.onNext(false)
                    }
                )
                
                menu.addAction(
                    UIAlertAction(title: launchStatusLabel, style: .default) { [weak self] _ in
                        self?.viewModel!.sortKey = .launchStatus
                        self?.requestLaunches.onNext(false)
                    }
                )
                
                menu.addAction(
                    UIAlertAction(title: cancelLabel, style: .cancel)
                )
                
                self?.present(menu, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }
    
    private func addSearchBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: nil, action: nil)
        navigationItem.leftBarButtonItem!.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self else {
                    return
                }
                
                let searchCtrl = UISearchController(searchResultsController: nil)
                searchCtrl.searchResultsUpdater = self
                searchCtrl.obscuresBackgroundDuringPresentation = false
                self.navigationItem.searchController = searchCtrl
                self.navigationItem.searchController!.searchBar.becomeFirstResponder()
                self.navigationItem.searchController!.isActive = true
                
                searchCtrl.rx.willDismiss
                    .subscribe(onNext: { [weak self] in
                        self?.navigationItem.searchController = nil
                        self?.requestSearch.onNext(nil)
                    })
                    .disposed(by: self.disposeBag)
                
                searchCtrl.searchBar.rx.cancelButtonClicked
                    .subscribe(onNext: { [weak self] in
                        self?.navigationItem.searchController = nil
                        self?.requestSearch.onNext(nil)
                    })
                    .disposed(by: self.disposeBag)
            })
            .disposed(by: disposeBag)
        definesPresentationContext = true
    }
    
    private var launchesDisposeBag: DisposeBag? = nil
    private var requestLaunches = PublishSubject<Bool>()
    private var onscreenDisposeBag = DisposeBag()
    private var disposeBag = DisposeBag()
    private var dataSource: RxTableViewSectionedReloadDataSource<ListTableSectionModel>! = nil
    private var requestSearch = PublishSubject<String?>()
}

extension ListTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        requestSearch.onNext(searchController.searchBar.text)
    }
}
