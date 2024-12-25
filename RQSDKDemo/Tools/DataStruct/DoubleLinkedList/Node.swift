//
//  Node.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 20/7/2023.
//

import Foundation

class Node<Value> {

    weak var previous: Node?
    var next: Node?
    
    var value: Value
    init(previous: Node? = nil, next: Node? = nil, value: Value) {
        self.previous = previous
        self.next = next
        self.value = value
    }
}
