import Foundation
import Combine

extension Publisher {
    
    func awaitSingleValue() async throws -> Output? {
        
        return try await withCheckedThrowingContinuation { continuation in
            
            var didSendValue = false
            
            var cancellable: AnyCancellable? = nil
            
            cancellable = self
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                            case .finished:
                                if !didSendValue {
                                    continuation.resume(returning: nil)
                                }
                            case .failure(let error):
                                continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { value in
                        // prevent any more values from being received
                        cancellable?.cancel()
                        
                        if !didSendValue {
                            didSendValue = true
                            continuation.resume(returning: value)
                        }
                        
                    }
                )
            
            
            
        }
    }
    
    func awaitValues() -> AsyncThrowingStream<Output, Error> {
        return AsyncThrowingStream { continuation in
            
            let cancellable = self
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                            case .finished:
                                continuation.finish()
                            case .failure(let error):
                                continuation.finish(throwing: error)
                        }
                    },
                    receiveValue: { value in
                        continuation.yield(value)
                    }
                )
            
            continuation.onTermination = { @Sendable termination in
                cancellable.cancel()
            }
            
        }
    }
    
}
