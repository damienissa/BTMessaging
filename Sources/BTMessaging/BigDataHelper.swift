//
//  File.swift
//  
//
//  Created by Dima Virych on 19.06.2020.
//

import Foundation

public
class BigDataHelper {
    
    private var count = 0
    private var datas: [Data] = []
    private let completion: (String) -> Void
  
    public
    init(with completion: @escaping (String) -> Void) {
        self.completion = completion
    }
    
    public
    func receive(_ data: Data) {
        
        if let str = data.string, str.contains("Size: "), let c = Int(str.replacingOccurrences(of: "Size: ", with: "")) {
            count = c
            return
        }
        
        if count == 0 {
            return
        }
        if data.string != nil {
            datas.append(data)
        }
    
        if datas.count == count {
            let arr = datas.map { [UInt8]($0) }.flatMap { $0 }
            let dat = Data(arr.filter( { $0 != 0 }))
            completion(dat.string ?? "-")
            datas = []
            count = 0
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

public 
extension String {
    
    func chunkedData(with size: Int) -> [Data] {
        
        let arr = Array(self).chunked(into: size).compactMap { String($0).data(using: .utf8) }
        var dat = ["Size: \(arr.count)".data(using: .utf8)!]
        dat.append(contentsOf: arr)

        return dat
    }
}
