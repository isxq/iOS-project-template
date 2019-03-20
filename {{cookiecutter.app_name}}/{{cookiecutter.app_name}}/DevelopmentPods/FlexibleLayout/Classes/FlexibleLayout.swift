//
//  FlexibleLayout.swift
//  FlexibleLayout
//
//  Created by ios on 2019/3/19.
//  Copyright © 2019 ios. All rights reserved.
//

import Foundation
import UIKit

// MARK: - FlexibleLayout

indirect enum FlexibleLayout {
    
    case view(UIView, FlexibleSize?, FlexibleLayout)
    case space(FlexiblePadding, FlexibleLayout)
    case box(contens: FlexibleLayout, FlexiblePadding, wrapper: UIView?, FlexibleLayout)
    case newLine(space: FlexiblePadding, FlexibleLayout)
    case choice(FlexibleLayout, FlexibleLayout)
    case empty
}

extension FlexibleLayout {
    
    func apply(containerSize: CGSize) -> [UIView] {
        let lines = computeLines(containerFrame: CGRect(origin: .zero, size: containerSize))
        return lines.apply(containerFrame: CGRect(origin: .zero, size: containerSize))
    }
    
    func or(_ layout: FlexibleLayout) -> FlexibleLayout {
        return .choice(self, layout)
    }
    
    var centered: FlexibleLayout {
        return [.space(.flexible(min: 0), .empty), self, .space(.flexible(min: 0), .empty)].horizontal()
    }
    
    func box(wrapper: UIView? = nil, width: FlexiblePadding = .basedOnContents) -> FlexibleLayout {
        return .box(contens: self, width, wrapper: wrapper, .empty)
    }
    
    func computeLines(containerFrame: CGRect) -> [FlexibleLine] {
        var x = containerFrame.origin.x
        var y = containerFrame.origin.y
        
        var current = self
        var lines: [FlexibleLine] = []
        var line: FlexibleLine = FlexibleLine(elements: [], space: .absolute(0))
        while true {
            switch current {
                
            case let .view(v, nil, rest):
                let availableWidth = containerFrame.width - x
                let size = v.sizeThatFits(CGSize(width: availableWidth, height: .greatestFiniteMagnitude))
                x += size.width
                y += size.height
                let layoutSize = FlexibleSize(width: .absolute(size.width), height: .absolute(size.height))
                line.elements.append(.view(v, layoutSize))
                current = rest
                
            case let .view(v, size?, rest):
                x += size.width.min
                y += size.height.min
                line.elements.append(.view(v, size))
                current = rest
                
            case let .space(width, rest):
                x += width.min
                line.elements.append(.space(width))
                current = rest
                
            case let .box(contents, width, wrapper, rest):
                let horizontalMargins = (wrapper?.layoutMargins).map { $0.left + $0.right } ?? 0
                let verticalMargins = (wrapper?.layoutMargins).map { $0.top + $0.bottom } ?? 0
                
                let availableWidth = containerFrame.width - x - horizontalMargins
                let availableHeight = containerFrame.height - y - verticalMargins
                
                let boxFrame = CGRect(x: x, y: y, width: availableWidth, height: availableHeight)
                let lines = contents.computeLines(containerFrame: boxFrame)
                let result = FlexibleLine.Element.box(lines, width, wrapper: wrapper)
                x += result.minWidth
                y += result.minHeight
                line.elements.append(result)
                current = rest
                
            case let .newLine(space, rest):
                x = 0
                lines.append(line)
                line = FlexibleLine(elements: [], space: space)
                current = rest
                
            case let .choice(first, second):
                var firstLines = first.computeLines(containerFrame: containerFrame)
                firstLines[0].elements.insert(contentsOf: line.elements, at: 0)
                firstLines[0].space = firstLines[0].space + line.space
                let tooWide = firstLines.contains{ $0.minWidth >= containerFrame.width}
                if tooWide {
                    current = second
                } else {
                    current = first
                }
            case .empty:
                lines.append(line)
                
                return lines
            }
        }
    }
}

extension BidirectionalCollection where Element == FlexibleLayout {
    
    func horizontal(space: CGFloat = 0) -> FlexibleLayout {
        guard var result = last else {
            return .empty
        }
        for l in dropLast().reversed() {
            result = l + .space(.absolute(space), result)
        }
        return result
    }
    
    func flexibleHorizontal(min: CGFloat) -> FlexibleLayout {
        guard var result = last else {
            return .empty
        }
        for l in dropLast().reversed() {
            result = l + .space(.flexible(min: min), result)
        }
        return result
    }
    
    func vertical(space: CGFloat = 0) -> FlexibleLayout {
        guard var result = last else {
            return .empty
        }
        for l in dropLast().reversed() {
            result = l + .newLine(space: .absolute(space), result)
        }
        return result
    }
    
    func flexibleVertical(min: CGFloat = 0) -> FlexibleLayout {
        guard var result = last else {
            return .empty
        }
        for l in dropLast().reversed() {
            result = l + .newLine(space: .flexible(min: min), result)
        }
        return result
    }
}

func +(lhs: FlexibleLayout, rhs: FlexibleLayout) -> FlexibleLayout {
    switch lhs {
    case let .view(v, size, reminder):
        return .view(v, size, reminder + rhs)
    case let .space(space, reminder):
        return .space(space, reminder + rhs)
    case let .box(content, width, wrapper, reminder):
        return .box(contens: content, width, wrapper: wrapper, reminder + rhs)
    case let .newLine(space, reminder):
        return .newLine(space: space, reminder + rhs)
    case let .choice(l, r):
        return .choice(l + rhs, r + rhs)
    case .empty:
        return rhs
    }
}

// MARK: - Line

enum FlexiblePadding: Equatable {
    case absolute(CGFloat)
    case flexible(min: CGFloat)
    case basedOnContents
    
    var min: CGFloat {
        switch self {
        case let .absolute(x):
            return x
        case let .flexible(min: x):
            return x
        case .basedOnContents:
            return 0
        }
    }
    
    var isFlexible: Bool {
        switch self {
        case .absolute, .basedOnContents:
            return false
        case .flexible:
            return true
        }
    }
    
    var isAbsolute: Bool {
        switch self {
        case .flexible, .basedOnContents:
            return false
        case .absolute:
            return true
        }
    }
    
    static func + (lhs: FlexiblePadding, rhs: FlexiblePadding) -> FlexiblePadding {
        switch lhs {
        case let .absolute(l):
            switch rhs {
            case let .absolute(r):
                return .absolute(l + r)
            case let .flexible(min: r):
                return .flexible(min: l + r)
            case .basedOnContents:
                return lhs
            }
        case let .flexible(l):
            return .flexible(min: l + rhs.min)
        case .basedOnContents:
            return rhs
        }
    }
    
}

struct FlexibleLine {
    enum Element {
        case view(UIView, FlexibleSize)
        case box([FlexibleLine], FlexiblePadding, wrapper: UIView?)
        case space(FlexiblePadding)
    }
    var elements: [Element]
    var space: FlexiblePadding
    
    var isFlexible: Bool {
        return space.isFlexible
    }
    
    var minWidth: CGFloat {
        return elements.reduce(0) {$0 + $1.minWidth}
    }
    
    var minHeight: CGFloat {
        return space.min + (elements.map { $0.minHeight }.max() ?? 0)
    }
    
    func absolute(flexibleSpace: CGFloat) -> CGFloat {
        switch space {
        case let .absolute(w):
            return w
        case let .flexible(min):
            return min + flexibleSpace
        case .basedOnContents:
            return 0
        }
    }
    
    
    var numberOfFlexibleSpaces: Int {
        return elements.filter { $0.isFlexible }.count
    }
}

struct FlexibleSize {
    var width: FlexiblePadding
    var height: FlexiblePadding
    
    var min: CGSize {
        return CGSize(width: width.min, height: height.min)
    }
}

extension FlexibleLine.Element {
    
    var minWidth: CGFloat {
        switch self {
        case let .view(_, size):
            return size.width.min
        case let .box(lines, w, wrapper):
            guard w == .basedOnContents else { return w.min }
            let margins = (wrapper?.layoutMargins).map { $0.left + $0.right } ?? 0
            return (lines.map { $0.minWidth }.max() ?? 0) + margins
        case let .space(width):
            return width.min
        }
    }
    
    var minHeight: CGFloat {
        switch self {
        case let .view(_, size):
            return size.height.min
        case let .box(lines, _, wrapper):
            let margins = (wrapper?.layoutMargins).map { $0.top + $0.bottom } ?? 0
            return lines.reduce(0) { $0 + $1.minHeight } + margins
        case let .space(height):
            return height.min
        }
    }
    
    
    var isFlexible: Bool {
        switch self {
        case let .view(_, size):
            return size.width.isFlexible
        case let .box(_, w, _):
            return w.isFlexible
        case let .space(width):
            return width.isFlexible
        }
    }
    
    var width: FlexiblePadding {
        switch self {
        case let .view(_, size):
            return size.width
        case let .space(w), let .box(_, w, _):
            return w
        }
    }
    
    var height: FlexiblePadding {
        switch self {
        case let .view(_, size):
            return size.height
        case .space, .box:
            return .basedOnContents
        }
    }
    
    
    func absolute(horizontalSpace: CGFloat) -> CGFloat {
        switch width {
        case let .absolute(w):
            return w
        case let .flexible(min):
            return min + horizontalSpace
        case .basedOnContents:
            return minWidth
        }
    }
    
    func absolute(verticalSpace: CGFloat) -> CGFloat {
        switch height {
        case let .absolute(h):
            return h
        case let .flexible(min: min):
            return min + verticalSpace
        case .basedOnContents:
            return minHeight
        }
    }
    
}

extension Array where Element == FlexibleLine {
    
    var spaceCount: Int {
        return filter { $0.isFlexible }.count
    }
    
    func apply(containerFrame: CGRect)->[UIView] {
        
        var result: [UIView] = []
        var origin = containerFrame.origin
        
        let minHeight = reduce(0) { $0 + $1.minHeight }
        let verticalAvailableSpace = containerFrame.height - minHeight
        var verticalFlexibleSpace: CGFloat = 0.0
        
        if verticalAvailableSpace != 0 && spaceCount > 0 {
            verticalFlexibleSpace = verticalAvailableSpace / CGFloat(spaceCount)
        }
        
        for line in self {
            origin.x = containerFrame.origin.x
            origin.y += line.absolute(flexibleSpace: verticalFlexibleSpace)
            let horizontalAvailableSpace = containerFrame.width - line.minWidth
            let horizontalFlexibleSpace = horizontalAvailableSpace / CGFloat(line.numberOfFlexibleSpaces)
            
            var lineHeight: CGFloat = 0
            var lineViews: [UIView] = []
            for element in line.elements {
                switch element {
                    
                case let .box(contents, _, nil):
                    let width = element.absolute(horizontalSpace: horizontalFlexibleSpace)
                    let size = CGSize(width: width, height: containerFrame.height)
                    let boxFrame = CGRect(origin: origin, size: size)
                    let views = contents.apply(containerFrame: boxFrame)
                    origin.x += width
                    let height = (views.map { $0.frame.maxY }.max() ?? origin.y) - origin.y
                    lineHeight = Swift.max(lineHeight, height)
                    lineViews.append(contentsOf: views)
                    
                case let .box(contents, _, wrapper?):
                    let width = element.absolute(horizontalSpace: horizontalFlexibleSpace)
                    let margins = wrapper.layoutMargins.left + wrapper.layoutMargins.right
                    let boxFrame = CGRect(x: wrapper.layoutMargins.left, y: wrapper.layoutMargins.top, width: width - margins, height: containerFrame.height)
                    let subviews = contents.apply(containerFrame: boxFrame)
                    let contentMaxY = subviews.map { $0.frame.maxY }.max() ?? 0
                    wrapper.setupSubviews(subviews)
                    let size = CGSize(width: width, height: contentMaxY + wrapper.layoutMargins.bottom)
                    wrapper.frame = CGRect(origin: origin, size: size)
                    
                    lineHeight = Swift.max(lineHeight, size.height)
                    origin.x += size.width
                    lineViews.append(wrapper)
                case .space(_):
                    origin.x += element.absolute(horizontalSpace: horizontalFlexibleSpace)
                case let .view(v, _):
                    lineViews.append(v)
                    let width = element.absolute(horizontalSpace: horizontalFlexibleSpace)
                    let height = element.absolute(verticalSpace: verticalFlexibleSpace)
                    let viewSize = CGSize(width: width, height: height)
                    v.frame = CGRect(origin: origin, size: viewSize)
                    origin.x += viewSize.width
                    lineHeight = Swift.max(lineHeight, height)
                }
            }
            result.append(contentsOf: lineViews)
            origin.y += lineHeight
            
        }
        return result
    }
}

//MARK: - UI Extensions

final class LayoutContainer: UIView {
    private let _layout: FlexibleLayout
    
    init(_ layout: FlexibleLayout) {
        _layout = layout
        super.init(frame: .zero)
        NotificationCenter.default.addObserver(self, selector: #selector(setNeedsLayout), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        let views = _layout.apply(containerSize: bounds.size)
        setupSubviews(views)
        frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: views.last?.frame.maxY ?? 0)
    }
}


extension UIView {
    
    convenience init(bgColor: UIColor, cornerRadius: CGFloat) {
        self.init(frame: .zero)
        backgroundColor = bgColor
        layer.cornerRadius = cornerRadius
    }
    
    var layout: FlexibleLayout {
        return .view(self, nil, .empty)
    }
    
    func layout(size: FlexibleSize) -> FlexibleLayout {
        return .view(self, size, .empty)
    }
    
    var size: CGSize {
        return frame.size
    }
    
    func setupSubviews<S:Sequence>(_ other: S) where S.Element == UIView {
        let views = Set(other)
        let sub = Set(subviews)
        for v in sub.subtracting(views) {
            v.removeFromSuperview()
        }
        for v in views.subtracting(sub) {
            addSubview(v)
        }
    }
    
}

extension UILabel {
    convenience init(text: String, size: UIFont.TextStyle, textColor: UIColor? = nil, multiline: Bool = false) {
        self.init()
        if let textColor = textColor {
            self.textColor = textColor
        }
        font = UIFont.preferredFont(forTextStyle: size)
        self.text = text
        adjustsFontForContentSizeCategory = true
        if multiline {
            numberOfLines = 0
        }
    }
}
