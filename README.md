# Online Banking System — Frontend

A React single-page app for a full-stack online banking platform — accounts, transactions, transfers, admin/bank/customer role management. The application itself is a pre-built React app I cloned as the frontend for this project; what I actually built is everything around it: containerizing it correctly, getting it deployed on AWS EKS, wiring it into a real domain with HTTPS, and setting up the CI/CD pipeline that ships it.

**Note:** the live infrastructure for this project has since been torn down (to avoid ongoing AWS costs after the portfolio demo period). The full deployment — domain, HTTPS, EKS, ArgoCD — was live and working end-to-end; see the docs linked below for the full build and screenshots.

This repo is just the UI. The full platform — infrastructure, backend, deployment pipelines, and observability — is split across a few repos, linked at the bottom.



## What I actually did here

The React app itself came pre-built. My work on this repo was:
- Writing the **Dockerfile** — multi-stage build, and fixing a base-image/dependency conflict that broke the production build
- Writing the **CI/CD pipeline** (GitHub Actions) — build, push to ECR, and sync into my GitOps manifest repo
- Getting the image building correctly for **ARM64** (my EKS nodes run on Graviton, GitHub's runners don't build for that by default)
- Fixing **CORS and hardcoded API domain issues** in the app's source so it could actually talk to my backend once deployed
- Adding a custom **Nginx config** so client-side routing (React Router) doesn't 404 on page refresh

Full breakdown of every issue I hit and how I fixed each one is in the docs linked below.

## Tech stack

**The app itself (pre-existing):**
- React (Create React App), React Router, Axios/fetch

**What I set up around it:**
- Docker (multi-stage build, ARM64/Graviton target)
- Nginx as the production static file server
- GitHub Actions for CI/CD
- ArgoCD for GitOps deployment to Kubernetes

## App features

- Role-based views for Admin, Bank, and Customer users
- Bank and bank account management (create, search, fetch, update status)
- Transactions: deposits, withdrawals, transfers, transaction history with time-range filtering
- Bank statement download
- User registration and login

## Architecture 
![Architecture](Architecture.drawio.svg)


This app is built into a Docker image, pushed to Amazon ECR, and deployed to an EKS cluster behind an ALB Ingress with a real ACM-issued HTTPS certificate. Every push to `main` triggers a pipeline that builds the image and updates my GitOps manifest repo, which ArgoCD then syncs to the cluster automatically — I never run `kubectl apply` by hand.


GitHub push → Build (ARM64 Docker image) → Push to ECR
           → Update Kubernetes manifest repo → ArgoCD syncs → Live on EKS


## Running it locally

```bash
git clone https://github.com/Kryptcloud/bank_app_frontend.git
cd bank_app_frontend
npm ci
npm start
```

Runs on `http://localhost:3000` by default. You'll need the backend running (or pointed at a live instance) for API calls to actually resolve — see the backend repo for setup.

## Building the Docker image locally

```bash
docker build -t bank-frontend .
docker run -p 8080:80 bank-frontend
```

## CI/CD

Every push to `main` or `dev-branch` builds and pushes an image. Pushes to `main` additionally sync the new image tag into my Kubernetes manifest repo, which ArgoCD picks up automatically. Full pipeline breakdown, including the ARM64 build issues I ran into and fixed, is in the CI/CD doc linked below.

## Related repos & docs

- https://github.com/Kryptcloud/Bank-Project-Terraform.git — infrastructure (VPC, EKS, RDS, ALB, IAM/IRSA)
- https://github.com/Kryptcloud/Bank_kubernetes-manifest.git — Kubernetes manifests, Ingress, monitoring stack
- https://github.com/Kryptcloud/bank_app_backend.git — Spring Boot API
- Full write-ups on my build process, architecture decisions, and every bug I hit along the way: https://app.notion.com/p/Banking-Application-Platform-on-AWS-EKS-3781485a639c80569a27e2c51c172caa?source=copy_link
