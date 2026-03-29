import Foundation

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#endif

enum StderrCapture {

    static func capture(_ body: () -> Void) -> String {
        let pipe = Pipe()
        let savedFd = dup(STDERR_FILENO)
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)
        body()
        pipe.fileHandleForWriting.closeFile()
        dup2(savedFd, STDERR_FILENO)
        close(savedFd)
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    }

    static func captureAsync(_ body: () async -> Void) async -> String {
        let pipe = Pipe()
        let savedFd = dup(STDERR_FILENO)
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)
        await body()
        pipe.fileHandleForWriting.closeFile()
        dup2(savedFd, STDERR_FILENO)
        close(savedFd)
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    }
}
