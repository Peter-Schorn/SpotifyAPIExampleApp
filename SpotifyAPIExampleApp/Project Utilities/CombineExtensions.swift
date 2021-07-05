import Foundation
import Combine

extension Publisher {
    
    func awaitValues() async throws -> [Output] {

        return try await withCheckedThrowingContinuation { continuation in

            let queue = DispatchQueue(
                label: "\(Self.self).waitForValues"
            )
            
            var output: [Output] = []

            var cancellable: AnyCancellable? = self
                .receive(on: queue)
                .sink(
                    receiveCompletion: { completion in
                        // prevent the cancellable from being deallocated
                        cancellable = nil
                        _ = cancellable
                        switch completion {
                            case .finished:
                                continuation.resume(returning: output)
                            case .failure(let error):
                                continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { value in
                        output.append(value)
                    }
                )
            

        }
    }
    
    func awaitSingleValue() async throws -> Output? {
        
        return try await withCheckedThrowingContinuation { continuation in
            
            var output: Output? = nil
            
            var cancellable: AnyCancellable? = self
                .sink(
                    receiveCompletion: { completion in
                        // prevent the cancellable from being deallocated
                        cancellable = nil
                        _ = cancellable
                        switch completion {
                            case .finished:
                                continuation.resume(returning: output)
                            case .failure(let error):
                                continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { value in
                        output = value
                    }
                )
            
            
        }
    }
    
    

}
