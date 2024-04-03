create extension pg_jsonschema with schema extensions;



alter table canvas_objects
add constraint object_schema_check 
    check(
    extensions.jsonb_matches_schema(
      '{
        "type": "object",
        "properties": {
            "object_type": {
              "enum": ["circle", "rectangle", "polygon"]
            },
            "id": {
              "type": "string"
            },
            "color": {
              "type": "integer"
            },
            "image_path": {
              "type": "string"
            },
            "center": {
                "type": "object",
                "properties": {
                    "x": {
                        "type": "number"
                    },
                    "y": {
                        "type": "number"
                    }
                },
                "required": ["x", "y"]
            },
            "radius": {
             "type": "number"
            },
            "top_left": {
                "type": "object",
                "properties": {
                    "x": {
                        "type": "number"
                    },
                    "y": {
                        "type": "number"
                    }
                },
                "required": ["x", "y"]
            },
            "bottom_right": {
                "type": "object",
                "properties": {
                    "x": {
                        "type": "number"
                    },
                    "y": {
                        "type": "number"
                    }
                },
                "required": ["x", "y"]
            },
            "points": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "x": {
                            "type": "number"
                        },
                        "y": {
                            "type": "number"
                        }
                    },
                    "required": ["x", "y"]
                }
            }
        },
        "required": ["object_type", "id", "color"],
        "oneOf": [
          {"required": ["center", "radius"]},
          {"required": ["top_left", "bottom_right"]},
          {"required": ["points"]}
        ],
        "additionalProperties": false
      }',
      "object"
    )
);
