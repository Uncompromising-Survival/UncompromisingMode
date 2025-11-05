#define VERTEX_SHADER

uniform mat4 MatrixPVW;

attribute vec3 POSITION;
attribute vec3 TEXCOORD0_LIFE;
attribute vec4 DIFFUSE;

varying vec3 PS_TEXCOORD_LIFE;
varying vec4 PS_COLOUR;
varying vec3 PS_POS;

void main() {
	vec3 pos = floor(POSITION + 0.5);

	gl_Position = MatrixPVW * vec4(pos, 1.0);

	PS_POS.xyz = pos;
	PS_TEXCOORD_LIFE.xyz = TEXCOORD0_LIFE.xyz;
	PS_COLOUR = DIFFUSE;
	PS_COLOUR.rgb *= PS_COLOUR.a;
}
