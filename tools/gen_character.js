// Generates entities/character/character.collection: a primitive low-poly humanoid
// with pivot game objects acting as sockets (arm_r = Hand_R_Socket, arm_l = Hand_L_Socket, ...).
// Run: node tools/gen_character.js
const fs = require("fs");
const path = require("path");

const CUBE = "/assets/models/cube_part.go";
const SPHERE = "/assets/models/sphere_part.go";

// [id, parent, prototype|null (pivot), pos, scale]
const parts = [
  ["root", null, null, [0, 0, 0], [1, 1, 1]],
  ["shadow", "root", SPHERE, [0, 0.02, 0], [0.95, 0.02, 0.95]],
  ["leg_l", "root", null, [-0.14, 0.82, 0], [1, 1, 1]],
  ["leg_l_mesh", "leg_l", CUBE, [0, -0.4, 0], [0.2, 0.82, 0.24]],
  ["leg_r", "root", null, [0.14, 0.82, 0], [1, 1, 1]],
  ["leg_r_mesh", "leg_r", CUBE, [0, -0.4, 0], [0.2, 0.82, 0.24]],
  ["torso", "root", CUBE, [0, 1.18, 0], [0.56, 0.72, 0.32]],
  ["belt", "root", CUBE, [0, 0.86, 0], [0.6, 0.14, 0.36]],
  ["head", "root", SPHERE, [0, 1.74, 0], [0.34, 0.38, 0.34]],
  ["helmet", "root", CUBE, [0, 1.86, 0], [0.4, 0.2, 0.4]],
  ["pad_l", "root", CUBE, [-0.36, 1.5, 0], [0.26, 0.14, 0.38]],
  ["pad_r", "root", CUBE, [0.36, 1.5, 0], [0.26, 0.14, 0.38]],
  ["back", "root", CUBE, [0, 1.25, 0.24], [0.42, 0.52, 0.18]],
  ["arm_r", "root", null, [0.38, 1.42, 0], [1, 1, 1]],
  ["arm_r_mesh", "arm_r", CUBE, [0, 0, -0.22], [0.14, 0.14, 0.48]],
  ["weapon", "arm_r", CUBE, [0, 0, -0.9], [0.08, 0.08, 0.9]],
  ["arm_l", "root", null, [-0.38, 1.42, 0], [1, 1, 1]],
  ["arm_l_mesh", "arm_l", CUBE, [0, 0, -0.22], [0.14, 0.14, 0.48]],
  ["shield", "arm_l", CUBE, [0, -0.05, -0.48], [0.62, 0.72, 0.07]],
];

const v3 = (n, [x, y, z]) => `  ${n} {\n    x: ${x}\n    y: ${y}\n    z: ${z}\n  }\n`;
let out = 'name: "character"\n';
for (const [id, parent, proto, pos, scale] of parts) {
  const children = parts.filter((p) => p[1] === id).map((p) => `  children: "${p[0]}"\n`).join("");
  if (proto) {
    out += `instances {\n  id: "${id}"\n  prototype: "${proto}"\n${children}${v3("position", pos)}${v3("scale3", scale)}}\n`;
  } else {
    out += `embedded_instances {\n  id: "${id}"\n${children}  data: ""\n${v3("position", pos)}${v3("scale3", scale)}}\n`;
  }
}
out += "scale_along_z: 1\n";
fs.writeFileSync(path.join(__dirname, "..", "entities", "character", "character.collection"), out);
console.log("ok", parts.length, "parts");
