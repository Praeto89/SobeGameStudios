extends CollisionPolygon2D


func _ready():
	$Polygon2D.polygon = self.polygon
