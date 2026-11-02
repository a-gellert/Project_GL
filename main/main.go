components {
  id: "main"
  component: "/main/main.script"
}
embedded_components {
  id: "camp_proxy"
  type: "collectionproxy"
  data: "collection: \"/scenes/camp/camp.collection\"\n"
}
embedded_components {
  id: "arena_proxy"
  type: "collectionproxy"
  data: "collection: \"/scenes/arena/arena.collection\"\n"
}
