//
//  Identifiable.swift
//  BwFramework
//
//  Created by Katsuhiko Terada on 2017/11/21.
//  Copyright (c) 2017 Katsuhiko Terada. All rights reserved.
//

import Foundation

// クラス文字列を返す classのみ適用
public protocol Identifiable: class {
    var identifier: String { get }
    static var identifier: String { get }

    var classIdentifier: String { get }
    static var classIdentifier: String { get }
}

// クラス文字列を返す
extension Identifiable {
    public var identifier: String { return classIdentifier }
    public static var identifier: String { return classIdentifier }

    public var classIdentifier: String { return String(describing: type(of: self)) }
    public static var classIdentifier: String { return String(describing: Self.self) }
}

// ユニークな識別子を返す
public protocol UniqueIdentifiable {
    var uniqueIdentifier: String { get }
}
