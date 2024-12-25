//
//  DoubleLinkedList.swift
//  RQSDKDemo
//
//  Created by xiaojuntao on 20/7/2023.
//

import Foundation

class DoubleLinkedList<NodeValue> {
    
    var head: Node<NodeValue>?
        
    var tail: Node<NodeValue>? {
        get {
            var node: Node? = self.head
            while node?.next != nil {
                node = node?.next
            }
            return node
        }
    }
    
    convenience init(nodes: [Node<NodeValue>]) {
        self.init()
        self.head = nodes.first
        var ptr = self.head
        for elem in nodes {
            if self.head === elem { continue }
            ptr?.next = elem
            elem.previous = ptr
            ptr = elem
        }
    }
    
    func append(node: Node<NodeValue>) {
        if let tail = self.tail {
            tail.next = node
            node.previous = tail
        }else{
            self.head = node
        }
    }
    
    func search(filter: ((Node<NodeValue>?)->Bool)) -> [Node<NodeValue>] {
        var result: [Node<NodeValue>] = []
        var node: Node<NodeValue>? = self.head
        repeat {
            node = node?.next
            if let node = node, filter(node) {
                result.append(node)
            }
        } while node != nil
        return result
    }
}
