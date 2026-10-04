# data_engineering

hands-on data engineering study plan

## Overview

This project is a Python package generated from the Python Cookiecutter template. It provides a production-ready starting point for building Python, MLOps projects with automated testing, linting, packaging, and CI/CD support.

## Features

- A `src/` layout that keeps package code separate from tests and repository tooling.
- A configured `pyproject.toml` for packaging, dependencies, pytest, Ruff, type checking, and coverage.
- Development dependencies managed with `uv`, including pytest, pytest-cov, Ruff, pre-commit, `ty`, and build tools.
- A Makefile and `run.sh` with commands for installation, testing, linting, building, and coverage reports.
- A starter test suite with fixtures, unit tests, coverage reporting, and a 70% coverage threshold.
- Package data configuration for including JSON, YAML, CSV, Markdown, and text files in distributions.
- CI and repository configuration files supplied by the generated project workflow.

## Project structure

```text

├── .github/
│   └── workflows/
│       └── ci.yml
├── .gitignore
├── .pre-commit-config.yaml
├── .vscode/
│   ├── extensions.json
│   └── settings.json
├── Makefile
├── README.md
├── pyproject.toml
├── run.sh
├── version.txt
├── src/
│   └── <project_slug>/
│       ├── __init__.py
│       └── ...
├── tests/
│   ├── conftest.py
│   ├── consts.py
│   ├── fixtures/
│   │   └── ...
│   └── unit_tests/
│       └── test_*.py
└──
```

## Development

### Set up the project

```bash
# create and enter a virtual environment
uv venv .venv
source .venv/bin/activate

# install the package and development dependencies
make install
```

### Add and use package code

For example, add a function to `src/data_engineering/calculator.py`:

```python
def multiply(left: int, right: int) -> int:
    """Return the product of two integers."""
    return left * right
```

Use it from Python after installing the package in editable mode:

```python
from data_engineering.calculator import multiply

result = multiply(6, 7)
print(result)  # 42
```

Add a matching test in `tests/unit_tests/test_calculator.py`:

```python
from data_engineering.calculator import multiply


def test_multiply() -> None:
    assert multiply(6, 7) == 42
```

### Validate changes

```bash
# run the test suite with coverage
make test

# run formatting, linting, and pre-commit checks
make lint

# build a wheel and source distribution
make build

# serve the HTML coverage report at http://localhost:8000
make serve-coverage-report
```

## Deploy to Cloud

When you are ready to deploy, add a `Dockerfile` at the repository root if your target platform uses container images. Then add a separate workflow under `.github/workflows/` that builds the image, authenticates to your cloud provider, pushes the image to its registry, and deploys the new image. GitHub Actions provides standard workflow examples for each major cloud provider:

- [Deploying to Amazon Elastic Container Service (AWS ECS)](https://docs.github.com/en/actions/deployment/deploying-to-your-cloud-provider/deploying-to-amazon-elastic-container-service)
- [AWS Lambda Deploy Action](https://github.com/marketplace/actions/aws-lambda-deploy-action)
- [Deploying to Google Kubernetes Engine (GKE)](https://docs.github.com/en/actions/deployment/deploying-to-your-cloud-provider/deploying-to-google-kubernetes-engine)
- [Deploying to Azure Kubernetes Service (AKS)](https://docs.github.com/en/actions/how-tos/deploy/deploy-to-third-party-platforms/azure-kubernetes-service)
- [GitHub Actions deployment guides for cloud providers](https://docs.github.com/en/actions/deployment/deploying-to-your-cloud-provider)

These guides show the complete workflow pattern for building and publishing a container, including provider authentication and deployment. For a simple first deployment, use the AWS ECS, GKE, or AKS workflow for your chosen platform, then update the image name, region, and service names to match your project. Configure cloud credentials with GitHub OIDC where supported instead of storing long-lived access keys in repository secrets.

Choose the runtime based on the workload:

- **AWS ECS/Fargate, GKE, or AKS:** best for long-running APIs, workers, and services.
- **AWS Lambda, Google Cloud Functions, or Azure Functions:** best for short-lived, event-driven functions. Follow the provider-specific serverless deployment documentation when your package needs a function handler rather than a continuously running web server.