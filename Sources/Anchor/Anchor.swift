import UIKit

public class Anchor {
  enum To {
    case anchor(Anchor)
    case size
    case none
  }

  class Pin {
    let attribute: NSLayoutAttribute
    var constant: CGFloat

    init(_ attribute: NSLayoutAttribute, constant: CGFloat = 0) {
      self.attribute = attribute
      self.constant = constant
    }
  }

  let view: UIView

  // key: attribute
  // value: constant
  var pins: [Pin] = []
  var multiplierValue: CGFloat = 1
  var priorityValue: Float?
  var identifierValue: String?
  var referenceBlock: (([NSLayoutConstraint]) -> Void)?
  var relationValue: NSLayoutRelation = .equal
  var toValue: To = .none

  init(view: UIView) {
    view.translatesAutoresizingMaskIntoConstraints = false
    self.view = view
  }
}

// MARK: - Conveninent Attributes

public extension Anchor {
  var edges: Anchor {
    pins.removeAll()
    return top.right.bottom.left
  }

  var center: Anchor {
    return centerX.centerY
  }
}

// MARK: - Configuration

public extension Anchor {

  func insets(_ insets: UIEdgeInsets) -> Self {
    updateIfAny(.top, insets.top)
    updateIfAny(.bottom, insets.bottom)
    updateIfAny(.left, insets.left)
    updateIfAny(.right, insets.right)
    return self
  }

  func constant(_ value: CGFloat) -> Self {
    pins.forEach {
      $0.constant = value
    }

    return self
  }

  func multiplier(_ value: CGFloat) -> Self {
    multiplierValue = value
    return self
  }

  func priority(_ value: Float) -> Self {
    priorityValue = value
    return self
  }

  func id(_ value: String) -> Self {
    identifierValue = value
    return self
  }

  func ref(_ block: @escaping ([NSLayoutConstraint]) -> Void) -> Self {
    referenceBlock = block
    return self
  }
}

// MARK: - Relation

public extension Anchor {
  var equal: Anchor {
    relationValue = .equal
    return self
  }

  var lessThanOrEqual: Anchor {
    relationValue = .lessThanOrEqual
    return self
  }

  var greaterThanOrEqual: Anchor {
    relationValue = .greaterThanOrEqual
    return self
  }
}

// MARK: - To

public extension Anchor {

  func to(_ anchor: Anchor) -> Self {
    toValue = .anchor(anchor)
    return self
  }

  func to(_ size: CGFloat) -> Self {
    toValue = .size
    updateIfAny(.width, size)
    updateIfAny(.height, size)
    return self
  }
}

// MARK: - Constraints

public extension Anchor {
  func constraints() -> [NSLayoutConstraint] {
    let constraints = output()
    constraints.forEach {
      if let identifierValue = identifierValue {
        $0.identifier = identifierValue
      }

      if let priorityValue = priorityValue {
        $0.priority = priorityValue
      }
    }

    referenceBlock?(constraints)
    return constraints
  }
}

// MARK: - Output Helper

extension Anchor {
  func output() -> [NSLayoutConstraint] {
    switch toValue {
    case .anchor(let anchor):
      return output(anchor: anchor)
    case .size:
      return outputForSize()
    case .none:
      if let superview = view.superview {
        return output(anchor: Anchor(view: superview))
      } else {
        return []
      }
    }
  }

  func outputForSize() -> [NSLayoutConstraint] {
    return pins
      .filter({
        return $0.attribute == .width || $0.attribute == .height
      })
      .map({
        let constraint = NSLayoutConstraint(item: view,
                                            attribute: $0.attribute,
                                            relatedBy: relationValue,
                                            toItem: nil,
                                            attribute: .notAnAttribute,
                                            multiplier: multiplierValue,
                                            constant: $0.constant)
        return constraint
      })
  }

  func output(anchor anotherAnchor: Anchor) -> [NSLayoutConstraint] {
    let anotherPins = anotherAnchor.pins.isEmpty ? pins : anotherAnchor.pins
    let pairs = zip(pins, anotherPins)

    return pairs.map({ pin, anotherPin in
      let constraint = NSLayoutConstraint(item: view,
                                          attribute: pin.attribute,
                                          relatedBy: relationValue,
                                          toItem: anotherAnchor.view,
                                          attribute: anotherPin.attribute,
                                          multiplier: multiplierValue,
                                          constant: pin.constant)
      return constraint
    })
  }
}

// MARK: - Update

extension Anchor {
  func updateIfAny(_ attribute: NSLayoutAttribute, _ constant: CGFloat) {
    let pin = pins.filter({ $0.attribute == attribute }).first
    pin?.constant = constant
  }
}
