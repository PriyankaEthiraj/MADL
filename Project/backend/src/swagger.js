import swaggerJSDoc from "swagger-jsdoc";

export const swaggerSpec = swaggerJSDoc({
  definition: {
    openapi: "3.0.0",
    info: {
      title: "Smart City Complaint API",
      version: "1.0.0",
      description: "AI-based complaint classification system using ML + Rule-based NLP"
    },
    servers: [
      {
        url: "http://localhost:4000"
      }
    ],
    tags: [
      { name: "System", description: "System health and metadata" },
      { name: "Classification", description: "Complaint classification endpoints" }
    ],
    paths: {
      "/": {
        get: {
          tags: ["System"],
          summary: "API root",
          description: "Returns basic API metadata and useful links.",
          responses: {
            200: {
              description: "Root metadata",
              content: {
                "application/json": {
                  schema: {
                    type: "object",
                    properties: {
                      message: { type: "string", example: "Smart City Backend API" },
                      health: { type: "string", example: "/health" },
                      docs: { type: "string", example: "/api-docs" }
                    }
                  }
                }
              }
            }
          }
        }
      },
      "/health": {
        get: {
          tags: ["System"],
          summary: "Health check",
          responses: {
            200: {
              description: "Service is healthy",
              content: {
                "application/json": {
                  schema: {
                    type: "object",
                    properties: {
                      status: { type: "string", example: "ok" }
                    }
                  }
                }
              }
            }
          }
        }
      },
      "/api/complaint/classify": {
        get: {
          tags: ["Classification"],
          summary: "Classify complaint from query string",
          parameters: [
            {
              name: "description",
              in: "query",
              required: true,
              schema: { type: "string" },
              description: "Complaint description text"
            }
          ],
          responses: {
            200: {
              description: "Classification result",
              content: {
                "application/json": {
                  schema: {
                    $ref: "#/components/schemas/ClassifySuccessResponse"
                  }
                }
              }
            },
            400: {
              description: "Missing or invalid description"
            }
          }
        },
        post: {
          tags: ["Classification"],
          summary: "Classify complaint from request body",
          requestBody: {
            required: true,
            content: {
              "application/json": {
                schema: {
                  type: "object",
                  required: ["description"],
                  properties: {
                    description: {
                      type: "string",
                      example: "There is a large pothole near the school gate"
                    }
                  }
                }
              }
            }
          },
          responses: {
            200: {
              description: "Classification result",
              content: {
                "application/json": {
                  schema: {
                    $ref: "#/components/schemas/ClassifySuccessResponse"
                  }
                }
              }
            },
            400: {
              description: "Validation error"
            },
            500: {
              description: "Server error"
            }
          }
        }
      }
    },
    components: {
      schemas: {
        ClassifySuccessResponse: {
          type: "object",
          properties: {
            success: { type: "boolean", example: true },
            description: { type: "string" },
            department: { type: "string", example: "Road" },
            confidence: { type: "number", format: "float", example: 0.9 },
            source: { type: "string", example: "ML" },
            system: {
              type: "string",
              example: "Hybrid AI (ML + Rule-based fallback)"
            }
          }
        }
      }
    }
  },
  apis: ["./app.js", "./server.js"]
});