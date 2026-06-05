# StartTech Application

A full-stack Todo application with user authentication, built with React (frontend) and Go (backend), deployed on AWS with a fully automated CI/CD pipeline.

## Architecture

```
                    ┌─────────────┐
         Users ───► │  CloudFront │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │  S3 Bucket  │  ◄── React (Vite + TypeScript)
                    └─────────────┘

                    ┌─────────────┐
         API  ───► │     ALB     │
                   └──────┬──────┘
                          │
                   ┌──────▼──────┐
                   │  ASG / EC2  │  ◄── Go (Gin) in Docker
                   └──────┬──────┘
                          │
              ┌───────────┼───────────┐
       ┌──────▼─────┐     │    ┌──────▼──────┐
       │  MongoDB   │     │    │    Redis     │
       │   Atlas    │     │    │ ElastiCache  │
       └────────────┘     │    └─────────────┘
                          │
                   ┌──────▼──────┐
                   │  CloudWatch │
                   └─────────────┘
```

## Repository Structure

```
starttech-app/
├── .github/workflows/
│   ├── frontend-ci-cd.yml    # React build → S3 → CloudFront
│   └── backend-ci-cd.yml     # Go test → Docker → ECR → EC2
├── Client/                   # React frontend
│   ├── src/
│   │   ├── routes/           # TanStack Router pages
│   │   ├── components/       # Reusable UI components
│   │   ├── context/          # Auth context
│   │   ├── hooks/            # Custom hooks
│   │   ├── lib/              # API client
│   │   └── types/            # TypeScript types
│   ├── .env.example
│   └── package.json
├── Server/MuchToDo/          # Go backend
│   ├── cmd/api/main.go       # Entry point
│   ├── internal/
│   │   ├── auth/             # JWT token service
│   │   ├── cache/            # Redis cache service
│   │   ├── config/           # Environment config
│   │   ├── database/         # MongoDB connection
│   │   ├── handlers/         # HTTP handlers
│   │   ├── middleware/       # CORS, auth middleware
│   │   ├── models/           # Data models
│   │   └── routes/           # Route registration
│   ├── docs/                 # Swagger docs
│   └── .env.example
└── scripts/
    ├── deploy-frontend.sh
    ├── deploy-backend.sh
    ├── health-check.sh
    └── rollback.sh
```

## Prerequisites

- Node.js 20+
- Go 1.21+
- Docker
- AWS CLI configured
- MongoDB Atlas connection string
- Redis (local or ElastiCache)

## Local Development

### Backend

```bash
cd Server/MuchToDo
cp .env.example .env
# Fill in MONGO_URI, JWT_SECRET_KEY, and Redis settings in .env

# Run with Docker Compose (includes MongoDB + Redis)
docker compose up

# Or run directly
go run cmd/api/main.go
```

The API will be available at `http://localhost:8080`.

### Frontend

```bash
cd Client
cp .env.example .env
# Set VITE_API_BASE_URL=http://localhost:8080

npm install
npm run dev
```

The app will be available at `http://localhost:5173`.

## Environment Variables

### Backend (`Server/MuchToDo/.env`)

| Variable | Description | Required |
|---|---|---|
| `PORT` | Server port (default: 8080) | No |
| `MONGO_URI` | MongoDB Atlas connection string | Yes |
| `DB_NAME` | Database name (default: much_todo_db) | No |
| `JWT_SECRET_KEY` | Secret key for signing JWT tokens | Yes |
| `JWT_EXPIRATION_HOURS` | Token expiry in hours (default: 72) | No |
| `ALLOWED_ORIGINS` | Comma-separated CORS origins | Yes |
| `ENABLE_CACHE` | Enable Redis caching (true/false) | No |
| `REDIS_ADDR` | Redis address (e.g. localhost:6379) | If cache enabled |
| `LOG_LEVEL` | Log level: DEBUG, INFO, WARN, ERROR | No |
| `LOG_FORMAT` | Log format: json or text | No |

### Frontend (`Client/.env`)

| Variable | Description | Required |
|---|---|---|
| `VITE_API_BASE_URL` | Backend API base URL | Yes |

## API Endpoints

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/health` | No | Health check |
| GET | `/swagger/*` | No | API documentation |
| POST | `/auth/register` | No | Register user |
| POST | `/auth/login` | No | Login |
| POST | `/auth/logout` | No | Logout |
| GET | `/auth/username-check/:username` | No | Check username availability |
| GET | `/tasks` | Yes | List all tasks |
| POST | `/tasks` | Yes | Create task |
| GET | `/tasks/:id` | Yes | Get task by ID |
| PUT | `/tasks/:id` | Yes | Update task |
| DELETE | `/tasks/:id` | Yes | Delete task |
| GET | `/users/me` | Yes | Get current user |
| PUT | `/users/me` | Yes | Update profile |
| PUT | `/users/me/password` | Yes | Change password |
| DELETE | `/users/me` | Yes | Delete account |

Full interactive docs available at `/swagger/index.html` when the server is running.

## CI/CD Pipelines

Both pipelines trigger on push to `feature/full-stack` for their respective directories, and can also be triggered manually via `workflow_dispatch`.

### Frontend Pipeline

```
Install deps → Lint → Security audit → Build → Upload artifact
                                                      │
                                               Deploy to S3
                                               Invalidate CloudFront
```

### Backend Pipeline

```
Go tests → staticcheck → govulncheck
                │
          Docker build → Trivy image scan → Push to ECR
                                                  │
                                         ASG instance refresh
                                         Wait for completion
                                         Smoke test /health
                                         CloudWatch alarm setup
```

### Required GitHub Actions Secrets

| Secret | Used by | Description |
|---|---|---|
| `AWS_ACCESS_KEY_ID` | Both | AWS credentials |
| `AWS_SECRET_ACCESS_KEY` | Both | AWS credentials |
| `VITE_API_URL` | Frontend | API URL injected at build time |
| `S3_BUCKET_NAME` | Frontend | S3 bucket for static files |
| `CLOUDFRONT_DISTRIBUTION_ID` | Frontend | CloudFront distribution to invalidate |
| `ASG_NAME` | Backend | Auto Scaling Group name |
| `ALB_URL` | Backend | ALB DNS name for smoke tests |
| `ALB_ARN` | Backend | ALB ARN for CloudWatch alarm dimensions |

## Deployment Scripts

Manual deployment outside of CI/CD:

```bash
# Deploy frontend
./scripts/deploy-frontend.sh <s3-bucket-name> <cloudfront-distribution-id>

# Deploy backend
./scripts/deploy-backend.sh <asg-name> <ecr-registry> <image-tag>

# Health check
./scripts/health-check.sh

# Rollback
./scripts/rollback.sh
```

## Infrastructure

All infrastructure is managed in the companion repository [starttech-infra](https://github.com/fadart/starttech-infra), which provisions:

- VPC, subnets, NAT Gateways
- ALB + Target Group
- Auto Scaling Group (EC2)
- S3 + CloudFront distribution
- ElastiCache Redis cluster
- CloudWatch log groups and dashboard
- IAM roles and security groups
