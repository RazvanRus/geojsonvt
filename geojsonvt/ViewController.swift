import UIKit

class ViewController: UIViewController {

    var vt: GeoJSONVT!
    var imageView: UIImageView!
    var z: Int = 0
    var x: Int = 0
    var y: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        print("@!#!@#1")
        
        do {
            let json = try NSString(contentsOfFile: Bundle.main.path(forResource: "threestates", ofType: "geojson")!, encoding: String.Encoding.utf8.rawValue)
            NSLog("loaded up feature JSON of \(json.length) bytes")
            
            DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
                self.vt = GeoJSONVT(data: json as String, debug: true)
                DispatchQueue.main.async {
                    [unowned self] in
                    self.drawTile()
                }
            }

        } catch {
            print("there is a problem with json")
        }
        
        
        let size = self.view.bounds.size.width

        self.imageView = UIImageView(frame: CGRect(x: 0, y: (self.view.bounds.size.height - size) / 2, width: size, height: size))
        self.imageView.isUserInteractionEnabled = true
        self.imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(singleTap(gesture:))))
        self.imageView.addGestureRecognizer({
            let gesture = UITapGestureRecognizer(target: self, action: #selector(twoFingerTap(gesture:)))
            gesture.numberOfTouchesRequired = 2
            return gesture
            }())
        self.view.addSubview(self.imageView)
    }

    func drawTile() {
        let size = self.view.bounds.size.width

        UIGraphicsBeginImageContext(CGSize(width: size, height: size))
        let c = UIGraphicsGetCurrentContext()

        c!.setFillColor(UIColor.white.cgColor)
        c!.fill(CGRect(x: 0, y: 0, width: size, height: size))

        c!.setStrokeColor(UIColor.red.cgColor)
        c!.setFillColor(UIColor.red.withAlphaComponent(0.05).cgColor)

        let tile = self.vt.getTile(z: self.z, x: self.x, y: self.y)

        if (tile != nil) {
            let extent: Double = 4096
            for feature in tile!.features {
                for geometry in feature.geometry {
                    if (feature.type == .Point) {
                        let radius: CGFloat = 1
                        let point = geometry as! TilePoint
                        let x = CGFloat((Double(point.x) / extent) * Double(size))
                        let y = CGFloat((Double(point.y) / extent) * Double(size))
                        let dot = CGRect(x: (x - radius), y: (y - radius), width: (radius * 2), height: (radius * 2))
                        c!.addEllipse(in: dot)
                    } else {
                        var pointCount = 0
                        let ring = geometry as! TileRing
                        for point in ring.points {
                            let x = CGFloat((Double(point.x) / extent) * Double(size))
                            let y = CGFloat((Double(point.y) / extent) * Double(size))
                            if (pointCount == 0) {
                                c!.move(to: CGPoint(x: x, y: y))
                            } else {
                                c!.addLine(to: CGPoint(x: x, y: y))
                            }
                            pointCount += 1
                        }
                    }
                }
                if (feature.type == .Polygon) {
                    let p = c!.path
                    c!.fillPath()
                    c!.addPath(p!)
                }
                c!.strokePath()
            }

            c!.setStrokeColor(UIColor.green.cgColor)
            c!.setLineWidth(1)
            c!.stroke(CGRect(x: 0, y: 0, width: size, height: size))
            c!.move(to: CGPoint(x: size / 2, y: 0))
            c!.addLine(to: CGPoint(x: size / 2, y: size))
            c!.move(to: CGPoint(x: 0, y: size / 2))
            c!.addLine(to: CGPoint(x: size, y: size / 2))
            c!.strokePath()

            self.imageView.image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        } else {
            self.zoomOut()
        }
    }

    func zoomOut() {
        self.z -= 1
        self.x = x / 2
        self.y = y / 2

        if (z < 0) {
            z = 0
        }

        if (x < 0) {
            x = 0
        }

        if (y < 0) {
            y = 0
        }
    }

    @objc func singleTap(gesture: UITapGestureRecognizer) {
        let left = (gesture.location(in: gesture.view).x / self.view.bounds.size.width < 0.5)
        let top  = (gesture.location(in: gesture.view).y / self.view.bounds.size.width < 0.5)

        self.z += 1
        self.x *= 2
        self.y *= 2
        if (!left) {
            self.x += 1
        }
        if (!top) {
            self.y += 1
        }

        self.drawTile()
    }

    @objc func twoFingerTap(gesture: UITapGestureRecognizer) {
        self.zoomOut()
        self.drawTile()
    }

}
