components {
  id: "camp"
  component: "/scenes/camp/camp.script"
}
embedded_components {
  id: "character_factory"
  type: "collectionfactory"
  data: "prototype: \"/entities/character/character.collection\"\n"
}
embedded_components {
  id: "cube_factory"
  type: "factory"
  data: "prototype: \"/assets/models/cube_part.go\"\n"
}
embedded_components {
  id: "sphere_factory"
  type: "factory"
  data: "prototype: \"/assets/models/sphere_part.go\"\n"
}
