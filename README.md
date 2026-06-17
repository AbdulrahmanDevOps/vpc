# Terraform + Checkov Workflow

This guide explains the recommended workflow for module-based Terraform projects with Checkov scanning, including handling CKV2_AWS_1 and CKV2_AWS_5 false positives.

---

## 1. Checkov HCL Scan (Static Analysis)

Run Checkov first to catch static issues before any Terraform apply:

```bash
checkov --skip-check CKV2_AWS_1,CKV2_AWS_5 -d .
```

**Notes:**

* CKV2_AWS_1 → NACL attachment to subnets uses variables, may appear as false positive
* CKV2_AWS_5 → Security Groups may attach outside the module, flagged incorrectly

---

## 2. Terraform Initialization

Initialize Terraform modules:

```bash
terraform init
```

---

## 3. Terraform Validation

Validate Terraform syntax and configuration:

```bash
terraform validate
```

---

## 4. Terraform Plan

Create a plan to preview changes:

```bash
terraform plan
```

---


## 6. Terraform Apply

Apply the plan to provision resources:

```bash
terraform apply --auto-approve
```

---

## 7. Summary

* **Checkov first** → early detection of static security issues
* **Skip CKV2_AWS_1 / CKV2_AWS_5** → prevents false positives in modules
* **Terraform plan → apply → optional plan scan** → validates runtime policies

