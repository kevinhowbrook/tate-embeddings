# Feature Requirements - TSE-108

**Feature:** Embedding computation service

As a developer, I want a standalone FastAPI app to compute text and image embeddings, so that the web app can offload expensive ML operations.

## Scenarios

### Scenario: FastAPI app initializes with embedding model

- Given the embedding model from TSE-108 is available (OpenClip)
- When the FastAPI app starts up with 4 gunicorn threads
- Then the model should be loaded into memory
- And the app should be ready to accept requests

### Scenario: Compute text embedding via API

- Given the FastAPI app is running
- And I have a valid authentication bearer token
- When I POST to `/embed-text` with `{"query": "landscape painting"}`
- And I include the bearer token in the Authorization header
- Then I should receive a 200 response
- And the response should contain `{"embedding": [array of numbers]}`

### Scenario: Compute image embedding via API

- Given the FastAPI app is running
- And I have a valid authentication bearer token
- When I POST to `/embed-image` with `{"url": "https://www.tate.org.uk/static/images/default.jpg"}`
- And I include the bearer token in the Authorization header
- Then I should receive a 200 response
- And the response should contain `{"embedding": [array of numbers]}`

### Scenario: Reject unauthenticated requests

- Given the FastAPI app is running
- When I POST to `/embed-text` or `/embed-image` without an authentication bearer token
- Then I should receive a 403 response

### Scenario: Test coverage exists

- Given the codebase includes the embedding service
- Then tests should exist for both `/embed-text` and `/embed-image` endpoints
- And tests should verify authentication is enforced
- And tests should use `https://www.tate.org.uk/static/images/default.jpg` for image tests

## Key Details

- Create a FastAPI app with a Docker build that runs the app with 4 concurrent gunicorn threads
- The app should load the OpenCLIP model or a model chosen in [TSE-108](https://github.com/TateMedia/tate-embeddings) when it starts up
- The app should expose an endpoint `POST /embed-text` that accepts a JSON body like `{"query": "[...]"}` and returns a JSON body like `{"embedding": [vector of numbers]}`
- The app should expose an endpoint `POST /embed-image` that accepts a JSON body like `{"url": "[...]"}` and returns a JSON body like `{"embedding": [vector of numbers]}`
- The app should reject requests using a shared secret configured in an environment variable
- The app should have tests for the endpoint responses and the authentication; for image tests we can use the `https://www.tate.org.uk/static/images/default.jpg` URL
- Tate will deploy the app on Railway and provide the public URL
- Locally, this will need to run in a separate docker container with a local endpoint that can be requested
