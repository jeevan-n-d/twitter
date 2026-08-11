# Twitter DevSecOps + Kubernetes + AWS Cloud Project

## Complete Project Architecture — From Source Code to Production Access and Monitoring

This README documents the whole project, not just monitoring.

The purpose is to let you understand the complete architecture well enough that, after reading it once, you can explain the project in an interview and rebuild the major pieces without depending on prior context.

## Table of Contents

- [1. Project in One Sentence](#1-project-in-one-sentence)
- [2. Project Goals](#2-project-goals)
- [3. Application](#3-application)
- [4. Application Architecture](#4-application-architecture)
- [5. Why Use RDS?](#5-why-use-rds)
- [6. Multi-Account Architecture](#6-multi-account-architecture)
- [7. AWS Infrastructure](#7-aws-infrastructure)
- [8. Terraform](#8-terraform)
- [9. Terraform Project Structure](#9-terraform-project-structure)
- [10. Terraform Workflow](#10-terraform-workflow)
- [11. VPC](#11-vpc)
- [12. Subnets](#12-subnets)
- [13. Internet Gateway](#13-internet-gateway)
- [14. Route Tables](#14-route-tables)
- [15. Security Groups](#15-security-groups)
- [16. EKS](#16-eks)
- [17. EKS Worker Nodes](#17-eks-worker-nodes)
- [18. EKS Core Components](#18-eks-core-components)
- [19. Kubernetes Namespace](#19-kubernetes-namespace)
- [20. Application Deployment](#20-application-deployment)
- [21. Kubernetes Pods](#21-kubernetes-pods)
- [22. Kubernetes Service](#22-kubernetes-service)
- [23. Application Service](#23-application-service)
- [24. Service Types](#24-service-types)
- [25. The Load Balancer Used in the Project](#25-the-load-balancer-used-in-the-project)
- [26. Why Classic Load Balancer?](#26-important-interview-question--why-classic-load-balancer)
- [27. DNS — Route 53](#27-dns--route-53)
- [28. Route 53 Record](#28-route-53-record)
- [29. DNS Verification](#29-dns-verification)
- [30. HTTPS / ACM](#30-https--acm)
- [31. Certificate vs DNS](#31-certificate-vs-dns)
- [32. CI/CD Pipeline](#32-cicd-pipeline)
- [33. Jenkins](#33-jenkins)
- [34. Jenkins Pipeline Stages](#34-jenkins-pipeline-stages)
- [35. Stage 1 — Git Checkout](#35-stage-1--git-checkout)
- [36. Stage 2 — Maven Compile](#36-stage-2--maven-compile)
- [37. Stage 3 — Tests](#37-stage-3--tests)
- [38. Stage 4 — Trivy Filesystem Scan](#38-stage-4--trivy-filesystem-scan)
- [39. Stage 5 — SonarQube](#39-stage-5--sonarqube)
- [40. Stage 6 — Nexus](#40-stage-6--nexus)
- [41. Nexus vs ECR](#41-nexus-vs-ecr)
- [42. Stage 7 — Docker Build](#42-stage-7--docker-build)
- [43. Docker Multi-Stage Build](#43-docker-multi-stage-build)
- [44. Stage 8 — Trivy Image Scan](#44-stage-8--trivy-image-scan)
- [45. Stage 9 — Amazon ECR](#45-stage-9--amazon-ecr)
- [46. ECR to EKS](#46-ecr-to-eks)
- [47. Kubernetes Deployment Image](#47-kubernetes-deployment-image)
- [48. Application to Database](#48-application-to-database)
- [49. Kubernetes Secrets](#49-kubernetes-secrets)
- [50. Spring Boot Actuator](#50-spring-boot-actuator)
- [51. Kubernetes Health Checks](#51-kubernetes-health-checks)
- [52. End-to-End User Request Flow](#52-end-to-end-user-request-flow)
- [53. Complete CI/CD + Runtime Architecture](#53-complete-cicd--runtime-architecture)
- [54. Full Project Architecture Diagram](#54-full-project-architecture-diagram)
- [55. Complete Technology Map](#55-complete-technology-map)
- [56. What Happens When a Developer Pushes Code?](#56-what-happens-when-a-developer-pushes-code)
- [57. What Happens During a Failed Pipeline?](#57-what-happens-during-a-failed-pipeline)
- [58. DevSecOps Shift-Left Concept](#58-devsecops-shift-left-concept)
- [59. Docker vs Kubernetes](#59-docker-vs-kubernetes)
- [60. Kubernetes Self-Healing](#60-kubernetes-self-healing)
- [61. Kubernetes Scaling](#61-kubernetes-scaling)
- [62. Rolling Updates](#62-rolling-updates)
- [63. Kubernetes Service Discovery](#63-kubernetes-service-discovery)
- [64. Application Persistence](#64-application-persistence)
- [65. Monitoring Architecture](#65-monitoring-architecture)
- [66. Metrics Server vs Prometheus](#66-metrics-server-vs-prometheus)
- [67. Prometheus Verification](#67-prometheus-verification)
- [68. Grafana Verification](#68-grafana-verification)
- [69. Port Forwarding — Final Understanding](#69-port-forwarding--final-understanding)
- [70. Final Production-Style Architecture](#70-final-production-style-architecture)
- [71. Lab Architecture vs Production Architecture](#71-lab-architecture-vs-production-architecture)
- [72. Why the Project Is Strong for DevOps Interviews](#72-why-the-project-is-strong-for-devops-interviews)
- [73. 60-Second Interview Answer](#73-60-second-interview-answer)
- [74. 2-Minute Architecture Explanation](#74-2-minute-architecture-explanation)
- [75–89. Common Interview Questions](#75-89-common-interview-questions)
- [90. Important Commands for the Entire Project](#90-important-commands-for-the-entire-project)
- [91. Terraform Commands](#91-terraform-commands)
- [92. Docker Commands](#92-docker-commands)
- [93. Jenkins Commands / Pipeline Concepts](#93-jenkins-commands--pipeline-concepts)
- [94. Kubernetes Commands](#94-kubernetes-commands)
- [95. Project Build Order](#95-project-build-order)
- [96. Final Project Checklist](#96-final-project-checklist)
- [97. The Project in One Picture](#97-the-project-in-one-picture)
- [98. What You Should Be Able to Do After Reading This](#98-what-you-should-be-able-to-do-after-reading-this)
- [99. Final Interview Mental Model](#99-final-interview-mental-model)
- [100. Final 30-Second Memory Trick](#100-final-30-second-memory-trick)
- [101. Final Status](#101-final-status)

---

## 1. Project in One Sentence

This project is a Spring Boot Twitter-style application deployed on Kubernetes/EKS with a complete DevSecOps pipeline, AWS infrastructure, external database, DNS/TLS, and monitoring.

The high-level flow is:

```
Developer
   |
   v
GitHub
   |
   v
Jenkins CI/CD
   |
   +--> Maven Compile
   +--> Unit Tests
   +--> Trivy Filesystem Scan
   +--> SonarQube Code Analysis
   +--> Nexus Artifact Repository
   +--> Docker Build
   +--> Trivy Image Scan
   +--> Amazon ECR
   |
   v
Amazon EKS
   |
   v
Kubernetes Deployment
   |
   v
Application Pods
   |
   +--------------------+
   |                    |
   v                    v
Service              RDS/MySQL
   |
   v
AWS Load Balancer
   |
   v
DNS / Route 53
   |
   v
User
```

Monitoring is connected to the Kubernetes cluster:

```
EKS
 |
 +--> Node Exporter
 +--> kube-state-metrics
 +--> kubelet / Kubernetes metrics
 |
 v
Prometheus
 |
 v
Grafana
 |
 v
Monitoring Dashboards
```

## 2. Project Goals

The project was built to demonstrate the following real-world DevOps skills:

- Linux
- AWS
- Terraform
- Docker
- Kubernetes
- Jenkins
- CI/CD
- DevSecOps
- Maven
- SonarQube
- Trivy
- Nexus
- Amazon ECR
- RDS
- Networking
- Load Balancing
- DNS
- TLS/ACM
- Prometheus
- Grafana

The goal is not simply to deploy an application. The goal is to demonstrate the complete lifecycle:

```
Code
 ↓
Build
 ↓
Test
 ↓
Security Scan
 ↓
Code Quality
 ↓
Artifact
 ↓
Container
 ↓
Image Security Scan
 ↓
Container Registry
 ↓
Kubernetes
 ↓
AWS Infrastructure
 ↓
Application Access
 ↓
DNS + HTTPS
 ↓
Monitoring
```

## 3. Application

### Application Type

The application is a Spring Boot 3.3.2 application.

Main technologies:

- Java 17
- Spring Boot 3.3.2
- Maven
- Spring Security
- Spring Data JPA
- Thymeleaf
- MySQL
- Spring Boot Actuator
- JaCoCo

The application is packaged using Maven, containerized with Docker, and the container is then deployed into Kubernetes.

## 4. Application Architecture

The logical application flow is:

```
User
 |
 v
Load Balancer
 |
 v
Kubernetes Service
 |
 v
Application Pods
 |
 v
Spring Boot Application
 |
 v
MySQL / RDS
```

The Kubernetes application layer contains:

- Deployment
- Service
- Config / Environment
- Secrets
- Pods

The database is kept outside the application container. This is important. Do NOT put the database inside the same application container.

Correct:

```
App Pod
   |
   v
External RDS/MySQL
```

## 5. Why Use RDS?

Amazon RDS provides a managed database service.

Instead of running MySQL manually inside a Kubernetes pod:

```
Kubernetes
   |
   +--> MySQL Pod
```

the project uses:

```
EKS Application
      |
      v
Amazon RDS
      |
      v
MySQL
```

Advantages:

- managed database
- backups
- easier maintenance
- persistence outside application pods
- database is independent from application scaling
- better production architecture

## 6. Multi-Account Architecture

The project was worked with three AWS accounts.

The practical separation used was:

```
ACCOUNT 1
 |
 +--> RDS
 +--> EC2 used for administration / supporting work


ACCOUNT 2
 |
 +--> Main Terraform-managed AWS infrastructure
 +--> EKS
 +--> Kubernetes-related infrastructure
 +--> Certificate / ACM used for HTTPS


ACCOUNT 3
 |
 +--> Route 53 DNS
```

Conceptually:

```
Account 3
Route 53
   |
   | DNS
   v
Account 2
EKS / Load Balancer / Certificate
   |
   v
Application
   |
   v
Account 1
RDS
```

Important: the exact cross-account permissions and DNS delegation depend on how the hosted zones/accounts were configured.

For the interview, explain the separation clearly:

> "I separated infrastructure across AWS accounts, with the application infrastructure in one account, the database/supporting EC2 resources in another, and Route 53 DNS in a separate account."

## 7. AWS Infrastructure

The infrastructure was managed using Terraform.

The important AWS components are:

- VPC
- Subnets
- Internet Gateway
- Route Tables
- Security Groups
- IAM
- EKS
- EC2 Worker Nodes
- RDS
- Load Balancer
- ACM
- Route 53
- ECR

## 8. Terraform

Terraform is used as Infrastructure as Code.

Instead of manually creating infrastructure from the AWS console:

```
Terraform
    |
    v
AWS resources
```

Terraform describes the desired infrastructure.

Basic workflow:

```bash
terraform init
terraform plan
terraform apply
```

## 9. Terraform Project Structure

A typical structure used for the infrastructure is:

```
terraform/
├── main.tf
├── providers.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
├── vpc.tf
├── eks.tf
├── iam.tf
├── security-groups.tf
├── rds.tf
└── ecr.tf
```

If the project is split into modules:

```
terraform/
├── main.tf
├── providers.tf
├── variables.tf
├── outputs.tf
└── modules/
    ├── vpc/
    ├── eks/
    ├── iam/
    ├── rds/
    ├── ecr/
    └── security-groups/
```

The exact filenames can change; the architecture is what matters.

## 10. Terraform Workflow

Whenever infrastructure is changed:

```bash
terraform init
```

Initializes providers/modules/backend.

```bash
terraform validate
```

Checks configuration syntax.

```bash
terraform plan
```

Shows what Terraform intends to change.

```bash
terraform apply
```

Creates/updates resources.

## 11. VPC

The Kubernetes infrastructure runs inside an AWS VPC.

Conceptually:

```
VPC
 |
 +--> Subnet A
 |
 +--> Subnet B
```

The VPC provides the private network boundary for EKS, EC2, RDS, and Load Balancers.

## 12. Subnets

Subnets divide the VPC IP range.

The project uses multiple subnets so that Kubernetes nodes and AWS services can operate across availability zones.

General architecture:

```
VPC
 |
 +-------------------+
 |                   |
AZ-A                AZ-B
 |                   |
Subnet A             Subnet B
 |                   |
Node                 Node
```

The exact CIDRs must be read from the current Terraform configuration rather than memorized.

## 13. Internet Gateway

For resources that require internet connectivity:

```
VPC
 |
 v
Internet Gateway
 |
 v
Internet
```

The Internet Gateway is attached to the VPC. A route table can contain:

```
0.0.0.0/0
    |
    v
Internet Gateway
```

## 14. Route Tables

Route tables determine where network traffic goes.

Example:

```
Destination       Target

VPC CIDR          local
0.0.0.0/0         Internet Gateway
```

Remember: **Route table = traffic direction**

## 15. Security Groups

Security Groups act as stateful virtual firewalls. They control inbound and outbound traffic.

Examples in the project:

```
SSH       22
HTTP      80
HTTPS     443
Grafana   3000   (lab/testing)
Prometheus 9090  (lab/testing)
Application port
Database port
```

The exact rules should be restricted to the required source rather than opening everything publicly.

## 16. EKS

Amazon EKS is the managed Kubernetes control plane.

Architecture:

```
AWS
 |
 v
EKS Control Plane
 |
 v
Worker Nodes
 |
 +--> Pods
```

EKS manages the Kubernetes control plane. The worker nodes run application workloads.

## 17. EKS Worker Nodes

The cluster uses EC2-based worker nodes.

Conceptually:

```
EKS
 |
 +--> Worker Node 1
 |
 +--> Worker Node 2
```

The cluster was configured with a managed node group. The exact node instance type/count should be taken from the current Terraform code.

The important concept:

```
EKS control plane
        |
        v
Worker nodes
        |
        v
Pods
```

## 18. EKS Core Components

The cluster contains Kubernetes system components such as:

- `aws-node`
- `coredns`
- `kube-proxy`

Later, monitoring components were added.

- The AWS VPC CNI provides networking for pods.
- CoreDNS provides Kubernetes DNS.
- kube-proxy handles service networking.

## 19. Kubernetes Namespace

Application resources should be isolated in a namespace.

Example:

```bash
kubectl create namespace webapps
```

Application resources:

```
webapps
 |
 +--> Deployment
 +--> Service
 +--> Config/Secrets
```

Monitoring uses a separate namespace: `monitoring`

## 20. Application Deployment

The application is deployed using a Kubernetes Deployment.

Conceptually:

```yaml
apiVersion: apps/v1
kind: Deployment
```

The Deployment manages application replicas.

Example:

```
Deployment
 |
 +--> Pod
 +--> Pod
 +--> Pod
```

If a pod crashes, Kubernetes recreates it. If the desired replicas are increased:

```bash
kubectl scale deployment <name> --replicas=5
```

Kubernetes creates more pods.

## 21. Kubernetes Pods

A pod is the smallest deployable unit in Kubernetes. The application container runs inside the pod.

Architecture:

```
Deployment
    |
    +--> Pod
          |
          +--> Spring Boot container
```

Pods are ephemeral. Therefore the database should not depend on the pod filesystem.

## 22. Kubernetes Service

Pods have changing IP addresses. A Service provides a stable network endpoint.

Example:

```
Client
   |
   v
Service
   |
   +--> Pod 1
   +--> Pod 2
   +--> Pod 3
```

For internal communication, `ClusterIP` is normally used.

## 23. Application Service

The application Service selects pods using labels.

Example:

```yaml
selector:
  app: bloggingapp
```

The important rule:

```
Service selector
       =
Pod labels
```

If the selector does not match the pod labels, the Service will have no useful endpoints.

## 24. Service Types

The main Kubernetes Service types are:

- ClusterIP
- NodePort
- LoadBalancer

**ClusterIP** — internal access only.

```
Pod -> Service -> Pod
```

**NodePort** — opens a port on Kubernetes nodes.

```
NodeIP:NodePort
```

**LoadBalancer** — requests an external cloud load balancer.

```
Internet
   |
   v
AWS Load Balancer
   |
   v
Kubernetes Service
   |
   v
Pods
```

## 25. The Load Balancer Used in the Project

During the actual lab implementation, the application Service was configured as:

```yaml
type: LoadBalancer
```

AWS created a Classic Load Balancer for the Service.

The observed AWS ELB had:

```
Protocol: TCP
Load Balancer Port: 80
Instance Port: NodePort
```

The Kubernetes Service had a NodePort similar to `32397`. The exact NodePort can change.

The architecture was:

```
Internet
   |
   v
AWS Classic Load Balancer
   |
   | TCP :80
   v
Kubernetes Node
   |
   | NodePort
   v
Kubernetes Service
   |
   v
Application Pod
```

## 26. Important Interview Question — Why Classic Load Balancer?

If asked: "Why did you use Classic Load Balancer instead of ALB?"

Answer honestly:

> "In this lab implementation, the Kubernetes Service was configured as type LoadBalancer, which provisioned the Classic Load Balancer. I used it to keep the setup simple and get external access to the application. For a production HTTP/HTTPS application, I would prefer an Application Load Balancer with the AWS Load Balancer Controller because it provides Layer 7 routing, path/host-based routing and better integration with Kubernetes Ingress."

Do NOT claim that Classic Load Balancer is the recommended new AWS design.

The important distinction:

```
Lab implementation
    |
    v
Classic ELB through Service type LoadBalancer

Production-preferred HTTP architecture
    |
    v
AWS Load Balancer Controller
    |
    v
ALB
    |
    v
Ingress
```

## 27. DNS — Route 53

The application domain used was: `twitter.mycoolprojects.online`

Route 53 is responsible for DNS.

The DNS flow is:

```
User
 |
 | twitter.mycoolprojects.online
 v
Route 53
 |
 v
AWS Load Balancer
 |
 v
Kubernetes Service
 |
 v
Application
```

## 28. Route 53 Record

The Route 53 record points the application hostname to the load balancer.

Conceptually:

```
twitter.mycoolprojects.online
          |
          v
AWS Load Balancer DNS
```

The load balancer DNS name observed during the project was similar to:

```
ae7d8f34520aa430e977f7e2b43f506b-726419655.ap-south-1.elb.amazonaws.com
```

The actual DNS name is generated by AWS and can change.

## 29. DNS Verification

Use:

```bash
nslookup twitter.mycoolprojects.online
```

To query Cloudflare DNS directly:

```bash
nslookup twitter.mycoolprojects.online 1.1.1.1
```

We verified that Cloudflare DNS returned:

```
Aliases:
twitter.mycoolprojects.online
```

pointing to the AWS load balancer.

If a local DNS resolver gives "Non-existent domain" while `nslookup twitter.mycoolprojects.online 1.1.1.1` works, the problem can be with the local DNS resolver/cache rather than Route 53 itself.

## 30. HTTPS / ACM

The project also included certificate work for HTTPS.

AWS Certificate Manager (ACM) is used to manage TLS certificates.

Conceptually:

```
User
 |
 | HTTPS
 v
Load Balancer
 |
 | TLS termination
 v
Kubernetes Application
```

The certificate must be available in the AWS account/region where the AWS service terminating TLS uses it.

This was one of the reasons the certificate/account arrangement required careful checking in the multi-account setup.

## 31. Certificate vs DNS

These are different responsibilities.

**Route 53** handles the domain name. Example: `twitter.mycoolprojects.online`

**ACM** handles the TLS certificate. Example: `*.mycoolprojects.online` or `twitter.mycoolprojects.online`

**Load Balancer** terminates HTTPS using the certificate.

So:

```
Route 53
   |
   | DNS
   v
Load Balancer
   |
   | ACM certificate
   v
HTTPS
```

## 32. CI/CD Pipeline

The project uses Jenkins for CI/CD. The source repository is GitHub.

High-level pipeline:

```
Developer
    |
    v
GitHub
    |
    v
Jenkins
    |
    +--> Checkout
    |
    +--> Maven Compile
    |
    +--> Tests
    |
    +--> Trivy FS Scan
    |
    +--> SonarQube
    |
    +--> Nexus
    |
    +--> Docker Build
    |
    +--> Trivy Image Scan
    |
    +--> ECR
    |
    v
EKS Deployment
```

## 33. Jenkins

Jenkins is the CI/CD automation server. It automates: build, test, security scan, code quality, artifact handling, container build, image security, deployment.

The Jenkins agent used a configured worker. Tools included:

- JDK 17
- Maven
- Sonar Scanner

## 34. Jenkins Pipeline Stages

The pipeline included stages similar to:

```
Git Checkout
Compile
Test
Trivy FS Scan
SonarQube Analysis
Nexus
Docker Build
Trivy Image Scan
ECR
Deploy
```

The exact final deployment stage can vary depending on the current Jenkinsfile.

## 35. Stage 1 — Git Checkout

Jenkins gets the latest code from GitHub.

Conceptually:

```
GitHub
   |
   v
Jenkins workspace
```

The source of truth is Git.

## 36. Stage 2 — Maven Compile

Run:

```bash
mvn clean compile
```

This checks whether the Java project compiles. The project uses Java 17.

A common failure encountered previously was a Java version mismatch. The important rule is:

```
Application Java version
        =
Maven compiler release
        =
Jenkins JDK
```

For this project: Java 17

## 37. Stage 3 — Tests

Run:

```bash
mvn test
```

This verifies application functionality through automated tests.

If tests fail, the pipeline should stop before producing a trusted release.

## 38. Stage 4 — Trivy Filesystem Scan

Trivy scans the project filesystem for vulnerabilities.

Conceptually:

```
Source code / dependencies
          |
          v
        Trivy
          |
          v
Vulnerability report
```

This helps identify vulnerable dependencies and files before containerization.

## 39. Stage 5 — SonarQube

SonarQube analyzes code quality and security-related code issues. It can identify: bugs, code smells, security issues, duplication, coverage information.

Pipeline:

```
Source
  |
  v
SonarQube Scanner
  |
  v
SonarQube Server
```

## 40. Stage 6 — Nexus

Nexus is used as an artifact repository.

For a Maven project, Maven artifacts can be stored in Nexus.

Conceptually:

```
Maven Build
    |
    v
Nexus Repository
```

Nexus answers: "Where do we store/version our build artifacts?"

Docker images are handled separately by a container registry.

## 41. Nexus vs ECR

This is an important interview distinction.

**Nexus** is used for Maven/JAR artifacts.

**Amazon ECR** is used for Docker/container images.

Therefore:

```
Maven artifact
     |
     v
Nexus

Docker image
     |
     v
ECR
```

## 42. Stage 7 — Docker Build

The Spring Boot application is packaged into a Docker image.

Conceptually:

```
Application JAR
      |
      v
Dockerfile
      |
      v
Docker Image
```

The image contains the application and runtime required to execute it.

## 43. Docker Multi-Stage Build

A multi-stage Dockerfile separates build and runtime environments.

Concept:

```
Stage 1
Maven + JDK
    |
    v
Build JAR
    |
    v
Stage 2
Smaller runtime image
    |
    v
Final application image
```

Benefits: smaller image, less unnecessary tooling, reduced attack surface, cleaner runtime container.

## 44. Stage 8 — Trivy Image Scan

After building the image:

```
Docker Image
     |
     v
Trivy
     |
     v
Vulnerability report
```

This is different from the filesystem scan.

```
Trivy FS
    = source/dependency filesystem

Trivy Image
    = container image
```

## 45. Stage 9 — Amazon ECR

The final Docker image is pushed to Amazon Elastic Container Registry.

Flow:

```
Jenkins
   |
   v
Docker build
   |
   v
Trivy image scan
   |
   v
Amazon ECR
```

ECR stores the image used by EKS.

## 46. ECR to EKS

Kubernetes pulls the image from ECR.

Flow:

```
ECR
 |
 | image pull
 v
EKS node
 |
 v
Pod
 |
 v
Spring Boot application
```

The EKS worker nodes need the appropriate AWS permissions to pull from ECR.

## 47. Kubernetes Deployment Image

The Deployment references the ECR image.

Conceptually:

```yaml
containers:
  - name: application
    image: <AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/<REPOSITORY>:<TAG>
```

The exact repository/tag should come from the current deployment manifest.

## 48. Application to Database

The Spring Boot application needs the database connection.

Conceptually:

```
Spring Boot Pod
      |
      | JDBC
      v
RDS MySQL
```

Typical information: DB host, DB port, DB name, DB username, DB password.

These should be provided securely. Do not hardcode production credentials into the Docker image or Git repository.

## 49. Kubernetes Secrets

Sensitive values should be stored using Kubernetes Secrets or a dedicated secret-management solution.

Examples:

```
DB_USERNAME
DB_PASSWORD
DB_URL
```

Concept:

```
Secret
   |
   v
Pod environment / mounted secret
   |
   v
Application
```

## 50. Spring Boot Actuator

The application includes Spring Boot Actuator.

Actuator provides operational endpoints such as `/actuator/health`.

This is useful for: health checks, load balancer checks, Kubernetes probes, monitoring.

Example: `/actuator/health` can return an application health status.

## 51. Kubernetes Health Checks

A production Kubernetes Deployment should use:

- `livenessProbe`
- `readinessProbe`

Concept:

```
Readiness
    |
    +--> Can this pod receive traffic?

Liveness
    |
    +--> Is this pod still alive?
```

If readiness fails:

```
Service
   |
   X
Pod does not receive traffic
```

If liveness repeatedly fails:

```
Kubernetes
   |
   v
Restart container
```

Actuator health endpoints can be used as probe endpoints.

## 52. End-to-End User Request Flow

This is the most important application architecture.

A user opens: `https://twitter.mycoolprojects.online`

Then:

```
1. Browser
      |
      v
2. Route 53
      |
      v
3. AWS Load Balancer
      |
      v
4. Kubernetes Service
      |
      v
5. Application Pod
      |
      v
6. Spring Boot
      |
      v
7. RDS MySQL
```

Response travels back:

```
RDS
 ↓
Spring Boot
 ↓
Pod
 ↓
Service
 ↓
Load Balancer
 ↓
Browser
```

## 53. Complete CI/CD + Runtime Architecture

```
                         DEVELOPMENT SIDE
                              |
                              v
                           GitHub
                              |
                              v
                           Jenkins
                              |
        +---------------------+----------------------+
        |                     |                      |
        v                     v                      v
     Maven                 Trivy                 SonarQube
     Build                 FS Scan               Code Quality
        |
        v
      Tests
        |
        v
      Nexus
        |
        v
    Docker Build
        |
        v
   Trivy Image Scan
        |
        v
      Amazon ECR
        |
        v
                       RUNTIME SIDE
                              |
                              v
                         Amazon EKS
                              |
                              v
                       Kubernetes Deployment
                              |
                    +---------+---------+
                    |                   |
                    v                   v
                  Pod                 Pod
                    |                   |
                    +---------+---------+
                              |
                              v
                       Kubernetes Service
                              |
                              v
                      AWS Load Balancer
                              |
                              v
                       Route 53 DNS
                              |
                              v
                             User
                              |
                              v
                         Spring Boot
                              |
                              v
                         RDS MySQL
```

Monitoring:

```
EKS
 |
 +--> Node Exporter
 |
 +--> kube-state-metrics
 |
 +--> kubelet
 |
 v
Prometheus
 |
 v
Grafana
 |
 v
Dashboard
```

## 54. Full Project Architecture Diagram

```
                                      USER
                                        |
                                        v
                              twitter.mycoolprojects.online
                                        |
                                        v
                                   Route 53
                                        |
                                        v
                              AWS Load Balancer
                                        |
                                   HTTPS/TLS
                                        |
                                        v
                              Kubernetes Service
                                        |
                           +------------+------------+
                           |                         |
                           v                         v
                    Application Pod 1        Application Pod 2
                           |                         |
                           +------------+------------+
                                        |
                                        v
                              Spring Boot Application
                                        |
                                        | JDBC
                                        v
                                  RDS MySQL

                         KUBERNETES MONITORING
                                        |
                  +---------------------+--------------------+
                  |                     |                    |
                  v                     v                    v
            Node Exporter       kube-state-metrics       kubelet
                  |                     |                    |
                  +---------------------+--------------------+
                                        |
                                        v
                                   Prometheus
                                        |
                                        v
                                     Grafana
                                        |
                                        v
                                  Dashboards


                         CI/CD / DEVSECOPS
                                        |
                                      GitHub
                                        |
                                      Jenkins
                                        |
          +-------------+---------------+----------------+
          |             |               |                |
          v             v               v                v
        Maven         Trivy         SonarQube          Tests
          |
          v
        Nexus
          |
          v
      Docker Build
          |
          v
    Trivy Image Scan
          |
          v
        Amazon ECR
          |
          v
         EKS
```

## 55. Complete Technology Map

| Layer | Technology | Purpose |
|---|---|---|
| Source | GitHub | Source control |
| CI/CD | Jenkins | Pipeline automation |
| Build | Maven | Java build |
| Language | Java 17 | Application runtime/build |
| Framework | Spring Boot 3.3.2 | Backend application |
| Security | Spring Security | Application security |
| Database access | Spring Data JPA | ORM/data access |
| Template | Thymeleaf | Web UI |
| Database | MySQL / RDS | Persistent data |
| Health | Actuator | Health/metrics endpoints |
| Coverage | JaCoCo | Test coverage |
| Artifact | Nexus | Maven artifacts |
| Container | Docker | Package application |
| Image registry | Amazon ECR | Store container images |
| Security | Trivy | Vulnerability scanning |
| Code quality | SonarQube | Static/code quality analysis |
| IaC | Terraform | AWS infrastructure |
| Cloud | AWS | Infrastructure platform |
| Kubernetes | Amazon EKS | Container orchestration |
| Networking | VPC | Private cloud network |
| DNS | Route 53 | Domain resolution |
| TLS | ACM | Certificate management |
| Monitoring | Prometheus | Metrics |
| Visualization | Grafana | Dashboards |
| K8s metrics | kube-state-metrics | Object state |
| Node metrics | Node Exporter | Node/system metrics |
| Alerting | Alertmanager | Alert handling |

## 56. What Happens When a Developer Pushes Code?

This should be easy to explain in an interview.

```
Developer
    |
    | git push
    v
GitHub
    |
    | webhook / Jenkins trigger
    v
Jenkins
```

Jenkins:

```
Checkout
   ↓
Maven compile
   ↓
Tests
   ↓
Trivy filesystem scan
   ↓
SonarQube analysis
   ↓
Maven artifact
   ↓
Nexus
   ↓
Docker build
   ↓
Trivy image scan
   ↓
ECR
   ↓
Deploy to EKS
```

Then Kubernetes:

```
EKS
 |
 v
Deployment
 |
 v
New Pod
 |
 v
New application version
```

## 57. What Happens During a Failed Pipeline?

The pipeline should stop when a critical stage fails.

Example:

```
Maven Test
    |
    X
Tests failed
    |
    v
Pipeline stops
```

Or:

```
Trivy
    |
    X
Critical vulnerability
    |
    v
Pipeline should fail according to configured policy
```

Or:

```
SonarQube
    |
    X
Quality Gate failed
    |
    v
Pipeline stops
```

The point of DevSecOps is to catch issues before deployment.

## 58. DevSecOps Shift-Left Concept

Security is integrated into the pipeline rather than performed only after deployment.

```
Code
 |
 +--> Test
 |
 +--> Code Quality
 |
 +--> Dependency Scan
 |
 +--> Image Scan
 |
 v
Deployment
```

This is called **Shift Left Security** — security checks happen earlier in the software lifecycle.

## 59. Docker vs Kubernetes

Interview distinction:

**Docker** packages and runs containers.

```
Docker
    |
    v
Container
```

**Kubernetes** manages containers at scale.

```
Kubernetes
    |
    +--> scheduling
    +--> scaling
    +--> service discovery
    +--> self-healing
    +--> rolling updates
```

The project uses both:

```
Docker
   ↓
Container image
   ↓
ECR
   ↓
EKS
```

## 60. Kubernetes Self-Healing

Suppose desired replicas = 2 and one pod crashes.

Kubernetes detects:

```
Actual = 1
Desired = 2
```

Then it creates another pod.

```
Deployment
 |
 +--> Pod 1
 +--> Pod 2
```

This is one reason the Deployment abstraction is used.

## 61. Kubernetes Scaling

Manual scaling:

```bash
kubectl scale deployment <deployment-name> --replicas=5 -n webapps
```

Check:

```bash
kubectl get pods -n webapps
```

Check Deployment:

```bash
kubectl get deployment -n webapps
```

The exact deployment name must be checked:

```bash
kubectl get deployments -n webapps
```

## 62. Rolling Updates

When the application image changes, a Deployment can perform a rolling update.

Conceptually:

```
Old Pod  Old Pod
    |
    v
New Pod created
    |
    v
Old Pod removed
    |
    v
New Pod
New Pod
```

This reduces downtime.

Check rollout:

```bash
kubectl rollout status deployment/<name> -n webapps
```

View history:

```bash
kubectl rollout history deployment/<name> -n webapps
```

Undo:

```bash
kubectl rollout undo deployment/<name> -n webapps
```

## 63. Kubernetes Service Discovery

Kubernetes Services provide stable DNS.

For example:

```
backend.webapps.svc.cluster.local
```

Conceptually:

```
Application Pod
      |
      v
Service
      |
      v
Backend Pod
```

Pods can be replaced while the Service remains stable.

## 64. Application Persistence

The application pods are not the database. The database is persistent (RDS).

Therefore:

```
Pod deleted
    |
    v
Database remains
```

This is an important production architecture principle.

## 65. Monitoring Architecture

Monitoring was added after the application infrastructure was working.

Installed: `kube-prometheus-stack`

This provided:

- Prometheus
- Grafana
- Alertmanager
- Node Exporter
- kube-state-metrics
- Prometheus Operator

Architecture:

```
EKS
 |
 +--> Nodes
 |      |
 |      +--> Node Exporter
 |
 +--> Kubernetes API
 |
 +--> kubelet
 |
 +--> kube-state-metrics
 |
 v
Prometheus
 |
 v
Grafana
 |
 v
Dashboards
```

## 66. Metrics Server vs Prometheus

Metrics Server was also installed in the cluster.

It allowed:

```bash
kubectl top nodes
kubectl top pods
```

Example: `kubectl top nodes` returned CPU and memory usage for the two worker nodes.

Important distinction:

```
Metrics Server
    |
    +--> kubectl top

Prometheus
    |
    +--> monitoring/time-series collection
    +--> PromQL
    +--> Grafana
```

Metrics Server is not a replacement for Prometheus.

## 67. Prometheus Verification

Queries used:

```
up
node_cpu_seconds_total
node_memory_MemAvailable_bytes
kube_pod_info
kube_node_info
```

The `up` query showed healthy targets including: kube-proxy, CoreDNS, Alertmanager, kubelet, API server, Node Exporter, Grafana, kube-state-metrics, Prometheus.

This confirmed the monitoring stack was functioning.

## 68. Grafana Verification

Grafana successfully connected to Prometheus using the internal Kubernetes Service DNS.

Example:

```
http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090
```

The Grafana data source test succeeded.

Kubernetes dashboards showed: CPU, Memory, Nodes, Pods, Namespaces, Workloads, Networking, Persistent Volumes, Prometheus, Node Exporter.

Therefore: **Monitoring = complete** for the project scope.

## 69. Port Forwarding — Final Understanding

The following were temporary:

```
kubectl port-forward ... 3000:80
kubectl port-forward ... 9090:9090
```

They were used only so the browser could access Grafana and Prometheus.

They are NOT part of the internal monitoring communication.

Actual internal communication:

```
Grafana Pod
    |
    v
Prometheus Service
    |
    v
Prometheus Pod
```

Therefore: **Port forwarding = temporary lab access**; **Kubernetes Service = actual application communication**

## 70. Final Production-Style Architecture

The project as implemented contains some lab-oriented simplifications.

A production-oriented version would look like:

```
                        INTERNET
                            |
                            v
                       Route 53
                            |
                            v
                     AWS ALB / Ingress
                            |
                         HTTPS
                            |
                            v
                     Kubernetes Service
                            |
                 +----------+----------+
                 |                     |
                 v                     v
              App Pod               App Pod
                 |                     |
                 +----------+----------+
                            |
                            v
                         RDS MySQL
```

CI/CD:

```
GitHub
   |
   v
Jenkins
   |
   +--> Maven
   +--> Tests
   +--> Trivy
   +--> SonarQube
   +--> Nexus
   +--> Docker
   +--> Trivy Image
   +--> ECR
   |
   v
EKS
```

Monitoring:

```
EKS
 |
 +--> Node Exporter
 +--> kube-state-metrics
 +--> kubelet
 |
 v
Prometheus
 |
 v
Grafana
```

## 71. Lab Architecture vs Production Architecture

**What was actually implemented**

```
Kubernetes Service
      |
      v
AWS Classic Load Balancer
      |
      v
Application
```

with Route 53 and certificate work around the AWS load-balancing/DNS setup.

**Production improvement**

```
Route 53
   |
   v
AWS Load Balancer Controller
   |
   v
Application Load Balancer
   |
   v
Kubernetes Ingress
   |
   v
Service
   |
   v
Pods
```

Why ALB? Because it supports Layer 7 functionality such as: host-based routing, path-based routing, HTTPS termination, listener rules, target groups.

Do not confuse Classic ELB with ALB.

## 72. Why the Project Is Strong for DevOps Interviews

This project demonstrates multiple layers.

**Infrastructure**: Terraform, AWS, VPC, EKS, IAM, Security Groups, RDS, ECR

**Containers**: Docker, Multi-stage builds, Image scanning, ECR

**Kubernetes**: Pods, Deployments, Services, Namespaces, Scaling, Rolling updates, Health checks, Service discovery

**CI/CD**: GitHub, Jenkins, Maven, Nexus

**DevSecOps**: Trivy, SonarQube, Security gates

**Networking**: VPC, Subnets, Routes, Load Balancer, DNS, TLS

**Observability**: Prometheus, Grafana, Node Exporter, kube-state-metrics, Alertmanager, Metrics Server

## 73. 60-Second Interview Answer

If the interviewer says "Explain your project," say:

> "I built a DevSecOps-based deployment pipeline for a Spring Boot application running on AWS EKS. The infrastructure is provisioned using Terraform, including the VPC, networking, IAM, EKS and supporting AWS resources. The application is built using Java 17 and Maven. GitHub is the source repository and Jenkins automates the CI/CD pipeline. The pipeline performs Maven compilation and tests, Trivy filesystem scanning, SonarQube analysis, artifact publishing to Nexus, Docker image creation, Trivy image scanning and pushing the image to Amazon ECR. EKS pulls the image from ECR and runs the application using Kubernetes Deployments and Services. The application connects to MySQL running on Amazon RDS. External access is provided through an AWS load balancer, with Route 53 providing the application DNS and ACM used for TLS. For observability, I deployed kube-prometheus-stack, which provides Prometheus, Grafana, Node Exporter, kube-state-metrics and Alertmanager. Prometheus collects Kubernetes and node metrics and Grafana visualizes them through dashboards."

## 74. 2-Minute Architecture Explanation

Start from the user:

```
User
 ↓
Route 53
 ↓
Load Balancer
 ↓
Kubernetes Service
 ↓
Application Pods
 ↓
Spring Boot
 ↓
RDS
```

Then explain deployment:

```
Developer
 ↓
GitHub
 ↓
Jenkins
 ↓
Maven
 ↓
Tests
 ↓
Trivy
 ↓
SonarQube
 ↓
Nexus
 ↓
Docker
 ↓
Trivy Image
 ↓
ECR
 ↓
EKS
```

Then monitoring:

```
EKS
 ↓
Node Exporter
kube-state-metrics
kubelet
 ↓
Prometheus
 ↓
Grafana
```

Then security:

```
Trivy
SonarQube
IAM
Security Groups
TLS
```

This is the entire project.

## 75–89. Common Interview Questions

**75. Why Terraform?**

> I use Terraform to provision AWS infrastructure as code. It makes the infrastructure reproducible, version-controlled and easier to review. Instead of manually creating resources through the AWS console, the desired state is defined in Terraform and applied using plan and apply.

**76. Why Kubernetes?**

> Kubernetes provides container orchestration. It handles scheduling, service discovery, scaling, rolling updates and self-healing for the application containers.

**77. Why EKS?**

> EKS provides a managed Kubernetes control plane on AWS, so I can use Kubernetes without manually managing the control-plane infrastructure.

**78. Why ECR?**

> ECR is the AWS-managed container registry where I store Docker images that EKS can pull.

**79. Why RDS Instead of MySQL in Kubernetes?**

> RDS separates the persistent database from the application lifecycle. Kubernetes pods are ephemeral, while the database requires persistent storage, backups and operational management. RDS provides a managed database service.

**80. Why Nexus if ECR already exists?**

> Nexus and ECR serve different purposes. Nexus is used for Maven/JAR artifacts, while ECR is the container image registry.

**81. Why Trivy Twice?**

> I use Trivy at two points. The filesystem scan checks the application source and dependencies, while the image scan checks the final Docker image and its packages.

**82. Why SonarQube?**

> SonarQube performs static code analysis to identify bugs, code smells, security issues and other code-quality problems.

**83. How Does Kubernetes Find Your Pods?**

> Through Services and selectors.

Example:

```
Service selector:
app=bloggingapp

Pod:
labels:
app=bloggingapp
```

Therefore:

```
Service
   |
   | selector
   v
Matching Pods
```

**84. What Happens If a Pod Dies?**

> The Deployment controller compares the desired replica count with the actual state. If a pod disappears, Kubernetes creates another pod to maintain the desired number of replicas.

**85. What Happens If a Node Dies?**

Conceptually:

```
Node failure
    |
    v
Kubernetes detects node unavailable
    |
    v
Pods become unavailable
    |
    v
Scheduler can recreate workloads on healthy nodes
```

The exact behavior depends on pod controllers, readiness, scheduling constraints and cluster capacity.

**86. How Do You Monitor Kubernetes?**

> I use Prometheus for metrics collection and storage and Grafana for visualization. Node Exporter collects host-level metrics, kube-state-metrics exposes Kubernetes object state, and Prometheus scrapes these targets. Grafana queries Prometheus using PromQL and displays dashboards.

**87. How Do You Know Prometheus Is Working?**

Run `up`. If targets return `1`, they are being successfully scraped.

Also verify: `node_cpu_seconds_total`, `kube_pod_info`, `kube_node_info`.

**88. How Do You Troubleshoot an Application Not Opening?**

Use a bottom-up approach:

```
1. DNS
2. Load Balancer
3. Security Group
4. Kubernetes Service
5. Service endpoints
6. Pods
7. Container
8. Application
9. Database
```

Commands:

```bash
nslookup twitter.mycoolprojects.online
kubectl get svc -n webapps
kubectl get endpoints -n webapps
kubectl get pods -n webapps
kubectl describe pod <pod> -n webapps
kubectl logs <pod> -n webapps
```

This is the troubleshooting order you should remember.

**89. Application Troubleshooting Flow**

If the URL doesn't open:

```
Does DNS resolve?
       |
       v
Does Load Balancer exist?
       |
       v
Does Service have endpoints?
       |
       v
Are Pods Running?
       |
       v
Are Pods Ready?
       |
       v
Does application respond internally?
       |
       v
Can application reach RDS?
```

This is much better than randomly changing configuration.

## 90. Important Commands for the Entire Project

**AWS**

```bash
aws sts get-caller-identity
```

Verify which AWS account/identity you are using.

```bash
aws configure
aws eks update-kubeconfig --region <region> --name <cluster>
```

Then:

```bash
kubectl get nodes
```

## 91. Terraform Commands

```bash
terraform init
terraform validate
terraform plan
terraform apply
terraform destroy
```

Use `destroy` carefully.

## 92. Docker Commands

Build:

```bash
docker build -t twitter-app .
```

List images:

```bash
docker images
```

Run:

```bash
docker run -p 8080:8080 <image>
```

Check:

```bash
docker ps
```

## 93. Jenkins Commands / Pipeline Concepts

You should understand: `agent`, `tools`, `environment`, `stages`, `steps`, `post`.

Typical:

```groovy
pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                // checkout
            }
        }

        stage('Compile') {
            steps {
                sh 'mvn clean compile'
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }
    }
}
```

The exact Jenkinsfile depends on the final project.

## 94. Kubernetes Commands

```bash
kubectl get pods -A
kubectl get pods -n webapps
kubectl get svc -n webapps
kubectl get endpoints -n webapps
kubectl get deployments -n webapps
kubectl describe pod <name> -n webapps
kubectl logs <pod> -n webapps
kubectl rollout status deployment/<name> -n webapps
kubectl rollout history deployment/<name> -n webapps
kubectl rollout undo deployment/<name> -n webapps
kubectl scale deployment <name> --replicas=5 -n webapps
```

## 95. Project Build Order

If rebuilding the project, use this order:

```
PHASE 1
AWS account/access
        |
        v
PHASE 2
Terraform
        |
        v
VPC + networking
        |
        v
EKS
        |
        v
Worker nodes
        |
        v
RDS / database connectivity
        |
        v
ECR
        |
        v
PHASE 3
Application Docker image
        |
        v
PHASE 4
Kubernetes namespace
        |
        v
Deployment
        |
        v
Service
        |
        v
Application verification
        |
        v
PHASE 5
Jenkins CI/CD
        |
        v
GitHub → Jenkins → Security → ECR
        |
        v
PHASE 6
Load Balancer
        |
        v
Route 53
        |
        v
ACM / HTTPS
        |
        v
PHASE 7
Prometheus
        |
        v
Grafana
        |
        v
Monitoring complete
```

## 96. Final Project Checklist

**AWS / Infrastructure**

- [ ] AWS credentials/account verified
- [ ] VPC created
- [ ] Subnets created
- [ ] Route tables configured
- [ ] Internet Gateway configured
- [ ] Security Groups configured
- [ ] IAM roles configured
- [ ] EKS created
- [ ] Worker nodes running
- [ ] RDS available
- [ ] ECR repository available

**Application**

- [ ] Spring Boot application builds
- [ ] Java 17 configured
- [ ] Maven works
- [ ] Tests work
- [ ] Database connection works
- [ ] Actuator works
- [ ] Docker image builds

**DevSecOps**

- [ ] GitHub connected
- [ ] Jenkins connected
- [ ] Maven build
- [ ] Unit tests
- [ ] Trivy filesystem scan
- [ ] SonarQube analysis
- [ ] Nexus artifact
- [ ] Docker build
- [ ] Trivy image scan
- [ ] ECR push

**Kubernetes**

- [ ] Namespace
- [ ] Deployment
- [ ] Pods Running
- [ ] Service
- [ ] Endpoints
- [ ] Health checks
- [ ] ECR image pull
- [ ] Scaling
- [ ] Rolling update

**External Access**

- [ ] Load Balancer
- [ ] DNS
- [ ] Route 53 record
- [ ] ACM certificate
- [ ] HTTPS
- [ ] Application reachable

**Monitoring**

- [ ] Metrics Server
- [ ] Prometheus
- [ ] Grafana
- [ ] Node Exporter
- [ ] kube-state-metrics
- [ ] Alertmanager
- [ ] Prometheus data source
- [ ] Grafana dashboards
- [ ] CPU metrics
- [ ] Memory metrics
- [ ] Pod metrics
- [ ] Node metrics

## 97. The Project in One Picture

```
                           DEVELOPER
                               |
                               v
                            GitHub
                               |
                               v
                            Jenkins
                               |
       +-----------------------+------------------------+
       |                       |                        |
       v                       v                        v
     Maven                  Trivy                   SonarQube
       |                       |                        |
       +-----------+-----------+------------------------+
                   |
                   v
                 Nexus
                   |
                   v
             Docker Build
                   |
                   v
            Trivy Image Scan
                   |
                   v
                Amazon ECR
                   |
                   v
              Amazon EKS
                   |
          +--------+--------+
          |                 |
          v                 v
      App Pod 1         App Pod 2
          |                 |
          +--------+--------+
                   |
                   v
             Kubernetes Service
                   |
                   v
          AWS Load Balancer
                   |
                   v
              Route 53
                   |
                   v
                USER


DATABASE:

App Pods
   |
   | JDBC
   v
RDS MySQL


MONITORING:

EKS
 |
 +--> Node Exporter
 +--> kube-state-metrics
 +--> kubelet
 |
 v
Prometheus
 |
 v
Grafana
 |
 v
Dashboards


ALERTING:

Prometheus
    |
    v
Alertmanager
    |
    v
Notifications
```

## 98. What You Should Be Able to Do After Reading This

You should be able to:

**Infrastructure**: explain VPC, subnet, route table and Internet Gateway; explain EKS control plane and worker nodes; explain IAM roles; explain RDS; explain ECR; explain Security Groups; explain Terraform

**Docker**: explain Dockerfile; explain multi-stage build; build an image; explain why images go to ECR

**Kubernetes**: create a namespace; create a Deployment; expose it using a Service; understand ClusterIP/NodePort/LoadBalancer; check endpoints; scale replicas; perform rolling updates; rollback; inspect logs; inspect pod events; explain self-healing

**CI/CD**: explain GitHub → Jenkins; explain Maven; explain tests; explain Trivy; explain SonarQube; explain Nexus; explain Docker; explain ECR; explain deployment

**Networking**: explain Load Balancer; explain Route 53; explain DNS resolution; explain ACM/TLS; troubleshoot DNS; troubleshoot application access

**Monitoring**: explain Metrics Server; explain Prometheus; explain Grafana; explain Node Exporter; explain kube-state-metrics; explain Alertmanager; run PromQL queries; troubleshoot monitoring

## 99. Final Interview Mental Model

If you get nervous in an interview, remember the project in six layers:

```
LAYER 1 — CODE

GitHub
Spring Boot
Java 17
Maven


LAYER 2 — CI/CD + SECURITY

Jenkins
Maven
Tests
Trivy
SonarQube
Nexus
Docker


LAYER 3 — REGISTRY

Amazon ECR


LAYER 4 — INFRASTRUCTURE

Terraform
VPC
Subnets
IAM
Security Groups
EKS
RDS


LAYER 5 — KUBERNETES

Deployment
Pods
Service
Load Balancer
Health checks
Scaling
Rolling updates


LAYER 6 — OPERATIONS

Route 53
ACM
Prometheus
Grafana
Alertmanager
Node Exporter
kube-state-metrics
```

Then connect the layers:

```
CODE
 ↓
CI/CD
 ↓
IMAGE
 ↓
ECR
 ↓
EKS
 ↓
SERVICE
 ↓
LOAD BALANCER
 ↓
DNS / HTTPS
 ↓
USER
```

and

```
EKS
 ↓
PROMETHEUS
 ↓
GRAFANA
 ↓
MONITORING
```

## 100. Final 30-Second Memory Trick

Memorize this:

```
GitHub
  ↓
Jenkins
  ↓
Maven + Test
  ↓
Trivy + SonarQube
  ↓
Nexus
  ↓
Docker
  ↓
Trivy Image
  ↓
ECR
  ↓
EKS
  ↓
Deployment
  ↓
Service
  ↓
Load Balancer
  ↓
Route 53 + HTTPS
  ↓
User

EKS
  ↓
Prometheus
  ↓
Grafana
```

That is the entire project architecture.

## 101. Final Status

The project is conceptually complete across these major areas:

```
AWS Infrastructure          ✓
Terraform                   ✓
EKS                         ✓
Application                 ✓
RDS                         ✓
Docker                      ✓
Jenkins                     ✓
Maven                       ✓
SonarQube                   ✓
Trivy                       ✓
Nexus                       ✓
ECR                         ✓
Kubernetes                  ✓
Load Balancing              ✓
Route 53                    ✓
ACM / HTTPS                 ✓
Prometheus                  ✓
Grafana                     ✓
Node Exporter               ✓
kube-state-metrics          ✓
Metrics Server              ✓
Alertmanager                ✓
```

The most important thing now is not adding more tools.

It is being able to explain:

- WHY each component exists
- HOW traffic flows
- HOW code flows
- HOW deployment works
- HOW the database is reached
- HOW DNS works
- HOW HTTPS works
- HOW monitoring works
- HOW you troubleshoot failures

Once you can explain those flows, you understand the project rather than just remembering commands.
