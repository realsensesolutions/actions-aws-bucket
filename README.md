# AWS S3 Bucket Creator Action

A GitHub Action that creates an S3 bucket using Terraform with configurable naming, versioning, CORS, and security settings. Uses a remote backend for state management.

## Prerequisites

Before using this action, your workflow must:

1. **Configure AWS credentials** using [aws-actions/configure-aws-credentials](https://github.com/aws-actions/configure-aws-credentials).
2. **Set up the Terraform backend** using [realsensesolutions/actions-aws-backend-setup](https://github.com/realsensesolutions/actions-aws-backend-setup). This creates the S3 bucket and DynamoDB table that store Terraform state.

## Quick Start

```yaml
steps:
  - name: Checkout
    uses: actions/checkout@v4

  - name: Configure AWS credentials
    uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
      aws-region: us-east-1

  - name: Setup Terraform Backend
    uses: realsensesolutions/actions-aws-backend-setup@main
    with:
      instance: my-app

  - name: Create S3 Bucket
    uses: realsensesolutions/actions-aws-bucket@main
    id: bucket
    with:
      name: my-app

  - name: Use the bucket
    run: echo "Bucket created: ${{ steps.bucket.outputs.name }}"
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `name` | Base name for the S3 bucket. Must contain only lowercase letters, numbers, and hyphens. | **Yes** | -- |
| `cors_configuration` | Path to a JSON file (relative to the repo root) containing CORS rules. If omitted, no CORS is configured. | No | `""` |
| `naming_pattern` | Bucket naming pattern. `"default"` produces a legacy name; `"service-provider"` produces a multi-tenant name. | No | `"default"` |
| `bucket_purpose` | Purpose suffix appended to the bucket name (e.g., `"files"`, `"assets"`, `"backups"`). Only used when `naming_pattern` is `"service-provider"`. | No | `"files"` |
| `enable_versioning` | Set to `"true"` to enable S3 bucket versioning. When enabled, S3 keeps all versions of an object so you can recover from unintended overwrites or deletions. | No | `"false"` |

## Outputs

| Output | Description |
|--------|-------------|
| `name` | The name of the created S3 bucket. |

## Bucket Naming

The final bucket name depends on the `naming_pattern` input. Both patterns append a random hex suffix and are truncated to 63 characters (S3 limit).

### Default Pattern (Legacy)

When `naming_pattern` is `"default"` (or omitted):

```
{name}-action-aws-bucket-{random_id}
```

Example: `my-app-action-aws-bucket-a1b2c3d4`

### Service Provider Pattern (Multi-Tenant)

When `naming_pattern` is `"service-provider"`:

```
{name}-{bucket_purpose}-{random_id}
```

Example: `acme-corp-files-a1b2c3d4`

Use the **default** pattern for single-tenant projects. Use **service-provider** for multi-tenant SaaS setups where each provider gets its own bucket and tenants are isolated via S3 key prefixes.

## Bucket Configuration

| Setting | Value |
|---------|-------|
| Versioning | Disabled by default. Set `enable_versioning: 'true'` to enable. |
| Access Control | Private (ACL + ownership controls) |
| Public Access | Fully blocked |
| Encryption | AWS-managed (S3 default) |
| CORS | None by default. Provide a JSON file via `cors_configuration` to enable. |

## CORS Configuration

To enable CORS, create a JSON file in your repository with one or more CORS rules and pass its path to the `cors_configuration` input.

Example `cors.json`:

```json
[
  {
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["PUT", "GET"],
    "AllowedOrigins": ["https://app.example.com"],
    "ExposeHeaders": [],
    "MaxAgeSeconds": 3000
  }
]
```

Then reference it in your workflow:

```yaml
- name: Create S3 Bucket
  uses: realsensesolutions/actions-aws-bucket@main
  id: bucket
  with:
    name: my-app
    cors_configuration: cors.json
```

## Example Workflows

### Basic Usage

```yaml
name: Deploy with S3 Bucket

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: us-east-1

      - name: Setup Terraform Backend
        uses: realsensesolutions/actions-aws-backend-setup@main
        with:
          instance: my-app-prod

      - name: Create S3 Bucket
        uses: realsensesolutions/actions-aws-bucket@main
        id: bucket
        with:
          name: my-app

      - name: Deploy to bucket
        run: aws s3 sync ./dist s3://$BUCKET_NAME/
        env:
          BUCKET_NAME: ${{ steps.bucket.outputs.name }}
```

### With Versioning Enabled

```yaml
- name: Create S3 Bucket with versioning
  uses: realsensesolutions/actions-aws-bucket@main
  id: bucket
  with:
    name: my-app-backups
    enable_versioning: 'true'
```

### Multi-Tenant SaaS Pattern

```yaml
name: Deploy Multi-Tenant Infrastructure

on:
  workflow_call:
    inputs:
      service_provider_name:
        required: true
        type: string

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: us-east-1

      - name: Setup Terraform Backend
        uses: realsensesolutions/actions-aws-backend-setup@main
        with:
          instance: ${{ inputs.service_provider_name }}

      - name: Create Files Bucket
        uses: realsensesolutions/actions-aws-bucket@main
        id: files_bucket
        with:
          name: ${{ inputs.service_provider_name }}
          naming_pattern: service-provider
          bucket_purpose: files
          cors_configuration: infra/${{ inputs.service_provider_name }}/cors.json

      - name: Create Assets Bucket
        uses: realsensesolutions/actions-aws-bucket@main
        id: assets_bucket
        with:
          name: ${{ inputs.service_provider_name }}
          naming_pattern: service-provider
          bucket_purpose: assets
          enable_versioning: 'true'

      - name: Output Bucket Names
        run: |
          echo "Files bucket: ${{ steps.files_bucket.outputs.name }}"
          echo "Assets bucket: ${{ steps.assets_bucket.outputs.name }}"
```

## Backend Configuration

This action stores Terraform state in a remote S3 backend provisioned by `actions-aws-backend-setup`. The backend provides:

- Remote state storage in S3
- State locking via DynamoDB
- State encryption at rest
- Team collaboration support

## License

This project is licensed under the MIT License.
