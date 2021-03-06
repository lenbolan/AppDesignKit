//
// Copyright (c) 2020 Related Code - http://relatedcode.com
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import UIKit

//-------------------------------------------------------------------------------------------------------------------------------------------------
class Story2CollectionViewLayout: UICollectionViewFlowLayout {

	public var perspective: CGFloat = -1 / 500
	public var totalAngle: CGFloat = .pi / 2
	open override class var layoutAttributesClass: AnyClass { return AnimatedCollectionViewLayoutAttributes.self }


	//---------------------------------------------------------------------------------------------------------------------------------------------
	open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {

		guard let attributes = super.layoutAttributesForElements(in: rect) else { return nil }
		return attributes.compactMap { $0.copy() as? AnimatedCollectionViewLayoutAttributes }.map { self.transformLayoutAttributes($0) }
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	open override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {

		return true
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	private func transformLayoutAttributes(_ attributes: AnimatedCollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {

		guard let collectionView = self.collectionView else { return attributes }

		let a = attributes

		let distance: CGFloat
		let itemOffset: CGFloat

		if scrollDirection == .horizontal {
			distance = collectionView.frame.width
			itemOffset = a.center.x - collectionView.contentOffset.x
			a.startOffset = (a.frame.origin.x - collectionView.contentOffset.x) / a.frame.width
			a.endOffset = (a.frame.origin.x - collectionView.contentOffset.x - collectionView.frame.width) / a.frame.width
		} else {
			distance = collectionView.frame.height
			itemOffset = a.center.y - collectionView.contentOffset.y
			a.startOffset = (a.frame.origin.y - collectionView.contentOffset.y) / a.frame.height
			a.endOffset = (a.frame.origin.y - collectionView.contentOffset.y - collectionView.frame.height) / a.frame.height
		}

		a.scrollDirection = scrollDirection
		a.middleOffset = itemOffset / distance - 0.5

		if a.contentView == nil,
			let c = collectionView.cellForItem(at: attributes.indexPath)?.contentView {
			a.contentView = c
		}

		let position = attributes.middleOffset
		if abs(position) >= 1 {
			attributes.contentView?.layer.transform = CATransform3DIdentity
			attributes.contentView?.keepCenterAndApplyAnchorPoint(CGPoint(x: 0.5, y: 0.5))
		} else if attributes.scrollDirection == .horizontal {
			let rotateAngle = totalAngle * position
			var transform = CATransform3DIdentity
			transform.m34 = perspective
			transform = CATransform3DRotate(transform, rotateAngle, 0, 1, 0)

			attributes.contentView?.layer.transform = transform
			attributes.contentView?.keepCenterAndApplyAnchorPoint(CGPoint(x: position > 0 ? 0 : 1, y: 0.5))
		} else {
			let rotateAngle = totalAngle * position
			var transform = CATransform3DIdentity
			transform.m34 = perspective
			transform = CATransform3DRotate(transform, rotateAngle, -1, 0, 0)

			attributes.contentView?.layer.transform = transform
			attributes.contentView?.keepCenterAndApplyAnchorPoint(CGPoint(x: 0.5, y: position > 0 ? 0 : 1))
		}

		return a
	}
}

// MARK: - AnimatedCollectionViewLayoutAttributes
//-------------------------------------------------------------------------------------------------------------------------------------------------
fileprivate class AnimatedCollectionViewLayoutAttributes: UICollectionViewLayoutAttributes {

	public var contentView: UIView?
	public var scrollDirection: UICollectionView.ScrollDirection = .vertical
	public var startOffset: CGFloat = 0
	public var middleOffset: CGFloat = 0
	public var endOffset: CGFloat = 0

	//---------------------------------------------------------------------------------------------------------------------------------------------
	open override func copy(with zone: NSZone? = nil) -> Any {

		let copy = super.copy(with: zone) as! AnimatedCollectionViewLayoutAttributes
		copy.contentView = contentView
		copy.scrollDirection = scrollDirection
		copy.startOffset = startOffset
		copy.middleOffset = middleOffset
		copy.endOffset = endOffset
		return copy
	}

	//---------------------------------------------------------------------------------------------------------------------------------------------
	open override func isEqual(_ object: Any?) -> Bool {

		guard let o = object as? AnimatedCollectionViewLayoutAttributes else { return false }

		return super.isEqual(o)
			&& o.contentView == contentView
			&& o.scrollDirection == scrollDirection
			&& o.startOffset == startOffset
			&& o.middleOffset == middleOffset
			&& o.endOffset == endOffset
	}
}

// MARK: - UIView
//-------------------------------------------------------------------------------------------------------------------------------------------------
fileprivate extension UIView {

	//---------------------------------------------------------------------------------------------------------------------------------------------
	func keepCenterAndApplyAnchorPoint(_ point: CGPoint) {

		guard layer.anchorPoint != point else { return }

		var newPoint = CGPoint(x: bounds.size.width * point.x, y: bounds.size.height * point.y)
		var oldPoint = CGPoint(x: bounds.size.width * layer.anchorPoint.x, y: bounds.size.height * layer.anchorPoint.y)

		newPoint = newPoint.applying(transform)
		oldPoint = oldPoint.applying(transform)

		var c = layer.position
		c.x -= oldPoint.x
		c.x += newPoint.x

		c.y -= oldPoint.y
		c.y += newPoint.y

		layer.position = c
		layer.anchorPoint = point
	}
}

