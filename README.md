# AWS S3 Bucket Creator Action

A GitHub Action that creates an S3 bucket using Terraform with configurable naming and security settings.

## Features

- Creates S3 bucket with unique naming pattern
- Configures bucket as private with public access blocked
- Disables versioning
- Limits bucket name to 63 characters (S3 requirement)
- Outputs bucket name for use in subsequent steps

## Usage

```yaml
- name: Create S3 Bucket
  uses: github/realsensesolutions/actions-aws-bucket@main
  id: bucket
  with:
    name: hello-world

- name: Use bucket in next step
  run: echo "Bucket created: ${{ steps.bucket.outputs.name }}"
  env:
    BUCKET_NAME: ${{ steps.bucket.outputs.name }}
```

## Inputs

| Input | Description | Required |
|-------|-------------|----------|
| `name` | Base name for the S3 bucket | Yes |

## Outputs

| Output | Description |
|--------|-------------|
| `name` | The created S3 bucket name |

## Bucket Naming

The bucket name follows this pattern:
```
${name}-action-aws-bucket-${random_id}
```

The final name is automatically truncated to 63 characters to comply with S3 bucket naming requirements.

## Bucket Configuration

- **Versioning**: Disabled
- **Access Control**: Private
- **Public Access**: Blocked
- **Encryption**: AWS managed (default)

## Prerequisites

Your GitHub workflow must have AWS credentials configured. You can do this using:

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: us-east-1
```

## Example Workflow

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
        
    - name: Create S3 Bucket
      uses: github/realsensesolutions/actions-aws-bucket@main
      id: bucket
      with:
        name: my-app
        
    - name: Deploy to bucket
      run: |
        echo "Deploying to bucket: $BUCKET_NAME"
        aws s3 sync ./dist s3://$BUCKET_NAME/
      env:
        BUCKET_NAME: ${{ steps.bucket.outputs.name }}
```

## License

This project is licensed under the MIT License.