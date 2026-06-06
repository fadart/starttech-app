# StartTech Application

A full-stack Todo app with user authentication. The frontend is built with React and the backend is a Go API. Both are deployed on AWS with automated CI/CD pipelines.

## How it works

```
Users → CloudFront → S3 (React frontend)
Users → CloudFront → ALB → EC2 (Go backend in Docker)
                              ↓              ↓
                         MongoDB Atlas   ElastiCache Redis
                              ↓
                         CloudWatch Logs
```

All traffic goes through CloudFront. API calls are proxied through CloudFront to the ALB — this avoids mixed content issues since everything stays on HTTPS.

## Repo structure

```
starttech-app/
├── .github/workflows/
│   ├── frontend-ci-cd.yml
│   └── backend-ci-cd.yml
├── much-to-do/
│   ├── Client/              # React frontend (Vite + TypeScript)
│   └── Server/MuchToDo/     # Go backend (Gin framework)
├── scripts/
│   ├── deploy-frontend.sh
│   ├── deploy-backend.sh
│   ├── health-check.sh
│   └── rollback.sh
└── README.md
```

## Running locally

### Backend

```bash
cd much-to-do/Server/MuchToDo
cp .env.example .env
# fill in MONGO_URI and JWT_SECRET_KEY

docker compose up  # starts MongoDB and Redis alongside the app
```

API runs on `http://localhost:8080`. Swagger docs at `http://localhost:8080/swagger/index.html`.

### Frontend

```bash
cd much-to-do/Client
cp .env.example .env
# set VITE_API_BASE_URL=http://localhost:8080

npm install
npm run dev
```

App runs on `http://localhost:5173`.

## Environment variables

### Backend

| Variable | Description |
|----------|-------------|
| `MONGO_URI` | MongoDB Atlas connection string |
| `DB_NAME` | Database name (default: `much_todo_db`) |
| `JWT_SECRET_KEY` | Secret for signing JWT tokens |
| `REDIS_ADDR` | Redis address (e.g. `localhost:6379`) |
| `ENABLE_CACHE` | Set to `true` to enable Redis caching |
| `ALLOWED_ORIGINS` | Comma-separated CORS allowed origins |
| `PORT` | Server port (default: `8080`) |

### Frontend

| Variable | Description |
|----------|-------------|
| `VITE_API_BASE_URL` | Backend API base URL |

## API endpoints

| Method | Path | Auth required |
|--------|------|--------------|
| GET | `/health` | No |
| POST | `/auth/register` | No |
| POST | `/auth/login` | No |
| POST | `/auth/logout` | No |
| GET | `/tasks` | Yes |
| POST | `/tasks` | Yes |
| PUT | `/tasks/:id` | Yes |
| DELETE | `/tasks/:id` | Yes |
| GET | `/users/me` | Yes |
| PUT | `/users/me` | Yes |
| PUT | `/users/me/password` | Yes |

## CI/CD pipelines

### Frontend pipeline
Triggers on push to `feature/full-stack` when files in `Client/` change.

1. Install dependencies
2. Lint (ESLint)
3. Security audit (`npm audit --audit-level=high`)
4. Build production bundle
5. Sync to S3
6. Invalidate CloudFront cache

### Backend pipeline
Triggers on push to `feature/full-stack` when files in `Server/` change.

1. Run unit tests
2. Static analysis (staticcheck)
3. Vulnerability scan (govulncheck)
4. Build Docker image
5. Scan image (Trivy)
6. Push to ECR
7. Rolling deploy via ASG instance refresh
8. Smoke test against `/health`

## GitHub Actions secrets

| Secret | Used by |
|--------|---------|
| `AWS_ACCESS_KEY_ID` | Both |
| `AWS_SECRET_ACCESS_KEY` | Both |
| `VITE_API_BASE_URL` | Frontend |
| `S3_BUCKET_NAME` | Frontend |
| `CLOUDFRONT_DISTRIBUTION_ID` | Frontend |
| `ASG_NAME` | Backend |
| `ALB_URL` | Backend |
| `ALB_ARN` | Backend |

## Infrastructure

All AWS infrastructure is in the companion repo [starttech-infra](https://github.com/fadart/starttech-infra).
