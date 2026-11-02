#version 140

in mediump vec3 var_normal;
in highp float var_depth;

out vec4 out_fragColor;

uniform fs_uniforms
{
    mediump vec4 tint;
    mediump vec4 fog_color;
    mediump vec4 fog_params;
};

void main()
{
    vec3 n = normalize(var_normal);
    vec3 sun_dir = normalize(vec3(0.45, 0.8, 0.35));
    float diffuse = max(dot(n, sun_dir), 0.0);
    float hemi = 0.5 + 0.5 * n.y;
    vec3 ambient = mix(vec3(0.30, 0.22, 0.20), vec3(0.58, 0.52, 0.48), hemi);
    vec3 light = vec3(1.0, 0.92, 0.80) * diffuse * 0.72 + ambient;

    vec3 color = tint.rgb * light;
    float fog = clamp((var_depth - fog_params.x) / (fog_params.y - fog_params.x), 0.0, 1.0);
    color = mix(color, fog_color.rgb, fog * fog_color.a);
    out_fragColor = vec4(color, 1.0);
}
