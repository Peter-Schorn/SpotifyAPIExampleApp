import Foundation
import Combine

extension Publisher {
    
    /**
     Blocks the thread until a single value is received.
     
     If the publisher finishes normally before a value is received,
     then `nil` is returned.
     
     - Throws: If the publisher finishes with an error.
     
     */
    func waitForSingleValue() throws -> Output? {
        
        var error: Error? = nil
        var output: Output? = nil
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let cancellable = self.sink(
            receiveCompletion: { completion in
                if case .failure(let failure) = completion {
                    error = failure
                }
                semaphore.signal()
            },
            receiveValue: { value in
                output = value
                semaphore.signal()
            }
        )
        
        _ = cancellable
        
        semaphore.wait()
        
        if let error = error {
            throw error
        }
        
        return output
        
    }
    
    /**
     Blocks the thread until the publisher receives the specified number
     of values or finishes normally.
     
     If the publisher finishes normally before any values are received, then
     an empty array is returned.
     
     - Parameter count: The number of values to wait for before returning.
     If `nil`, then wait for the publisher to finish before returning.
     
     - Throws: If the publisher finishes with an error.
     
     - Returns: The values received from the publisher.
     
     */
    func waitForValues(count: Int? = nil) throws -> [Output] {
        
        var error: Error? = nil
        var output: [Output] = []
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let queue = DispatchQueue(
            label: "\(Self.self).waitForValues"
        )
        
        let cancellable = self
            .receive(on: queue)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let failure) = completion {
                        error = failure
                    }
                    semaphore.signal()
                },
                receiveValue: { value in
                    output.append(value)
                    if let count = count, output.count >= count {
                        assert(output.count == count)
                        semaphore.signal()
                    }
                }
            )
        
        _ = cancellable
        
        semaphore.wait()
        
        if let error = error {
            throw error
        }
        
        return output
        
    }
    
    func sink<S: Scheduler>(
        delay: S.SchedulerTimeType.Stride,
        scheduler: S,
        options: S.SchedulerOptions? = nil,
        receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void,
        receiveValue: @escaping ((Output) -> Void)
    ) -> AnyCancellable {
        
        let subscriber = Subscribers.Sink<Output, Failure>(
            receiveCompletion: receiveCompletion,
            receiveValue: receiveValue
        )
        scheduler.schedule(
            after: scheduler.now.advanced(by: delay),
            tolerance: scheduler.minimumTolerance,
            options: options
        ) {
            self.subscribe(subscriber)
        }
        return AnyCancellable(subscriber)
    }
    
}
