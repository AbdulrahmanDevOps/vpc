# GitHub OIDC → AWS → Terraform Deployment with Manual Approval

## Step 1: Create GitHub Repository

1. Login to GitHub

2. Create a new repository

3. Example name:

   ```
   vpc-iac
   ```

4. Initialize with a README file

---

## Step 2: Create OIDC Provider in AWS

1. Login to **AWS Console**

2. Go to **IAM → Identity Providers**

3. Click **Add provider**

4. Select:

   * Provider type: **OpenID Connect**

   * Provider URL:

     ```
     https://token.actions.githubusercontent.com
     ```

   * Audience:

     ```
     sts.amazonaws.com
     ```

5. Click **Add provider**

---

## Step 3: Create IAM Role in AWS

1. Go to **IAM → Roles → Create role**

2. Select **Web identity**

3. Choose:

   * Identity provider:

     ```
     token.actions.githubusercontent.com
     ```

   * Audience:

     ```
     sts.amazonaws.com
     ```

4. Attach policy

   * For learning:

     ```
     AdministratorAccess
     ```

5. Role name example:

   ```
   github-oidc-role
   ```

6. Create the role

7. Copy the **Role ARN**

Example:

```text
arn:aws:iam::637423214760:role/github-oidc-role
```

---

## Step 4: Configure GitHub Environment

1. Open GitHub Repository

2. Click **Settings**

3. Click **Environments**

4. Click **New environment**

5. Environment name: 
   Example:
   ```
   production
   ```

6. Click **Configure environment**

### Required Reviewers

Add:

```text
your GitHub username
```

Example:

```text
Cloudgarage_user1
```

### Prevent Self Review

Leave Disabled

### Wait Timer

Optional

```text
0 Minutes
```

Save the environment.

---

## Step 5: Create GitHub Actions Workflow

Create:

```text
.github/workflows/vpc.yml
```

Paste the following:

```yaml
name: Terraform Auto Deploy (OIDC)

on:
  push:
    branches:
      - main

permissions:
  contents: read

jobs:
  terraform:
    name: Terraform
    runs-on: ubuntu-latest

    environment:
      name: production

    permissions:
      id-token: write
      contents: read
      
    steps:
      # Checkout repository
      - name: Checkout code
        uses: actions/checkout@v4

      # Configure AWS credentials using OIDC
      - name: Configure AWS Credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: us-east-1

      # Install Terraform
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.14.0

      # Terraform Init
      - name: Terraform Init
        run: terraform init

      # Terraform Validate
      - name: Terraform Validate
        run: terraform validate

      # Terraform Plan
      - name: Terraform Plan
        run: terraform plan

      # Terraform Apply
      - name: Terraform Apply
        run: terraform apply -auto-approve
```

### Replace

```text
aws-region: us-east-1
```

with your AWS region.

---

## Step 6: Set AWS Role ARN as Secret in GitHub

1. Open GitHub Repository
2. Click **Settings**
3. Secrets and variables → **Actions**
4. Click **New repository secret**

Add:

**Name**

```text
AWS_ROLE_ARN
```

**Secret**

```text
arn:aws:iam::637423214760:role/github-oidc-role
```

5. Click **Add secret**

Now your AWS Role ARN is securely stored in GitHub Actions secrets.

---

## Step 7: Push Code

```bash
git add .
git commit -m "Terraform deployment"
git push origin main
```

---

## Step 8: Manual Approval Process

After the push:

GitHub Actions starts automatically.

The workflow runs:

```text
✓ Checkout
✓ Configure AWS Credentials
✓ Terraform Init
✓ Terraform Validate
✓ Terraform Plan
⏸ Waiting For Approval
```

Because the job targets:

```yaml
environment:
  name: production
```

GitHub pauses deployment and waits for approval.

---

## Step 9: Approve Deployment

1. Open:

   ```
   GitHub Repository
   → Actions
   ```

2. Open the running workflow

3. Click:

   ```
   Review deployments
   ```

4. Select:

   ```
   production
   ```

5. Click:

   ```
   Approve and deploy
   ```

After approval:

```text
✓ Terraform Apply
```

runs automatically.

---

## Step 10: Verify Workflow

Go to:

```text
GitHub → Repository → Actions
```

Open the workflow logs.

Successful output:

```text
Apply complete! Resources: 50 added, 0 changed, 0 destroyed.

Outputs:
```

Success:

* GitHub connected to AWS
* OIDC authentication successful
* No AWS Access Keys used
* Manual approval completed
* Terraform deployed infrastructure to AWS

---

## Common Mistakes

### Error

```text
Not authorized to perform sts:AssumeRoleWithWebIdentity
```

Check:

1. OIDC provider exists in AWS
2. Trust policy matches repository name exactly
3. Correct AWS_ROLE_ARN secret
4. `id-token: write` permission exists

### Workflow Does Not Pause

Check:

1. Environment name matches exactly:

   ```yaml
   environment:
     name: production
   ```

2. Reviewer is configured in Environment settings

3. Repository plan supports Environment approvals

### Wrong Role ARN

Verify:

```text
arn:aws:iam::<account-id>:role/github-oidc-role
```

matches the actual IAM role ARN.

---

## Deployment Flow

```text
Developer Pushes Code
        │
        ▼
GitHub Actions Starts
        │
        ▼
Terraform Init
        │
        ▼
Terraform Validate
        │
        ▼
Terraform Plan
        │
        ▼
Manual Approval Required
        │
        ▼
Approve and Deploy
        │
        ▼
Terraform Apply
        │
        ▼
AWS Resources Created
```
