# Kubernetes Jenkins RBAC — Clean Setup

## 1. Create Namespace

```bash
kubectl create namespace webapps
```

## 2. Create ServiceAccount

```yaml
# serviceaccount.yaml

apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins
  namespace: webapps
```

```bash
kubectl apply -f serviceaccount.yaml
```

## 3. Create Role

```yaml
# role.yaml

apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-role
  namespace: webapps

rules:
  - apiGroups: [""]
    resources:
      - pods
      - services
      - configmaps
      - secrets
    verbs:
      - get
      - list
      - watch
      - create
      - update
      - patch
      - delete

  - apiGroups: ["apps"]
    resources:
      - deployments
      - replicasets
    verbs:
      - get
      - list
      - watch
      - create
      - update
      - patch
      - delete

  - apiGroups: ["networking.k8s.io"]
    resources:
      - ingresses
    verbs:
      - get
      - list
      - watch
      - create
      - update
      - patch
      - delete
```

```bash
kubectl apply -f role.yaml
```

## 4. Create RoleBinding

```yaml
# rolebinding.yaml

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-rolebinding
  namespace: webapps

roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: app-role

subjects:
  - kind: ServiceAccount
    name: jenkins
    namespace: webapps
```

```bash
kubectl apply -f rolebinding.yaml
```

## 5. Verify

```bash
kubectl get sa -n webapps
kubectl get role -n webapps
kubectl get rolebinding -n webapps
```

## 6. Test ServiceAccount Permissions

```bash
kubectl auth can-i create deployments \
  --as=system:serviceaccount:webapps:jenkins \
  -n webapps
```

Should return:

```
yes
```

## 7. Generate Token

```bash
kubectl create token jenkins -n webapps
```

Copy the generated token.

## 8. Get EKS API Server

```bash
aws eks describe-cluster \
  --region ap-south-2 \
  --name myproject-cluster \
  --query 'cluster.endpoint' \
  --output text
```

## 9. Get CA Certificate

```bash
aws eks describe-cluster \
  --region ap-south-2 \
  --name myproject-cluster \
  --query 'cluster.certificateAuthority.data' \
  --output text
```

## 10. Jenkins Credential

Create Jenkins credential:

```
ID: k8-cred
```

Use:

```
EKS API Server
CA Certificate
ServiceAccount Token
```

Then your Jenkinsfile uses:

```groovy
withKubeConfig(
    credentialsId: 'k8-cred',
    namespace: 'webapps'
) {
    sh '''
        kubectl get nodes
        kubectl apply -f kubernetes/
    '''
}
```

---

That's the complete Namespace → ServiceAccount → Role → RoleBinding → Token → Jenkins flow.
```

### Generate token using service account in the namespace

[Create Token](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/#:~:text=To%20create%20a%20non%2Dexpiring,with%20that%20generated%20token%20data.)



kubectl create secret docker-registry regcred \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=jeeva08raj \
  --docker-password=Jee$123@ND \
  -n webapps






