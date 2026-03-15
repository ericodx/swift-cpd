actor ProgressState {

    private var task: Task<Void, Never>?

    func storeTask(_ task: Task<Void, Never>) {
        self.task = task
    }

    func cancelTask() {
        task?.cancel()
        task = nil
    }
}
