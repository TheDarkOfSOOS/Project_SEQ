shader_type canvas_item;
uniform bool look_right = true;

void vertex() {
	VERTEX.x = VERTEX.x * { -1.0, 1.0 }[int(look_right)];

	float xSkewRatio = step(UV.y, .5);
	vec2 skewTransition = vec2(abs(VERTEX.x) * xSkewRatio, 0.0);
	vec2 skewScale = vec2(VERTEX.x, (VERTEX.y + abs(VERTEX.y)) / 2.0);

	VERTEX = skewScale;

	VERTEX = VERTEX + skewTransition;
}

void fragment() {
	COLOR = vec4(vec3(.0), .5 * COLOR.a);
}

//void light() {
	//
	//
	//
	//// Called for every pixel for every light affecting the CanvasItem.
	//// Uncomment to replace the default light processing function with this one.
//}
