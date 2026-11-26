return {
  version = "1.1",
  luaversion = "5.1",
  orientation = "orthogonal",
  width = 16,
  height = 16,
  tilewidth = 16,
  tileheight = 16,
  properties = {},
  tilesets = {
    {
      name = "tiles",
      firstgid = 1,
      tilewidth = 64,
      tileheight = 64,
      spacing = 0,
      margin = 0,
      image = "../../../../tools/tiled/dont_starve/tiles.png",
      imagewidth = 512,
      imageheight = 384,
      properties = {},
      tiles = {}
    }
  },
  layers = {
    {
      type = "tilelayer",
      name = "BG_TILES",
      x = 0,
      y = 0,
      width = 36,
      height = 36,
      visible = true,
      opacity = 1,
      properties = {},
      encoding = "lua",
      data = {
        0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,
        0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,
        0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,
        1, 0, 0, 0,  1, 0, 0, 0,  1, 0, 0, 0,  1, 0, 0, 0,  2, 0, 0, 0,  3, 0, 0, 0,  3, 0, 0, 0,  1, 0, 0, 0,  1, 0, 0, 0,
        0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,
        0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,
        0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,
        1, 0, 0, 0,  1, 0, 0, 0,  1, 0, 0, 0,  3, 0, 0, 0,  3, 0, 0, 0,  3, 0, 0, 0,  1, 0, 0, 0,  1, 0, 0, 0,  1, 0, 0, 0,  
        0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,
        0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,
        0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,
        1, 0, 0, 0,  1, 0, 0, 0,  1, 0, 0, 0,  1, 0, 0, 0,  3, 0, 0, 0,  3, 0, 0, 0,  3, 0, 0, 0,  1, 0, 0, 0,  3, 0, 0, 0,
        0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,
        0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,
        0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,
        1, 0, 0, 0,  1, 0, 0, 0,  1, 0, 0, 0,  1, 0, 0, 0,  1, 0, 0, 0,  1, 0, 0, 0,  3, 0, 0, 0,  3, 0, 0, 0,  1, 0, 0, 0,
        0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,
        0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,
        0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,
        1, 0, 0, 0,  3, 0, 0, 0,  3, 0, 0, 0,  1, 0, 0, 0,  1, 0, 0, 0,  1, 0, 0, 0,  3, 0, 0, 0,  3, 0, 0, 0,  1, 0, 0, 0,
        0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,
        0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,
        0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,
        3, 0, 0, 0,  3, 0, 0, 0,  3, 0, 0, 0,  1, 0, 0, 0,  2, 0, 0, 0,  2, 0, 0, 0,  2, 0, 0, 0,  3, 0, 0, 0,  3, 0, 0, 0,  
        0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,
        0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,
        0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,
        3, 0, 0, 0,  3, 0, 0, 0,  1, 0, 0, 0,  3, 0, 0, 0,  2, 0, 0, 0,  2, 0, 0, 0,  2, 0, 0, 0,  3, 0, 0, 0,  3, 0, 0, 0,
        0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,
        0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,
        0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,
        3, 0, 0, 0,  1, 0, 0, 0,  1, 0, 0, 0,  3, 0, 0, 0,  1, 0, 0, 0,  3, 0, 0, 0,  2, 0, 0, 0,  2, 0, 0, 0,  3, 0, 0, 0,
        0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,
        0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,
        0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,
        3, 0, 0, 0,  3, 0, 0, 0,  3, 0, 0, 0,  1, 0, 0, 0,  1, 0, 0, 0,  1, 0, 0, 0,  3, 0, 0, 0,  2, 0, 0, 0,  3, 0, 0, 0,
      }
    },
    {
      type = "objectgroup",
      name = "FG_OBJECTS",
      visible = true,
      opacity = 1,
      properties = {},
      objects = {
        {
          name = "",
          type = "um_moontear_core_base",
          shape = "rectangle",
          x = 128, -- This was in the middle of a 4 x 4, so it's 2 tiles right and up
          y = 128,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "um_moontear_stalactite",
          shape = "rectangle",
          x = 192,
          y = 128,
          width = 0,
          height = 0,
          visible = true,
          properties = {
            ["data.variant"] = "1",
          }
        },
        {
          name = "",
          type = "um_moontear_stalactite",
          shape = "rectangle",
          x = 128,
          y = 192,
          width = 0,
          height = 0,
          visible = true,
          properties = {
            ["data.variant"] = "2",
          }
        },
        {
          name = "",
          type = "um_moontear_stalactite",
          shape = "rectangle",
          x = 64,
          y = 128,
          width = 0,
          height = 0,
          visible = true,
          properties = {
            ["data.variant"] = "3",
          }
        },
        {
          name = "",
          type = "um_moontear_stalactite",
          shape = "rectangle",
          x = 128,
          y = 64,
          width = 0,
          height = 0,
          visible = true,
          properties = {
            ["data.variant"] = "4",
          }
        },
        {
          name = "",
          type = "um_moontear_stalactite",
          shape = "rectangle",
          x = 0,
          y = 0,
          width = 0,
          height = 0,
          visible = true,
          properties = {
            ["data.variant"] = "5",
          }
        },
        {
          name = "",
          type = "um_moontear_stalactite",
          shape = "rectangle",
          x = 256,
          y = 256,
          width = 0,
          height = 0,
          visible = true,
          properties = {
            ["data.variant"] = "1",
          }
        },
        {
          name = "",
          type = "um_moontear_stalactite",
          shape = "rectangle",
          x = 256,
          y = 0,
          width = 0,
          height = 0,
          visible = true,
          properties = {
            ["data.variant"] = "2",
          }
        },
        {
          name = "",
          type = "um_moontear_stalactite",
          shape = "rectangle",
          x = 0,
          y = 256,
          width = 0,
          height = 0,
          visible = true,
          properties = {
            ["data.variant"] = "3",
          }
        },
        {
          name = "",
          type = "um_moontear_stalactite",
          shape = "rectangle",
          x = -64,
          y = 128,
          width = 0,
          height = 0,
          visible = true,
          properties = {
            ["data.variant"] = "10",
          }
        },
        {
          name = "",
          type = "um_moontear_stalactite",
          shape = "rectangle",
          x = 128,
          y = -64,
          width = 0,
          height = 0,
          visible = true,
          properties = {
            ["data.variant"] = "6",
          }
        },
        {
          name = "",
          type = "um_moontear_stalactite",
          shape = "rectangle",
          x = 320,
          y = 128,
          width = 0,
          height = 0,
          visible = true,
          properties = {
            ["data.variant"] = "7",
          }
        },
        {
          name = "",
          type = "um_moontear_stalactite",
          shape = "rectangle",
          x = 128,
          y = 320,
          width = 0,
          height = 0,
          visible = true,
          properties = {
            ["data.variant"] = "8",
          }
        },
        {
          name = "",
          type = "um_moontear_rock",
          shape = "rectangle",
          x = -64,
          y = -64,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "um_moontear_rock",
          shape = "rectangle",
          x = 320,
          y = 320,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "um_moontear_rock",
          shape = "rectangle",
          x = -64,
          y = 320,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "um_moontear_rock",
          shape = "rectangle",
          x = 320,
          y = -64,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "um_reeds_lunar",
          shape = "rectangle",
          x = 0, -- This was in the middle of a 4 x 4, so it's 2 tiles right and up
          y = 0,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "um_reeds_lunar",
          shape = "rectangle",
          x = -20, -- This was in the middle of a 4 x 4, so it's 2 tiles right and up
          y = 56,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "um_reeds_lunar",
          shape = "rectangle",
          x = 46, -- This was in the middle of a 4 x 4, so it's 2 tiles right and up
          y = 36,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "moonglass_rock",
          shape = "rectangle",
          x = -10, -- This was in the middle of a 4 x 4, so it's 2 tiles right and up
          y = 136,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "lightflier_flower",
          shape = "rectangle",
          x = 146, -- This was in the middle of a 4 x 4, so it's 2 tiles right and up
          y = -10,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "moonglass_rock",
          shape = "rectangle",
          x = 236, -- This was in the middle of a 4 x 4, so it's 2 tiles right and up
          y = 5,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "um_reeds_moon",
          shape = "rectangle",
          x = 220, -- This was in the middle of a 4 x 4, so it's 2 tiles right and up
          y = 36,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "moonglass_rock",
          shape = "rectangle",
          x = 270, -- This was in the middle of a 4 x 4, so it's 2 tiles right and up
          y = 120,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "lightflier_flower",
          shape = "rectangle",
          x = 20, -- This was in the middle of a 4 x 4, so it's 2 tiles right and up
          y = 266,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "sapling_moon",
          shape = "rectangle",
          x = -60, -- This was in the middle of a 4 x 4, so it's 2 tiles right and up
          y = 240,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },

        {
          name = "",
          type = "moon_fissure",
          shape = "rectangle",
          x = -30, -- This was in the middle of a 4 x 4, so it's 2 tiles right and up
          y = 150,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },        
        {
          name = "",
          type = "moon_fissure",
          shape = "rectangle",
          x = 320, -- This was in the middle of a 4 x 4, so it's 2 tiles right and up
          y = 276,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "rock_moon",
          shape = "rectangle",
          x = 236, -- This was in the middle of a 4 x 4, so it's 2 tiles right and up
          y = 276,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "rock_moon",
          shape = "rectangle",
          x = 266, -- This was in the middle of a 4 x 4, so it's 2 tiles right and up
          y = 76,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "rock_moon",
          shape = "rectangle",
          x = 126, -- This was in the middle of a 4 x 4, so it's 2 tiles right and up
          y = 266,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "rock_moon",
          shape = "rectangle",
          x = 110, -- This was in the middle of a 4 x 4, so it's 2 tiles right and up
          y = 320,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "moonglass_rock",
          shape = "rectangle",
          x = 300, -- This was in the middle of a 4 x 4, so it's 2 tiles right and up
          y = 146,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },

        {
          name = "",
          type = "um_tentacle_moon",
          shape = "rectangle",
          x = 60, -- This was in the middle of a 4 x 4, so it's 2 tiles right and up
          y = 30,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "um_tentacle_moon",
          shape = "rectangle",
          x = 216, -- This was in the middle of a 4 x 4, so it's 2 tiles right and up
          y = 80,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
        {
          name = "",
          type = "um_tentacle_moon",
          shape = "rectangle",
          x = 60, -- This was in the middle of a 4 x 4, so it's 2 tiles right and up
          y = 270,
          width = 0,
          height = 0,
          visible = true,
          properties = {}
        },
      }
    }
  }
}
