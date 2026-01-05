# AWS S3 Bucket Creator Action

A GitHub Action that creates an S3 bucket using Terraform with configurable naming and security settings. Uses remote backend state management for improved reliability and team collaboration.

## Features

- Creates S3 bucket with unique naming pattern
- Supports both legacy and multi-tenant naming patterns
- Configures bucket as private with public access blocked
- Disables versioning
- Limits bucket name to 63 characters (S3 requirement)
- Uses Terraform remote backend for state management
- Outputs bucket name for use in subsequent steps
- Optional CORS configuration support

## Usage

**⚠️ Important:** This action requires Terraform backend resources to be set up first using the `actions-aws-backend-setup` action.

```yaml
- name: Setup Terraform Backend
  uses: realsensesolutions/actions-aws-backend-setup@main
  with:
    instance: demo

- name: Create S3 Bucket
  uses: realsensesolutions/actions-aws-bucket@main
  id: bucket
  with:
    name: hello-world
    instance: demo  # Must match the backend setup instance

- name: Use bucket in next step
  run: echo "Bucket created: ${{ steps.bucket.outputs.name }}"
  env:
    BUCKET_NAME: ${{ steps.bucket.outputs.name }}
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `name` | Base name for the S3 bucket | Yes | |
| `cors_configuration` | Path to JSON file containing CORS configuration | No | |
| `naming_pattern` | Bucket naming pattern: `"default"` (legacy) or `"service-provider"` (multi-tenant) | No | `"default"` |
| `bucket_purpose` | Purpose suffix for bucket (e.g., `"files"`, `"assets"`, `"backups"`). Only used when `naming_pattern` is `"service-provider"` | No | `"files"` |

## Outputs

| Output | Description |
|--------|-------------|
| `name` | The created S3 bucket name |

## Bucket Naming

The bucket naming pattern depends on the `naming_pattern` input:

### Default Pattern (Legacy)
When `naming_pattern: default` (or not specified):
```
${name}-action-aws-bucket-${random_id}
```

**Example:** `my-app-action-aws-bucket-a1b2c3d4`

### Service Provider Pattern (Multi-Tenant)
When `naming_pattern: service-provider`:
```
${name}-${bucket_purpose}-${random_id}
```



The final name is automatically truncated to 63 characters to comply with S3 bucket naming requirements.

### When to Use Each Pattern

- **Default Pattern**: Use for traditional single-tenant applications or when migrating existing projects
- **Service Provider Pattern**: Use for multi-tenant SaaS applications where each service provider gets their own bucket, with tenants isolated via S3 key prefixes

## Bucket Configuration

- **Versioning**: Disabled
- **Access Control**: Private
- **Public Access**: Blocked
- **Encryption**: AWS managed (default)

## Prerequisites

1. **AWS Credentials**: Your GitHub workflow must have AWS credentials configured
2. **Backend Setup**: Terraform backend resources must be created first using `actions-aws-backend-setup`

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: us-east-1
```

## Backend Configuration

This action uses a Terraform S3 backend with the following naming pattern:
- **S3 Bucket**: `{instance}-terraform-state`
- **DynamoDB Table**: `{instance}-terraform-state-lock`
- **State Key**: `buckets/{bucket-name}/terraform.tfstate`

The backend provides:
- ✅ Remote state storage
- ✅ State locking via DynamoDB
- ✅ State encryption
- ✅ Team collaboration support

## Example Workflows

### Basic Usage (Legacy Pattern)

```yaml
name: Deploy with S3 Bucket

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout
      uses: actions/checkout@v4
      
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
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
        # naming_pattern defaults to "default"
        
    - name: Deploy to bucket
      run: |
        echo "Deploying to bucket: $BUCKET_NAME"
        aws s3 sync ./dist s3://$BUCKET_NAME/
      env:
        BUCKET_NAME: ${{ steps.bucket.outputs.name }}
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
        
    - name: Output Bucket Names
      run: |
        echo "Files bucket: ${{ steps.files_bucket.outputs.name }}"
        echo "Assets bucket: ${{ steps.assets_bucket.outputs.name }}"
```

### Testing with Matrix Strategy

See `example.yml` in this repository for a comprehensive example using matrix strategy to test both naming patterns.

## License

This project is licensed under the MIT License.