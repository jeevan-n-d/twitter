# Twitter App — End-to-End DevSecOps Setup Guide

This README documents the complete infrastructure and CI/CD setup for the Twitter app project: a Jenkins-based DevSecOps pipeline that builds, scans, and deploys a Java (Maven/Spring Boot) application to AWS EKS, backed by SonarQube, Nexus, and RDS.

---

## 1. Architecture Overview

```
GitHub (prod branch)
      │
      ▼
Jenkins (Master + Worker EC2 nodes)
      │
      ├── Compile / Package (Maven)
      ├── Trivy FS Scan
      ├── SonarQube Static Analysis
      ├── Publish to Nexus
      │
      ▼ (worker node)
Docker Build → Trivy Image Scan → Push to Docker Hub
      │
      ▼
AWS EKS Cluster (via Terraform)
      │
      ├── Deployment: bloggingapp-deployment (3 replicas)
      ├── Service: bloggingapp-ssvc (LoadBalancer → ALB/NLB)
      ├── Namespace: webapps
      │
      ▼
RDS (MySQL) ── via VPC Peering
      │
      ▼
ACM + Load Balancer (HTTPS listeners) → https://twitter.mycoolprojects.online
      │
      ▼
OWASP ZAP DAST Scan (post-deploy)
```

---

## 2. Prerequisites

- AWS account with permissions for EC2, EKS, RDS, ACM, VPC, IAM
- Docker Hub account (`jeeva08raj/twitter`)
- GitHub repo access (`jeevan-n-d/twitter.git`, `prod` branch)
- Domain for the app (e.g. `twitter.mycoolprojects.online`) with DNS access

---

## 3. Provision Jenkins EC2 Instances

Create **2 EC2 instances**:

| Node | Role |
|---|---|
| Instance 1 | Jenkins **Master** |
| Instance 2 | Jenkins **Worker** |

On **both** the master and worker nodes:

```bash
chmod +x setup.sh
./setup.sh
exit
```

> `setup.sh` (in this repo as `setup-master.sh` / `setup-worker.sh`) installs Docker, `kubectl`, Terraform, and other required CLI tools on each node. Re-log in (or start a new shell session) after running it so updated group memberships (e.g. `docker` group) take effect.

---

## 4. Jenkins Plugin Installation

Install the following plugins on the Jenkins master (**Manage Jenkins → Plugins**):

- **Kubernetes**
- **SonarQube Scanner for Jenkins**
- **Config File Provider**
- **Eclipse Temurin installer**
- **Docker**
- **Pipeline Stage View**
- **Maven Integration** and **Pipeline Maven Integration**

---

## 5. Jenkins Global Tool Configuration

Under **Manage Jenkins → Tools**, configure:

| Tool | Name used in Jenkinsfile |
|---|---|
| SonarQube Scanner | `sonar-scanner` |
| Maven | `maven` |
| JDK | `jdk17` |
| Docker (optional) | — |

These names must match exactly what's referenced in the `Jenkinsfile`'s `tools {}` block and the `SonarQube Analysis` stage (`tool 'sonar-scanner'`).

---

## 6. Database — Amazon RDS (MySQL)

1. **Create an RDS instance** (MySQL), exposing **TCP port 3306**.
2. Connect and verify access:
   ```bash
   mysql -h 172.31.20.188 -P 3306 -u admin -p
   ```
3. **Create the database:**
   ```sql
   CREATE DATABASE twitterdb;
   ```
4. **Update application config** with the new DB endpoint and credentials in:
   - `src/main/resources/application.properties`
   - `src/test/resources/application.properties`

   Update the JDBC URL, username, and password to point at the RDS endpoint and `twitterdb`.

---

## 7. SonarQube Integration

1. Log in to SonarQube → generate a **project token** (**My Account → Security → Generate Token**).
2. In Jenkins, go to **Manage Jenkins → System → SonarQube servers**, add a server named `sonar-server` (matches `withSonarQubeEnv('sonar-server')` in the Jenkinsfile) with the SonarQube URL and the generated token as a credential.

---

## 8. Nexus Repository Integration

1. In **Nexus**, create/confirm a Maven hosted repository for artifact publishing.
2. Update `pom.xml` `<distributionManagement>` to point to the Nexus repository URL(s).
3. In Jenkins, go to **Manage Jenkins → Managed files** (Config File Provider) and add a **Global Maven settings.xml** with Nexus credentials, named `maven-settings` (matches `globalMavenSettingsConfig: 'maven-settings'` in the Jenkinsfile's `Publish Artifacts` stage).

---

## 9. Provision AWS Infrastructure with Terraform

From the `EKS/` directory (`backend.tf`, `main.tf`, `output.tf`, `variable.tf`):

```bash
terraform init
terraform plan
terraform apply
```

This provisions the **EKS cluster** (`myproject-cluster`) and associated networking/IAM resources.

### Connect `kubectl` to the new cluster:

```bash
aws eks update-kubeconfig \
  --region ap-south-2 \
  --name myproject-cluster
```

### Create the application namespace:

```bash
kubectl create namespace webapps
```

---

## 10. Networking — VPC Peering, ACM & Load Balancer

1. **Create VPC Peering** between the EKS cluster VPC and the RDS VPC (if they live in separate VPCs), so pods can reach the database over `3306` privately.
2. **Request an ACM certificate** for your domain (e.g. `twitter.mycoolprojects.online`) for HTTPS termination.
3. **Configure Load Balancer listeners:**
   - Add an **HTTPS (443) listener** using the ACM certificate.
   - Update the Load Balancer's **Security Group** to allow **inbound HTTPS (443)** from `0.0.0.0/0` (or a restricted range as appropriate).

---

## 11. Deploy the Application

Once Jenkins, SonarQube, Nexus, EKS, and RDS are all wired up, the `Jenkinsfile` pipeline handles the rest end-to-end:

1. Checkout → Compile → Package → Trivy FS Scan → SonarQube → Publish to Nexus *(Master node)*
2. Docker Build → Trivy Image Scan → Push to Docker Hub → Deploy to EKS (`webapps` namespace) → Verify → OWASP ZAP Scan *(Worker node)*

Trigger a build in Jenkins and monitor via **Pipeline Stage View**.

---

## 12. Verification Checklist

- [ ] `kubectl get pods -n webapps` shows 3 healthy `bloggingapp` pods
- [ ] `kubectl get svc -n webapps` shows an `EXTERNAL-IP`/hostname for `bloggingapp-ssvc`
- [ ] App reachable at `https://twitter.mycoolprojects.online` with a valid ACM certificate
- [ ] App can connect to `twitterdb` on RDS
- [ ] SonarQube dashboard shows analysis results for `twitter-app`
- [ ] Nexus shows the published Maven artifact
- [ ] Trivy FS/image reports and ZAP report archived in Jenkins build artifacts
- [ ] Build success/failure emails arriving at the configured address

---

## 13. Known Gaps / Follow-ups

- `imagePullSecrets` is commented out in `deployment-service.yml` — fine while `jeeva08raj/twitter` stays public, but needs a `regcred` secret if the repo goes private.
- No resource `requests`/`limits` or liveness/readiness probes defined on the deployment yet.
- RDS credentials are currently referenced by IP (`172.31.20.188`) — consider using the RDS DNS endpoint instead, since the IP can change.
- Confirm the Load Balancer Security Group also restricts unnecessary inbound rules (avoid leaving old HTTP/testing rules open).