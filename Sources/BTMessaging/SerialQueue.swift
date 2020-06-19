//
//  File.swift
//  
//
//  Created by Dima Virych on 19.06.2020.
//

import Foundation

public final class SerialQueue {
    
    // MARK: - Types
    
    public typealias Operation = () -> Void
    
    
    // MARK: - Properties
    
    private let serialQueue = DispatchQueue(label: "com.EZUtilites.serial.worker", qos: .background)
    
    private var operations: [Operation] = []
    
    
    // MARK: - Lifecycle
    
    public init() { }
    
    
    // MARK: - Actions
    
    public func addOperation(_ operation: @escaping Operation) {
        
        operations.append(operation)
        start()
    }
    
    public func stop() {
        
        operations = []
    }
    
    public func start(_ progress: ((Int) -> ())? = nil,  _ completion: (() -> ())? = nil) {
        
        progress?(operations.count)
        
        if operations.isEmpty { return completion?() ?? () }
        
        let operation = operations.first
        _ = operations.removeFirst()
        
        serialQueue.async { [weak self] in
            operation?()
            self?.start(progress, completion)
        }
    }
}
