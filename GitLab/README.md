# GitLab OIDC → AWS → Terraform Deployment

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
   * Provider URL: `https://gitlab.com`
   * Audience    : `https://gitlab.com`
5. Click **Add Provider**

---

## Step 3: Create IAM Role in AWS

1. Go to **Assign Role → Create Role**
2. Select **Web Identity**
3. Choose:

   * Identity Provider: `https://gitlab.com`
   * Audience         : `https://gitlab.com`
4. Attach a policy

   * (For learning): `AdministratorAccess`
5. Role name example:

   ```
   gitlab-oidc-role
   ```
6. Create the role

---

## Step 4: Create GitLab CI/CD Pipeline

1. Open your GitLab project
2. Go to **CI/CD**
3. Click **Create .gitlab-ci.yml**
4. Paste the following code 

---

## Step 5: `.gitlab-ci.yml` File

```yaml
image:
  name: hashicorp/terraform:1.14.0
  entrypoint: [""]

stages:
  - deploy

variables:
  AWS_REGION: us-east-1
  ROLE_ARN: $ROLE_ARN

deploy:
  stage: deploy

  id_tokens:
    AWS_OIDC_TOKEN:
      aud: https://gitlab.com

  before_script:
    - apk add --no-cache curl jq aws-cli
    - terraform --version

  script:
    # Assume role using GitLab OIDC token
    - |
      aws sts assume-role-with-web-identity \
        --role-arn $ROLE_ARN \
        --role-session-name gitlab-session \
        --web-identity-token $AWS_OIDC_TOKEN \
        --duration-seconds 3600 > credentials.json

    - export AWS_ACCESS_KEY_ID=$(jq -r .Credentials.AccessKeyId credentials.json)
    - export AWS_SECRET_ACCESS_KEY=$(jq -r .Credentials.SecretAccessKey credentials.json)
    - export AWS_SESSION_TOKEN=$(jq -r .Credentials.SessionToken credentials.json)

    # Terraform
    - terraform init
    - terraform validate
    - terraform plan
    - terraform apply -auto-approve

```

### Replace:

* `AWS_REGION : ` → Your Region

## Step 6 : Set AWS Role ARN as Secret in GitHub

### Store Role ARN in GitLab CI/CD Variables
1. Open your GitLab Project
2. Go to:
   ```
   Settings → CI/CD
   ```
3. Expand:
   ```
   Variables
   ```
4. Click Add variable
5. Add the following details:
   * Key  : `ROLE_ARN`
   * Value : `Your Role arn`
	```
	example:
        (arn:aws:iam::637423214760:role/github-oidc-role)
    ```
   * Type: Variable
6. Click Add variable
   ```yaml
   variables:
     ROLE_ARN: $ROLE_ARN
   ```
---

## Step 7: Commit & Run Pipeline

1. Click **Commit changes**
2. GitLab automatically starts the pipeline
3. Open **CI/CD → Pipelines**
4. Click the running job

---

## Step 8: Check Successful Output

If everything is correct, you will see:

   ```
   Apply complete! Resources: 50 added, 0 changed, 0 destroyed.
   Outputs:
   ```


 **Success!**

* GitLab connected to AWS
* No access keys used
* Secure authentication completed
* Resources created in aws

---

## Common Mistakes (Beginner Tips)

1. Wrong AWS Role ARN
2. Wrong audience (`aud`) value
3. Missing IAM permissions

1. Double-check role ARN
2. Ensure OIDC provider exists
3. Check pipeline logs