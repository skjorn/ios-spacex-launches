//

protocol Service {
    func start()
    func stop()
}

enum ServiceError: Error {
    case serviceStopped
}

