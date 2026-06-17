# GitHub OIDC → AWS → Terraform Deployment

## Step 1: Create GitHub Repository

1. Login to GitHub
2. Create a new repository
3. Example name:
   ```
   github-aws-oidc
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

1. Go to **Assign Roles → Create role**
2. Select **Web identity**
3. Choose:

   * Identity provider: `token.actions.githubusercontent.com`
   * Audience: `sts.amazonaws.com`
4. Attach policy

   * (For learning): `AdministratorAccess`
5. Role name example:

   ```
   github-oidc-role
   ```
6. Create the role

 Copy the **Role ARN** (you’ll need it later)

---

## Step 4: Create GitHub Actions Workflow

1. In your repository, create this file:
   ```
   .github/workflows/blank.yml
   ```
2. Paste the following code 

---

## Step 5: GitHub Actions Workflow (`aws-oidc.yml`)

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

      # Terraform Apply (Auto apply on push to main)
      - name: Terraform Apply
        run: terraform apply -auto-approve
```

### Replace:

* `AWS_REGION : `  → your aws-region

### Set AWS Role ARN as Secret in GitHub

## Step 6: Open Your GitHub Repository
1. Go to your repository on GitHub
2. Click Settings
3. Secrets and variables → Actions
4. Click New repository secret
5. Add the following:

   * Name   -> AWS_ROLE_ARN
   * Secret	-> Your Role ARN
   ```
   Example : arn:aws:iam::637423214760:role/github-oidc-role
   ```
6. Click Add secret

 * Now your AWS Role ARN is securely stored in GitHub Actions secrets.
---

## Step 7: Run & Verify Workflow

1. Go to **GitHub → Repository → Actions**
2. Click the workflow run
3. Open the logs

If successful, you will see:

```
Apply complete! Resources: 50 added, 0 changed, 0 destroyed. 
Outputs:
```

**Success!**

* GitHub connected to AWS
* No access keys used
* Secure authentication completed
* Resources created in aws
---

## Common Mistakes

1. Wrong IAM Role ARN
2. Missing `id-token: write` permission
3. OIDC provider not created in AWS

1. Double-check role ARN
2. Ensure permissions are correct
3. Check workflow logs

---