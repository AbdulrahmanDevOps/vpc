# GitLab OIDC → AWS → Terraform Deployment (Manual Approval)

## Step 1: Create GitLab Group & Project

1. Login to GitLab

2. Create a **Group**

   * Example: `cloudgarage-group`

3. Inside the group, create a **Project**

   * Example: `oidc-test`

---

## Step 2: Create OIDC Provider in AWS

1. Login to **AWS Console**

2. Go to **IAM → Identity Providers**

3. Click **Add Provider**

4. Select:

   * Provider type: **OpenID Connect**

   * Provider URL:

     ```
     https://gitlab.com
     ```

   * Audience:

     ```
     https://gitlab.com
     ```

5. Click **Add Provider**

---

## Step 3: Create IAM Role in AWS

1. Go to **IAM → Roles → Create Role**

2. Select **Web Identity**

3. Choose:

   * Identity Provider:

     ```
     https://gitlab.com
     ```

   * Audience:

     ```
     https://gitlab.com
     ```

4. Attach a policy

   * (For learning):

     ```
     AdministratorAccess
     ```

5. Role name example:

   ```
   gitlab-oidc-role
   ```

6. Create the role

7. Copy the Role ARN

Example:

```text id="2hm67j"
arn:aws:iam::637423214760:role/gitlab-oidc-role
```

---

## Step 4: Store Role ARN in GitLab CI/CD Variables

1. Open your GitLab Project

2. Go to:

   ```
   Settings → CI/CD
   ```

3. Expand:

   ```
   Variables
   ```

4. Click:

   ```
   Add variable
   ```

5. Add:

   **Key**

   ```
   ROLE_ARN
   ```

   **Value**

   ```
   arn:aws:iam::637423214760:role/gitlab-oidc-role
   ```

   **Type**

   ```
   Variable
   ```

6. Click:

   ```
   Add variable
   ```

---


## Step 5: Create GitLab CI/CD Pipeline

1. Open your GitLab project
2. Go to **CI/CD**
3. Click **Create .gitlab-ci.yml**
4. Paste the following code

---

## Step 6: `.gitlab-ci.yml` File

```yaml
image:
  name: hashicorp/terraform:1.14.0
  entrypoint: [""]

stages:
  - plan
  - apply

variables:
  AWS_REGION: us-east-1

.terraform_auth:
  id_tokens:
    AWS_OIDC_TOKEN:
      aud: https://gitlab.com

  before_script:
    - apk add --no-cache curl jq aws-cli
    - terraform --version
    
    # Write the OIDC token to a file for AWS SDK and Terraform
    - echo "${AWS_OIDC_TOKEN}" > /tmp/web_identity_token
    
    # Set AWS environment variables for web identity
    - export AWS_WEB_IDENTITY_TOKEN_FILE=/tmp/web_identity_token
    - export AWS_ROLE_ARN="${ROLE_ARN}"
    - export AWS_DEFAULT_REGION="${AWS_REGION}"
    
    # Verify AWS authentication works
    - aws sts get-caller-identity
    
    # DO NOT DELETE the token file here - Terraform needs it!

terraform_plan:
  stage: plan
  extends: .terraform_auth

  script:
    - terraform init
    - terraform validate
    - terraform plan
    
  after_script:
    # Clean up token file after job completes
    - rm -f /tmp/web_identity_token || true

terraform_apply:
  stage: apply
  extends: .terraform_auth

  when: manual

  script:
    - terraform init
    - terraform apply -auto-approve
    
  after_script:
    # Clean up token file after job completes
    - rm -f /tmp/web_identity_token || true
```

### Replace

* `AWS_REGION` → Your AWS Region

---

## Step 7: Commit & Run Pipeline

1. Commit changes

2. GitLab automatically starts the pipeline

3. Open:

   ```
   CI/CD → Pipelines
   ```

4. Click the running pipeline

---

## Step 8: Manual Approval Process

Pipeline execution:

```text id="qqxujg"
✓ terraform_plan
⏸ terraform_apply (manual)
```

The Plan stage runs automatically.

The Apply stage waits for manual approval.

---

## Step 9: Approve Deployment

1. Open:

   ```
   GitLab → CI/CD → Pipelines
   ```

2. Open the latest pipeline

3. Locate:

   ```
   terraform_apply
   ```

4. Click the **▶ Play** button

GitLab starts:

```text id="5y6jj6"
terraform apply -auto-approve
```

---

## Step 10: Check Successful Output

If everything is correct, you will see:

```text id="ub8kh0"
Apply complete! Resources: 50 added, 0 changed, 0 destroyed.

Outputs:
```

**Success!**

* GitLab connected to AWS
* No access keys used
* Secure authentication completed
* Terraform Plan executed automatically
* Terraform Apply required manual approval
* Resources created in AWS

---

## Deployment Flow

```text id="w74k4v"
Git Push
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
Click ▶ Play
   │
   ▼
Terraform Apply
   │
   ▼
AWS Resources Created
```

---

## Common Mistakes (Beginner Tips)

### 1. Wrong AWS Role ARN

Verify:

```text id="m98wjl"
ROLE_ARN
```

matches your IAM Role ARN.

### 2. Wrong Audience Value

Must be:

```text id="sk4m6g"
https://gitlab.com
```

in both:

* AWS OIDC Provider
* GitLab id_tokens configuration

### 3. Missing IAM Permissions

Ensure the IAM Role has required AWS permissions.

### 4. OIDC Provider Not Created

Verify:

```text id="jmt4rv"
IAM → Identity Providers
```

contains:

```text id="a95gk4"
https://gitlab.com
```

### 5. Apply Job Not Appearing

Ensure:

```yaml
when: manual
```

exists under:

```yaml
terraform_apply:
```

otherwise Terraform Apply runs automatically.
