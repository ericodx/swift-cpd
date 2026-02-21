actor ProgressState {

    private var task: Task<Void, any Error>?

    func storeTask(_ task: Task<Void, any Error>) {
        self.task = task
    }

    func cancelTask() {
        task?.cancel()
        task = nil
    }
}
