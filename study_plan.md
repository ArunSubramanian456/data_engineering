# Analytics & Cloud Data Engineering Study Plan

> Living study plan + project memory for the `data_engineering` repo. Agent rules and guardrails live in `CLAUDE.md` + `.claude/` (local only, gitignored; this plan is the only agent doc in git).
> Owner: Senior Data Scientist (strong SQL + Python) leveling up in analytics engineering and AWS data engineering.
> Cadence: **≤ 6 hours per week**, ~45 weeks (+1 buffer). Labs-first: course videos for concepts, mini-projects for mastery.

---

## 0. Instructions for Claude (read first, every session)

You are my **data engineering mentor and pair programmer** for this repo.

**How to help**
- Default to **hints, reviews and questions**; write a full solution only when I say "show me" or "write it". The point is that I build it.
- When I start a session, read the **Progress tracker** (§2) and tell me what's next for the current week in 2–3 lines.
- When I say a task is done, **tick its checkbox**, update the tracker row, and add a dated line to the **Learning log** (§13). Never tick a box I haven't confirmed.
- Review my code against the mini-project's **Done when** criteria before I merge the PR into `main`.
- Lecture links in this file open the right Udemy lecture. When I'm stuck on a lab and Claude in Chrome is connected, open that lecture and read its transcript or resources before answering.
- If a lecture is outdated (Airflow 2 vs 3, dbt version changes, AWS console changes), tell me the current equivalent.

**Environment facts**
- Windows 11 + **WSL2 (Ubuntu)**. All code lives in the Linux filesystem: `~/repos/data_engineering` (never `/mnt/c/...`).
- Python via **uv**; lint/format via **ruff**; type checks via **ty**; hooks via **pre-commit**. Repo generated from `ArunSubramanian456/python-course-cookiecutter-v2`.
- AWS via **IAM Identity Center (SSO)** profiles. Use `AWS_PROFILE=<your-sso-profile>`, region `<your-region>` (fill in). Run `aws sso login --profile <your-sso-profile>` when tokens expire.
- Docker: Docker Engine inside WSL2 (or Docker Desktop with WSL integration).

**Work context (why this plan is shaped this way)**
- At work I query **Redshift**; SQL jobs are scheduled in an internal tool (DataCentral) and write files to **S3**. My ML workflow then reads those files, builds features in **pandas**, and writes the modeling dataset to another S3 bucket. There is no Airflow at work today.
- Priority #1 is **dbt on Redshift** (software engineering practices for SQL). Priority #2 is **orchestration**: Airflow (portable career skill) and **Step Functions** (AWS-native). Later phases are lower priority.
- **Fundamentals before wrappers:** I learn the plain official tools first (F1 dbt CLI, F2 Airflow components, hand-written ASL) before Cosmos, Workflow Studio or IDE extensions. When I use a wrapper, explain what it does in terms of the underlying tool.

**Rules**
- Redshift Serverless (the study warehouse) keeps the smallest base capacity and a daily RPU-hour usage limit; never raise them without asking.
- Before any command that **creates a billable AWS resource**, state the expected cost and ask me. Never create MWAA, EMR-on-EC2 clusters, provisioned Redshift clusters, NAT gateways or provisioned resources without an explicit "yes".
- Tag every AWS resource `project=de-study-plan`, `owner=<me>`. Prefer pay-per-use services (S3, Athena, Lambda, Glue Flex, EMR Serverless, Step Functions).
- Prefer **open-source or free** tools. Flag anything that is paid, trial-only or source-available-but-not-OSI before suggesting it.
- Never commit data, `.duckdb` files, credentials, or `.env`. `data/` is gitignored.
- Solo repo, PR flow: `main` is branch-protected (PR required, 0 approvals, required checks = lint + tests, admin bypass allowed). Work on a branch with Conventional Commits (`feat(mp01): …`), push it, open a PR, and merge (squash/rebase) once CI is green. The PR runs CI; there is no human review. Direct pushes to `main` (admin bypass) only for plan/docs-only commits. Run `make lint` and `make test` before pushing (enforced by `.claude/hooks/gate-push.sh`).
- Glue 5.x runs **Python 3.11** and Spark **3.5**; code in `src/` that Glue or EMR imports must stay 3.11-compatible.

**Common commands**
```bash
make install          # uv: dev + project deps (extend to groups, see §4)
make lint             # pre-commit: ruff, ty, sqlfluff, yaml/toml checks
make test             # pytest + coverage (fail-under 70)
cd dbt/nyc_taxi && uv run dbt build --target dev
cd airflow && AIRFLOW_HOME=$PWD .venv/bin/airflow standalone        # UI on :8080
cd airflow && .venv/bin/airflow dags test <dag_id> 2024-01-15 && .venv/bin/pytest tests/
cd infra && terraform fmt -recursive && terraform validate && terraform plan
```

---

## 1. Goals

1. **Priority #1 — dbt on Redshift with software engineering practices**: modular layers, DRY macros, tests (generic, singular, unit, contracts), Git workflow, CI/CD with Slim CI, and refactoring work-style SQL into dbt.
2. **Priority #2 — Orchestration with Airflow and AWS Step Functions** of SQL + pandas + dbt pipelines end to end (the Redshift → S3 → pandas → S3 pattern from work).
3. **Cloud data engineering on AWS** (S3, IAM, Lambda, Terraform IaC, GitHub OIDC CI/CD).
4. **AWS Glue (ETL, Workflows, Data Catalog, Crawlers), Athena, Step Functions.**
5. **PySpark and distributed processing** on local Spark, EMR Serverless and Glue.

---

## 2. Progress tracker

Status: `⬜ Not started` · `🟨 In progress` · `✅ Done`

| Week | Phase | Focus | Hours | Status |
|---|---|---|---|---|
| 1 | 0 Setup | WSL2, tooling, repo from cookiecutter, VS Code | 5.5 | ⬜ |
| 2 | 1 dbt | Course S1–S4 follow-along (Snowflake trial starts) | 5.6 | ⬜ |
| 3 | 1 dbt | Course S5–S10 follow-along | 5.5 | ⬜ |
| 4 | 1 dbt | Course S11, S13–S16; MP1 kickoff | 5.5 | ⬜ |
| 5 | 1 dbt | Course S17–S22 (Slim CI reference build) | 5.7 | ⬜ |
| 6 | 1 dbt | Redshift foundations: Serverless, COPY; MP1 setup | 5.9 | ⬜ |
| 7 | 1 dbt | F1: dbt under the hood (CLI, artifacts, dbtRunner) | 5.5 | ⬜ |
| 8 | 1 dbt | Redshift table design + Python access; MP1 part A | 6.0 | ⬜ |
| 9 | 1 dbt | MP1 part B (tests, incremental, refactor proof) | 5.5 | ⬜ |
| 10 | 1 dbt | MP2 dbt CI/CD on Redshift | 5.5 | ⬜ |
| 11 | 2 Orchestration | Airflow fundamentals (Airflow 3, standalone) | 5.5 | ⬜ |
| 12 | 2 Orchestration | F2: Airflow from its parts; dbt in Airflow by hand | 6.0 | ⬜ |
| 13 | 2 Orchestration | Course ETL DAG; MP3 sensing + extract | 5.7 | ⬜ |
| 14 | 2 Orchestration | Airflow + Redshift lab; MP3 load + resilience | 5.7 | ⬜ |
| 15 | 2 Orchestration | MP3 backfill + tests; MP4 start | 6.0 | ⬜ |
| 16 | 2 Orchestration | MP4: dbt (Cosmos) → UNLOAD → pandas → modeling dataset | 5.0 | ⬜ |
| 17 | 2 Orchestration | Lambda + Step Functions foundations (ASL by hand) | 5.9 | ⬜ |
| 18 | 2 Orchestration | Step Functions with Redshift and ECS; MP5 core | 5.9 | ⬜ |
| 19 | 2 Orchestration | MP5 finish; Airflow vs Step Functions | 5.5 | ⬜ |
| 20 | 3a Terraform | TF intro, state, workflow, CLI | 5.8 | ⬜ |
| 21 | 3a Terraform | Block types; first configurations | 5.9 | ⬜ |
| 22 | 3a Terraform | Reusable code: locals, for_each, lifecycle, functions | 5.8 | ⬜ |
| 23 | 3a Terraform | Modules; import + maintenance; import MP2 OIDC role + MP5 resources | 6.0 | ⬜ |
| 24 | 3b AWS | S3 + IAM; MP6 lake infrastructure in Terraform | 5.5 | ⬜ |
| 25 | 3b AWS | Lambda ingestion; MP6 ingest | 5.0 | ⬜ |
| 26 | 3b AWS | Glue components + Catalog; MP6 crawl + query | 5.3 | ⬜ |
| 27 | 3b AWS | Athena deep dive; MP6 optimize | 5.6 | ⬜ |
| 28 | 3b AWS | PySpark/Glue dev lifecycle; MP7 job + tests | 5.5 | ⬜ |
| 29 | 3b AWS | Glue APIs + bookmarks; MP7 DQ, Iceberg, Workflow | 5.5 | ⬜ |
| 30 | 3b AWS | Redshift Spectrum; MP7 deploy; MP8 start | 5.7 | ⬜ |
| 31 | 3b AWS | AWS CI/CD; MP8 complete | 6.0 | ⬜ |
| 32 | 3b AWS | MP9 dbt-athena | 5.3 | ⬜ |
| 33 | 3b AWS | MP9 end-to-end orchestration | 5.0 | ⬜ |
| 34 | 4 Spark | Spark architecture; local Spark; MP10 baseline | 5.2 | ⬜ |
| 35 | 4 Spark | DataFrame APIs; MP10 scaling + plans | 5.8 | ⬜ |
| 36 | 4 Spark | Joins, ranking, Catalyst; MP10 tuning A | 5.9 | ⬜ |
| 37 | 4 Spark | Cluster config, file formats; MP10 tuning B | 5.9 | ⬜ |
| 38 | 4 Spark | EMR; MP11 package + EMR Serverless | 5.8 | ⬜ |
| 39 | 4 Spark | EMR deploy; MP11 Glue + orchestration | 5.5 | ⬜ |
| 40 | 4 Spark | MLlib; MP12 features + GBT | 5.9 | ⬜ |
| 41 | 4 Spark | MP12 per-zone models with applyInPandas | 5.0 | ⬜ |
| 42 | 5 Capstone | Design + ingest | 6.0 | ⬜ |
| 43 | 5 Capstone | Spark processing + quality | 6.0 | ⬜ |
| 44 | 5 Capstone | dbt + orchestration | 6.0 | ⬜ |
| 45 | 5 Capstone | Serve, docs, demo | 6.0 | ⬜ |
| 46 | Buffer | Catch-up or AWS DE Associate exam prep | ≤6 | ⬜ |

**Mini-project scoreboard** (F = fundamentals lab, plain official tools only)

| ID | Title | Status |
|---|---|---|
| F1 | dbt under the hood: CLI, artifacts, dbtRunner, manifest DAG | ⬜ |
| MP1 | NYC Taxi dbt project on Redshift Serverless (with refactor proof) | ⬜ |
| MP2 | dbt CI/CD on Redshift (Slim CI, GitHub OIDC) | ⬜ |
| F2 | Airflow from its parts; dbt in Airflow by hand | ⬜ |
| MP3 | Airflow ingestion DAG: S3 → Redshift | ⬜ |
| MP4 | Work pipeline in Airflow: dbt → UNLOAD → pandas → modeling dataset | ⬜ |
| MP5 | Same work pipeline in Step Functions | ⬜ |
| MP6 | S3 lake + Crawler + Catalog + Athena | ⬜ |
| MP7 | Glue ETL job + Glue Workflow | ⬜ |
| MP8 | Step Functions part 2: Glue + Athena | ⬜ |
| MP9 | dbt-athena on the lake, end to end | ⬜ |
| MP10 | pandas vs DuckDB vs Spark + tuning | ⬜ |
| MP11 | Same Spark job on EMR Serverless and Glue | ⬜ |
| MP12 | Distributed features + MLlib + per-zone models | ⬜ |
| Capstone | Full stack on a new dataset | ⬜ |

---

## 3. Courses: what to use and what to skip

Lecture times are video runtimes from each curriculum. Budget assumes ~1.25× playback with pauses for follow-along.

| Short name | Course | Use | Skip |
|---|---|---|---|
| **dbt** | [The Complete dbt Bootcamp: Zero to Hero (13 h)](https://www.udemy.com/course/complete-dbt-data-build-tool-bootcamp-zero-to-hero-learn-dbt/learn/) | S1–S11, S13–S23, S27; optional S24 Dagster comparison | S12, S25 course capstone (MP1 replaces it), S26, S29–S34 reference |
| **ULT** | [Ultimate AWS Data Engineering Bootcamp: 15 Real-World Labs (8 h)](https://www.udemy.com/course/ultimate-aws-data-engineering-bootcamp-with-real-world-labs/learn/) | S2, S3, S4, S5, S6, S10, S16; optional S7, S13 | Streaming labs S8, S9, S11, S14, S15 (optional later) |
| **AWSDA** | [Data Engineering using AWS Data Analytics (25.5 h)](https://www.udemy.com/course/data-engineering-using-aws-analytics-services/learn/) | S4, S5, S6, S9–S17, S21, S23, **S24–S28 Redshift (work-critical)**; optional S22 | S2/S3 local setup (we use WSL2), S7–S8 EC2, S18–S20 |
| **CERT** | [AWS Certified Data Engineer Associate (24 h)](https://www.udemy.com/course/aws-data-engineer/learn/) | S8 Glue/Athena/EMR/Lake Formation lectures, S9 Step Functions/EventBridge/SNS/SQS/MWAA | Most of S3–S7, S11, S13, S15 (unless sitting the exam) |
| **PYS** | [Spark and Python for Big Data with PySpark (10.5 h)](https://www.udemy.com/course/spark-and-python-for-big-data-with-pyspark/learn/) | S11 Linear Regression, S13 Trees/Random Forests | Everything else |
| **DEE** | [Data Engineering Essentials: SQL, Python & Spark (56 h)](https://www.udemy.com/course/data-engineering-essentials-sql-python-and-spark/learn/) | S19, S20, S33–S38, S40–S43 | S1–S18 (known), S21–S32 (Databricks/Spark SQL basics), S39, S44–S53 Hadoop/Dataproc |
| **BDB** | [Big Data Engineering Bootcamp with GCP and Azure (74 h)](https://www.udemy.com/course/big-data-engineering-bootcamp-with-gcp-and-azure-cloud/learn/) | S28 Airflow, S29 Airflow ETL project (run with `airflow standalone` instead of Astro) | Everything else |
| **TF** | [HashiCorp Terraform: The Ultimate Beginner's Guide with Labs (15.5 h)](https://www.udemy.com/course/terraform-for-beginners-with-labs/learn/) | S2 (minus OpenTofu lectures), S4–S13; optional S14 | S1, S3 (tools installed in week 1; its credential lectures use static keys, you use SSO), S15–S17 |

DEE Spark labs use Databricks on GCP; run them in **local PySpark/Jupyter** instead.

Free extras used in the plan: [AWS Step Functions Workshop](https://catalog.workshops.aws/stepfunctions/), [Astronomer Academy](https://academy.astronomer.io/) (Airflow 3 fundamentals), and the official dbt and Airflow docs for the F1/F2 labs.

Lecture checkboxes link to the **first lecture of that section** (CERT items link to the exact lecture). Section numbers follow each curriculum as of October 2026; if a link breaks, the course was reorganized — ask Claude to re-map it with the browser.

---

## 4. Tooling decisions and licenses

| Need | Choice | License / cost | Notes |
|---|---|---|---|
| Transformation | **dbt Core 1.x** with **`dbt-redshift`** (primary), `dbt-athena` (lake, MP9), `dbt-duckdb` (optional local) | Apache 2.0 | What the course teaches; works with Cosmos and sqlfluff |
| dbt next-gen engine | dbt v2 / Fusion + official dbt VS Code extension | Free, proprietary distribution | Optional try in week 9 (course S23); not the default engine here |
| Primary warehouse | **Amazon Redshift Serverless** | $300 credit for 90 days if your account never used Redshift Serverless; then per-second billing (60 s minimum) | Same engine as work; MP1–MP5. Smallest base capacity + daily usage limit |
| Course warehouse | Snowflake | 30-day free trial | Weeks 2–5 only |
| Linting SQL | **sqlfluff** + dbt templater | MIT | |
| dbt packages | `dbt_utils`, `dbt_project_evaluator`, `dbt_expectations` (metaplane fork) | Apache 2.0 | The original calogica repo is archived |
| Orchestration | **Apache Airflow 3** | Apache 2.0 | |
| Local Airflow runner | **Official Apache Airflow 3** (`airflow standalone`; components run separately in F2) | Apache 2.0 | No Docker or Astro; uses your SSO profile directly. The course's Astro CLI commands map 1:1 |
| dbt in Airflow | Hand-built first (F2), then **astronomer-cosmos** (MP4) | Apache 2.0 | |
| AWS-native orchestration | **AWS Step Functions** + Lambda (AWS SDK for pandas layer) + ECS Fargate | Pay per use (pennies at this scale) | ASL written by hand first; MP5, MP8 |
| Python ↔ Redshift | Redshift Data API (boto3), `redshift_connector`, `awswrangler` | Apache 2.0 | Data API for statements (UNLOAD/COPY); the others to read results into pandas |
| Managed Airflow (MWAA) | Not used | Paid, bills while idle | Optional single session in MP9 |
| Data validation in pandas | **pandera** | MIT | |
| IaC | **Terraform** (≥ 1.10) | Free; Business Source License (source-available, not OSI) | Free for learning and internal use; industry standard for data platforms. OpenTofu is the drop-in OSS fork if ever needed |
| Containers | **Docker Engine in WSL2** | Apache 2.0 | Docker Desktop is free for personal use only |
| Spark | **PySpark 3.5.x** + Java 17 | Apache 2.0 | Match Glue 5.x / EMR 7.x Spark 3.5 line |
| Glue local dev | AWS Glue Docker image (`public.ecr.aws/glue/aws-glue-libs`) | Free | |
| Table format | **Apache Iceberg** | Apache 2.0 | Native in Athena, Glue, EMR |
| Weather source | **Open-Meteo historical API** | Free, no key | |
| CI/CD | **GitHub Actions** + **GitHub OIDC → AWS IAM role** | Free for public repos | No static AWS keys in GitHub |
| Alerts | SNS email, or a free Slack workspace webhook | Free | |

---

## 5. VS Code setup (WSL2)

Open the repo **from WSL**: `cd ~/repos/data_engineering && code .`. Extensions then install on the WSL side ("Install in WSL: Ubuntu").

**Official extensions (by the tool's own publisher)**

| Extension | ID | Why |
|---|---|---|
| WSL | `ms-vscode-remote.remote-wsl` | Required for WSL2 development |
| Python, Pylance, Python Debugger | `ms-python.python`, `ms-python.vscode-pylance`, `ms-python.debugpy` | Core Python |
| Jupyter | `ms-toolsai.jupyter` | Spark/pandas notebooks |
| Ruff | `charliermarsh.ruff` | Astral's official extension (format + lint on save) |
| ty | `astral-sh.ty` | Astral's official type checker |
| AWS Toolkit | `amazonwebservices.aws-toolkit-vscode` | SSO profiles, S3/CloudWatch browsing, Lambda, **Step Functions Workflow Studio + ASL validation** |
| HashiCorp Terraform | `hashicorp.terraform` | HCL syntax, validation, format on save, provider docs on hover |
| Container Tools | `ms-azuretools.vscode-containers` | Docker containers: Postgres, Glue image, the dbt image for ECS (successor to the Docker extension) |
| GitHub Actions | `github.vscode-github-actions` | Workflow authoring, run status |
| GitHub Pull Requests | `github.vscode-pull-request-github` | PR review in editor |
| YAML | `redhat.vscode-yaml` | Schemas for dbt, GitHub workflows |
| Snowflake | `snowflake.snowflake-vsc` | Weeks 2–5 only |
| dbt (official, dbt Labs) | `dbtLabsInc.dbt` | Requires the dbt v2/Fusion engine; optional try in week 9 |

**Community extensions worth having** (no official equivalent exists)

| Extension | ID | Why |
|---|---|---|
| Power User for dbt | `innoverio.vscode-dbt-power-user` | Best dbt Core experience: go-to-definition, lineage, compiled SQL preview, run model/tests. Core features need no account |
| sqlfluff | `dorzey.vscode-sqlfluff` | Inline SQL lint with the dbt templater |
| Even Better TOML | `tamasfe.even-better-toml` | pyproject.toml |
| GitLens | `eamodio.gitlens` | Blame/history |

There is **no official Apache Airflow extension**. For DAGs, Pylance against `airflow/.venv` (below) plus `airflow dags list-import-errors` gives import checking and autocomplete.

**Changes to the template's `.vscode/extensions.json`**: remove `GitHub.copilot-labs` (deprecated), replace `ms-azuretools.vscode-docker` with `ms-azuretools.vscode-containers`, and add the rows above.

**Settings to add to `.vscode/settings.json`**
```jsonc
{
  "files.associations": { "**/dbt/**/*.sql": "jinja-sql" },
  "dbt.queryLimit": 500,
  "sqlfluff.linter.run": "onSave",
  "sqlfluff.executablePath": "${workspaceFolder}/.venv/bin/sqlfluff",
  "yaml.schemas": {
    "https://raw.githubusercontent.com/dbt-labs/dbt-jsonschema/main/schemas/latest/dbt_yml_files-latest.json": ["dbt/**/models/**/*.yml"]
  },
  "files.watcherExclude": { "**/target/**": true, "**/dbt_packages/**": true, "**/data/**": true, "**/airflow/logs/**": true },
  "python.analysis.extraPaths": ["src"],
  "jupyter.notebookFileRoot": "${workspaceFolder}"
}
```

**Multi-root workspace** (`data_engineering.code-workspace`) so each area uses its own interpreter:
```jsonc
{
  "folders": [
    { "path": ".", "name": "root (shared libs, dbt, spark, infra)" },
    { "path": "airflow", "name": "airflow (Airflow 3)" }
  ],
  "settings": {}
}
```
`airflow/.venv` is created in week 11 (Phase 2 setup). It runs Airflow itself and gives Pylance its imports; select it as the interpreter for the airflow root. Do week 7 (F1) in the terminal without the dbt extension.

---

## 6. Phase 0 — Setup (Week 1)

### Week 1 — Environment, repo, dataset (~5.5 h)

**Lectures (~0.4 h)**
- [ ] [AWSDA S4 Getting Started with S3, IAM and CLI (25 min)](https://www.udemy.com/course/data-engineering-using-aws-analytics-services/learn/lecture/28005754) — skim; you already have SSO

**Hands-on (~5.1 h)**

*WSL2 (0.5 h)*
- [ ] Use **Ubuntu 24.04 LTS** in WSL2 (`wsl --install -d Ubuntu-24.04`). 20.04 is out of standard support, and Docker's and HashiCorp's apt repos no longer publish for it.
- [ ] Create `C:\Users\<you>\.wslconfig`: `[wsl2]` → `memory=` ~60% of RAM (10GB on a 16 GB machine), `processors=6`, `swap=8GB`. Run `wsl --shutdown`.
- [ ] `sudo apt update && sudo apt install -y build-essential git unzip curl make jq`; `git config --global core.autocrlf input`; `git config --global fetch.prune true`. Java (`openjdk-17-jdk`) only for the Spark phase (week 34+).

*Tooling (1.0 h)*
- [ ] uv: `curl -LsSf https://astral.sh/uv/install.sh | sh`; `uv python install 3.11 3.12`
- [ ] Docker Engine in WSL2 (docs.docker.com → Install Docker Engine on Ubuntu), add user to `docker` group, enable systemd in `/etc/wsl.conf`
- [ ] AWS CLI v2 in WSL; copy or recreate SSO profiles in `~/.aws/config`; verify `aws sts get-caller-identity --profile <your-sso-profile>`
- [ ] GitHub CLI: `gh auth login`
- [ ] Terraform via HashiCorp's apt repository (developer.hashicorp.com → Install Terraform → Linux/Ubuntu); verify `terraform -version` ≥ 1.10

*Repo from your cookiecutter (2.5 h)*
- [ ] Run your template's **Create or Update Repo** workflow: `repo_name=data_engineering`, **public** (free Actions minutes + GitHub Pages for dbt docs). Merge its PR.
- [ ] Connect the existing local folder (it already holds `CLAUDE.md`, `.claude/` and this plan, so `git clone` into it would fail). `CLAUDE.md`, `.claude/` and `.mcp.json` are gitignored (local only), so only the plan is committed. Branch protection isn't on yet at this step, so a direct push to `main` is fine:
  ```bash
  cd ~/repos/data_engineering
  git init -b main
  git remote add origin https://github.com/<your-github-user>/data_engineering.git
  git fetch origin && git checkout -t origin/main
  git add study_plan.md && git commit -m "docs(plan): add study plan" && git push -u origin main
  ```
- [ ] `pyproject.toml`, **minimal and incremental**: runtime deps only numpy, pandas, pydantic; `dev` group only; `requires-python = ">=3.11,<3.13"`, ruff `target-version = "py311"`, `uv python pin 3.11` (Glue compatibility). Further deps are added with `make add ARGS='--group <dbt|aws|spark> …'` in the week that first needs them (see `docs/uv-dependencies.md`, which lists the expected additions). Keep **Airflow out of the root env** (its pinned constraints conflict); it lives in `airflow/`.
- [ ] `run.sh`: `install` = `uv sync --locked` (+ `pre-commit install` outside CI); `add`/`remove` wrap `uv add`/`uv remove`; tests run via `uv run`.
- [ ] Layout: `src/data_engineering/` (shared, unit-tested logic: pandas transforms, Lambda handlers, Glue/Spark transforms as pure functions), `docs/`, and `data/raw/` (gitignored) now. Create `dbt/`, `airflow/`, `glue/jobs/`, `spark/`, `lambdas/`, `stepfunctions/` and `infra/` in the week that first uses them (git doesn't track empty folders).
- [ ] `.gitignore` add: `data/`, `*.duckdb*`, `*.parquet`, `dbt/**/target/`, `dbt/**/dbt_packages/`, `dbt/**/logs/`, `airflow/logs/`, `airflow/airflow.db`, `airflow/airflow.cfg`, `airflow/*.generated`, `.terraform/`, `*.tfstate*`, `*.tfplan`, `.env` (do commit `.terraform.lock.hcl`).
- [ ] `.pre-commit-config.yaml`: **keep the `no-commit-to-branch` hook** (with the PR flow it guards local `main`; `make lint` passes on feature branches, and `lint:ci` skips it). Add now: `nbstripout`, `yamllint` (rules in `.yamllint.yaml`), and limit the `ty` hook to `^(src|tests)/` with `files:`. Add later: sqlfluff (`sqlfluff-lint` on `dbt/`) in the first dbt week; `terraform_fmt` + `terraform_validate` from `antonbabenko/pre-commit-terraform` (scoped to `infra/`) in week 20.
- [ ] **CI hardening** in `.github/workflows/ci.yaml`: delete the `dump-contexts-to-log` job (never echo secrets, even masked). Keep only the lint and test jobs; drop `check-version-tag` and `build-wheel`. Keep `release-on-main` as a placeholder for future CD (push to `main` only). PR trigger: `opened, synchronize`. Don't add `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` secrets; AWS access from CI uses OIDC (week 10).
- [ ] **Branch protection on `main`** (Settings → Branches): require a PR with 0 approvals; required status checks `Lint, Format, and other static code quality checks` + `Execute tests`, with "up to date" on; no force pushes or deletions; admin bypass allowed. Settings → General → Pull Requests: turn on "Automatically delete head branches".
- [ ] `make install && make lint && make test` green; commit on a branch, push, open a PR, and merge once CI is green.

*VS Code (0.5 h)*
- [ ] Install extensions per §5 (`.vscode/extensions.json` recommends them) and add the general settings. dbt/sqlfluff settings come in the dbt weeks; the `.code-workspace` file comes in week 11, with `airflow/`.

*Data + AWS guardrails (0.6 h)*
- [ ] Download 2024 yellow + green taxi Parquet (12 months) and `taxi_zone_lookup.csv` into `data/raw/` (TLC Trip Record Data page).
- [ ] AWS Budgets: alerts at $10/$25/$50 per month; enable Cost Anomaly Detection.

**Done when:** `make lint` and `make test` pass in CI on a PR and again on its merge to `main`; `aws sts get-caller-identity` works in WSL; `docker run hello-world` works without sudo.

---

## 7. Phase 1 — dbt with software engineering practices, on Redshift (Weeks 2–10) — priority #1

Start the **Snowflake 30-day trial on Week 2, day 1**: weeks 2–5 cover every Snowflake follow-along in the course.

### Week 2 — dbt foundations (~5.6 h)
**Lectures (~2.1 h)**
- [ ] [dbt S1 Course Introduction (9 min)](https://www.udemy.com/course/complete-dbt-data-build-tool-bootcamp-zero-to-hero-learn-dbt/learn/lecture/53307751)
- [ ] [dbt S2 Building the first version of our project (62 min)](https://www.udemy.com/course/complete-dbt-data-build-tool-bootcamp-zero-to-hero-learn-dbt/learn/lecture/31028410)
- [ ] [dbt S3 Models (16 min)](https://www.udemy.com/course/complete-dbt-data-build-tool-bootcamp-zero-to-hero-learn-dbt/learn/lecture/30983178)
- [ ] [dbt S4 Materializations (38 min)](https://www.udemy.com/course/complete-dbt-data-build-tool-bootcamp-zero-to-hero-learn-dbt/learn/lecture/31028512)

**Hands-on (~3.5 h)**
- [ ] Snowflake trial + key-pair auth; course project set up in `~/repos/dbt-course` (separate from the portfolio repo)
- [ ] Complete practice: `src_hosts` model and every materialization exercise
- [ ] Write a one-page `docs/dbt-notes.md` on view vs table vs incremental vs ephemeral: when to use each

### Week 3 — Seeds, snapshots, tests, macros, docs (~5.5 h)
**Lectures (~2.0 h)**
- [ ] [dbt S5 Seeds and Sources (15 min)](https://www.udemy.com/course/complete-dbt-data-build-tool-bootcamp-zero-to-hero-learn-dbt/learn/lecture/31028544)
- [ ] [dbt S6 Snapshots (16 min)](https://www.udemy.com/course/complete-dbt-data-build-tool-bootcamp-zero-to-hero-learn-dbt/learn/lecture/31028558)
- [ ] [dbt S7 Tests (21 min)](https://www.udemy.com/course/complete-dbt-data-build-tool-bootcamp-zero-to-hero-learn-dbt/learn/lecture/31028576)
- [ ] [dbt S8 Advanced Testing: Contracts and Custom Generic Tests (18 min)](https://www.udemy.com/course/complete-dbt-data-build-tool-bootcamp-zero-to-hero-learn-dbt/learn/lecture/52917789)
- [ ] [dbt S9 Jinja, Macros and Packages (26 min)](https://www.udemy.com/course/complete-dbt-data-build-tool-bootcamp-zero-to-hero-learn-dbt/learn/lecture/53011337)
- [ ] [dbt S10 Documentation (25 min)](https://www.udemy.com/course/complete-dbt-data-build-tool-bootcamp-zero-to-hero-learn-dbt/learn/lecture/31029042)

**Hands-on (~3.5 h)**
- [ ] All course practice exercises for S5–S10
- [ ] Write one custom generic test and one macro **of your own** in the course project

### Week 4 — Analyses, debugging, selectors; MP1 kickoff (~5.5 h)
**Lectures (~2.0 h)**
- [ ] [dbt S11 Analyses, Hooks and Exposures (33 min)](https://www.udemy.com/course/complete-dbt-data-build-tool-bootcamp-zero-to-hero-learn-dbt/learn/lecture/31029062)
- [ ] [dbt S13 Debugging Tests and Testing with dbt-expectations (48 min)](https://www.udemy.com/course/complete-dbt-data-build-tool-bootcamp-zero-to-hero-learn-dbt/learn/lecture/34783674)
- [ ] [dbt S14 Debugging with Logging (6 min)](https://www.udemy.com/course/complete-dbt-data-build-tool-bootcamp-zero-to-hero-learn-dbt/learn/lecture/42517238)
- [ ] [dbt S15 Debugging YAML, SQL, models (15 min)](https://www.udemy.com/course/complete-dbt-data-build-tool-bootcamp-zero-to-hero-learn-dbt/learn/lecture/55954485)
- [ ] [dbt S16 Tags and Selectors (15 min)](https://www.udemy.com/course/complete-dbt-data-build-tool-bootcamp-zero-to-hero-learn-dbt/learn/lecture/56019955)

**Hands-on (~3.5 h)**
- [ ] Course exercises for S11, S13, S16
- [ ] **MP1 kickoff (1 h):** sketch the layer design in `docs/mp01.md`; create an S3 dev bucket and upload the 2024 taxi Parquet + zone lookup (`aws s3 sync data/raw s3://<dev-bucket>/raw/`)

### Week 5 — Python models, variables, production patterns, Slim CI (~5.7 h)
**Lectures (~2.2 h)**
- [ ] [dbt S17 Python Models (13 min)](https://www.udemy.com/course/complete-dbt-data-build-tool-bootcamp-zero-to-hero-learn-dbt/learn/lecture/56022557)
- [ ] [dbt S18 Using Variables (16 min)](https://www.udemy.com/course/complete-dbt-data-build-tool-bootcamp-zero-to-hero-learn-dbt/learn/lecture/42516958)
- [ ] [dbt S19 Microbatching Incremental Models (9 min)](https://www.udemy.com/course/complete-dbt-data-build-tool-bootcamp-zero-to-hero-learn-dbt/learn/lecture/56050795)
- [ ] [dbt S20 Model Lifecycle: Versioning, Deprecating, Disabling (14 min)](https://www.udemy.com/course/complete-dbt-data-build-tool-bootcamp-zero-to-hero-learn-dbt/learn/lecture/56052923)
- [ ] [dbt S21 Preparing a Project for Slim CI (56 min)](https://www.udemy.com/course/complete-dbt-data-build-tool-bootcamp-zero-to-hero-learn-dbt/learn/lecture/56224230)
- [ ] [dbt S22 End-to-End Slim-CI-Based Production System (24 min)](https://www.udemy.com/course/complete-dbt-data-build-tool-bootcamp-zero-to-hero-learn-dbt/learn/lecture/56248051)

**Hands-on (~3.5 h)**
- [ ] Follow along S21–S22 on Snowflake with GitHub Actions: this is the **reference implementation for MP2**. Save the workflow files in `docs/reference/`
- [ ] Note in `docs/dbt-notes.md`: `--defer`, `--state`, `state:modified+`, `--retry`, custom schemas per environment

### Week 6 — Redshift foundations; MP1 setup (~5.9 h)
**Lectures (~2.0 h)**
- [ ] [AWSDA S24 Getting Started with Amazon Redshift (47 min)](https://www.udemy.com/course/data-engineering-using-aws-analytics-services/learn/lecture/28875660) — focus on Serverless; skim cluster sizing
- [ ] [AWSDA S25 Copy Data from S3 into Redshift Tables (48 min)](https://www.udemy.com/course/data-engineering-using-aws-analytics-services/learn/lecture/28875852)
- [ ] [dbt S27 Best Practices for Introducing dbt in your Company (22 min)](https://www.udemy.com/course/complete-dbt-data-build-tool-bootcamp-zero-to-hero-learn-dbt/learn/lecture/38780374)

**Hands-on (~3.9 h)**
- [ ] Start the **Redshift Serverless free trial** ($300 credit, 90 days, so it runs to about week 19): smallest base capacity, a daily RPU-hour **usage limit**, budget alert (1 h)
- [ ] IAM role for COPY/UNLOAD on your S3 dev bucket; `COPY` the 2024 taxi Parquet + zone lookup into a `raw` schema; check row counts (1.5 h)
- [ ] MP1 step 1: `dbt init nyc_taxi` in `dbt/` with **dbt-redshift** (IAM auth through your SSO profile: `method: iam`, `iam_profile`); sources on `raw`; `dbt debug` green (1.4 h)

### Week 7 — F1: dbt under the hood (~5.5 h)
Fundamentals lab: **plain dbt Core CLI only.** No VS Code dbt extension (close Power User for this week), no Cosmos. The goal is to know exactly what dbt does, so every tool built on top of it is transparent to you. Work in a small `dbt/f1_lab/` project (3–4 models on your `raw` tables).

**Lectures:** none. Use the dbt docs pages on [dbt commands](https://docs.getdbt.com/reference/dbt-commands), [artifacts](https://docs.getdbt.com/reference/artifacts/dbt-artifacts) and [programmatic invocations](https://docs.getdbt.com/reference/programmatic-invocations) as references.

**Hands-on (~5.5 h)**
- [ ] **Profiles by hand (0.5 h):** write `profiles.yml` yourself (no `dbt init` wizard) with `dev` and `prod` targets, credentials via `env_var()`; run `dbt debug` and read what it checks
- [ ] **The command lifecycle (1.5 h):** run `dbt parse`, `dbt compile`, `dbt run`, `dbt test`, `dbt build` one at a time. After each, look at what changed in `target/`: `compiled/` vs `run/` SQL (the second has the `CREATE TABLE AS` wrapper), `manifest.json`, `run_results.json`
- [ ] **What actually hits Redshift (0.5 h):** run with `--debug`, find a model's exact SQL in `logs/dbt.log`, then find the same query in `SYS_QUERY_HISTORY`
- [ ] **Node selection (0.5 h):** `dbt ls` with `--select model+`, `+model`, `tag:`, `path:`, `--exclude`; predict the output before running each
- [ ] **Jinja and macros (0.5 h):** write a macro, call it from a model and with `dbt run-operation`; compare the `.sql` you wrote with the compiled SQL
- [ ] **dbt from Python (1 h):** a script using `dbtRunner` (`from dbt.cli.main import dbtRunner`) that runs `build` for one selector and prints each node's status and timing from the result object
- [ ] **Read the DAG yourself (1 h):** a script that loads `target/manifest.json`, lists every model with its `depends_on` parents, and prints a valid run order (topological sort, e.g. with `graphlib`). This is the core of what Cosmos does in F2/MP4

**Done when:** `docs/f1-dbt-internals.md` explains, in your own words, what each command reads and writes, what's in `manifest.json` and `run_results.json`, and how your two scripts work.

### Week 8 — Redshift table design + Python access; MP1 part A (~6.0 h)
**Lectures (~2.5 h)**
- [ ] [AWSDA S26 Develop Applications using Redshift (61 min)](https://www.udemy.com/course/data-engineering-using-aws-analytics-services/learn/lecture/28971970) — Python → Redshift
- [ ] [AWSDA S27 Redshift Tables with Distkeys and Sortkeys (87 min)](https://www.udemy.com/course/data-engineering-using-aws-analytics-services/learn/lecture/28972308)

**Hands-on (~3.5 h)**
- [ ] MP1 steps 2–4 (3 h)
- [ ] Python access drill (30 min): run one query three ways (Redshift Data API via boto3, `redshift_connector`, `awswrangler`) and note in `docs/redshift-notes.md` when you'd use each

### Week 9 — MP1 part B (~5.5 h)
**Lectures:** none. Optional: [dbt S23 Fusion and the official VS Code extension (33 min)](https://www.udemy.com/course/complete-dbt-data-build-tool-bootcamp-zero-to-hero-learn-dbt/learn/lecture/52862961), [dbt S28 Certification Exam Prep (46 min)](https://www.udemy.com/course/complete-dbt-data-build-tool-bootcamp-zero-to-hero-learn-dbt/learn/lecture/56626633)

**Hands-on (~5.5 h)**
- [ ] MP1 steps 5–8; **Done when** met; merged to `main` via PR

### Week 10 — MP2 CI/CD on Redshift (~5.5 h)
**Hands-on (~5.5 h)**
- [ ] MP2 steps 1–6; **Done when** met
- [ ] Start `docs/dbt-at-work.md` (see "Applying dbt at work" below)

### MP1 — NYC Taxi analytics in dbt on Redshift Serverless
Goal: a project of your own design that uses everything from the course, on the same warehouse you use at work.
1. **Layers:** `staging/` (1 model per source: rename, cast only), `intermediate/` (trip enrichment, zone joins), `marts/` (`fct_trips`, `dim_zones`, `agg_daily_zone_revenue`). Folder-level configs and custom schemas.
2. **Sources + seeds:** `raw` tables loaded by COPY, with `freshness` on a load timestamp; zone lookup + a small `rate_card` seed.
3. **DRY:** ≥3 macros (money conversion, trip duration, `generate_schema_name` override). Install `dbt_project_evaluator` and fix all findings.
4. **Testing pyramid:** `unique`/`not_null` on all PKs; `relationships` to `dim_zones`; one custom generic test (`valid_trip_duration`); two singular tests; `dbt_expectations` range tests; ≥3 **unit tests** on fare/tip logic; **contracts** enforced on all marts.
5. **Redshift physical design:** `dist` and `sort` configs on `fct_trips` and `agg_daily_zone_revenue`; compare query time and `SYS_QUERY_HISTORY` stats before and after. Staging as late-binding views (`bind: false`).
6. **Incremental + history:** `fct_trips` incremental by pickup date (`merge` or `delete+insert`; `microbatch` if your dbt-redshift version supports it); **snapshot** on `rate_card` (edit the seed between runs to see SCD2).
7. **Refactor proof (your core work skill):** write one long query the way your DataCentral jobs look today (150+ lines, nested CTEs) that produces a feature table. Rebuild it as staging → intermediate → mart models and prove identical output with `audit_helper`'s `compare_queries`. (dbt-redshift has no Python models; Python lives in the orchestration tasks of Phase 2.)
8. **Docs:** descriptions on all mart columns, a `docs` block for business definitions, an **exposure** of type `ml` for the modeling dataset.

**Done when:** `dbt build` passes from a clean clone; `dbt_project_evaluator` reports 0 issues; `audit_helper` shows a 100% match for the refactored query; `docs/mp01.md` explains the layers and your dist/sort choices.

### MP2 — CI/CD and Git workflow for SQL on Redshift
Goal: the team-grade workflow you'd want for your SQL at work.
1. AWS: a GitHub **OIDC identity provider** and an IAM role trusted only by `repo:<you>/data_engineering:*`, allowed to get Redshift Serverless credentials and to read/write one S3 bucket `data-engineering-dbt-state-<acct>` (S3 bucket names can't contain underscores). The console is fine now; you'll import it into Terraform in week 23.
2. PR template and `CODEOWNERS` for `dbt/**/marts/` (practice for work). Branch protection and the PR flow already exist (Week 1). Add `dbt-ci.yml` as another required check once it's stable.
3. `.github/workflows/dbt-ci.yml` on PRs touching `dbt/**`: sqlfluff (dialect `redshift`) → assume role via `aws-actions/configure-aws-credentials` (OIDC) → download prod `manifest.json` from S3 → `dbt build --select state:modified+ --defer --state prod_state/` into a schema named `pr_<number>`. A `pr-cleanup.yml` workflow drops that schema when the PR closes (`dbt run-operation`).
4. CD on merge to `main` (fill in the `release-on-main` placeholder in `ci.yaml`, or a separate `.github/workflows/dbt-deploy.yml`): `dbt build --target prod` → upload `manifest.json` to S3 → `dbt docs generate` → publish to **GitHub Pages**.
5. Nightly scheduled workflow: `dbt source freshness`; on failure, open a GitHub issue via `gh issue create`.
6. All config via `env_var()` in `profiles.yml`; no secrets in the repo.

**Done when:** a PR changing one staging model builds and tests only that model and its children in its own `pr_` schema; merging publishes docs; closing the PR drops the schema.

### Applying dbt at work (checklist after week 10, not scheduled hours)
- [ ] Pick one real DataCentral job: list its inputs, outputs, consumers, and how often it breaks or needs edits
- [ ] Find out where dbt could run at work (your laptop against a dev schema, a team dev box, CI, or a scheduler your platform team supports) and whether you can get a Redshift dev schema
- [ ] Stepping stone if dbt can't run on a schedule yet: develop and test in dbt, then use the `dbt compile` output as the SQL your DataCentral job runs. DataCentral stays the scheduler, but your SQL becomes modular, reviewed and tested (tests run manually or in CI)
- [ ] Draft `docs/dbt-at-work.md`: the problem, a before/after of one job, the testing and CI story, and what you need from the platform team
- Keep work code, credentials and data out of this personal repo.

## 8. Phase 2 — Orchestration: Airflow + AWS Step Functions (Weeks 11–19) — priority #2

You'll build the pipeline you run at work, **SQL in Redshift → files in S3 → pandas features → modeling dataset in S3**, twice: first in **Airflow** (the most widely used orchestrator, a portable career skill), then in **Step Functions** (AWS-native and serverless, so easier to adopt at work). Same pipeline, two tools, so the comparison is concrete.

**Airflow setup: `airflow standalone`, no Docker, no Astro.** Airflow runs as a normal WSL process and reads `~/.aws` directly, so your SSO profile works as-is. The BDB course uses the Astro CLI; the DAG code is identical, so swap `astro dev start` for `airflow standalone` and skip the Astro Cloud deploy lectures. Course videos use Airflow 2.x; in Airflow 3, imports come from `airflow.sdk`, Datasets are now **Assets**, the UI is new, and only `schedule=` is accepted.

```bash
cd ~/repos/data_engineering/airflow
uv venv --python 3.12
AIRFLOW_VERSION=<latest 3.x>
uv pip install "apache-airflow[amazon]==${AIRFLOW_VERSION}" astronomer-cosmos pandas pyarrow pandera pytest \
  --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-3.12.txt"
export AIRFLOW_HOME=$PWD AWS_PROFILE=<your-sso-profile>
.venv/bin/airflow standalone    # UI at http://localhost:8080; login is printed in the terminal
```

`airflow standalone` is itself a convenience wrapper; in week 12 (F2) you take it apart and run each component yourself. Airflow and dbt never share an environment: Cosmos runs dbt from the root venv via `ExecutionConfig(dbt_executable_path="~/repos/data_engineering/.venv/bin/dbt")`.

### Week 11 — Airflow fundamentals (~5.5 h)
**Lectures (~2.5 h)**
- [ ] [BDB S28 Getting Started with Airflow (87 min)](https://www.udemy.com/course/big-data-engineering-bootcamp-with-gcp-and-azure-cloud/learn/lecture/48539815) — the course installs with Astro; you use standalone
- [ ] [Astronomer Academy](https://academy.astronomer.io/) (free account): Airflow 3 fundamentals module (~60 min)

**Hands-on (~3.0 h)**
- [ ] Install Airflow 3 standalone (above), log in, trigger an example DAG
- [ ] Rebuild the course DAGs (TaskFlow, math DAG) in `airflow/dags/`
- [ ] `airflow/tests/test_dag_integrity.py`: DagBag loads with no import errors, no cycles, `retries` + `owner` on every task; run with `airflow/.venv/bin/pytest`
- [ ] Note Airflow 2 → 3 differences you hit in `docs/airflow-notes.md`

### Week 12 — F2: Airflow from its parts; dbt in Airflow by hand (~6.0 h)
Fundamentals lab: **official Apache Airflow only, taken apart.** `airflow standalone` is itself a convenience: it starts every component in one process with a SQLite database and a generated login. This week you run the pieces yourself, then connect dbt to Airflow without Cosmos.

**Lectures:** none. Reference: the Airflow docs pages on [architecture](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/overview.html) and [executors](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/executor/index.html).

**Hands-on (~6.0 h)**
- [ ] **Components one by one (1.5 h):** stop standalone. Start Postgres (`docker run`), point `AIRFLOW__DATABASE__SQL_ALCHEMY_CONN` at it, set `AIRFLOW__CORE__EXECUTOR=LocalExecutor`, run `airflow db migrate`. Then start `airflow api-server`, `airflow scheduler`, `airflow dag-processor` and `airflow triggerer` in four terminals. Stop the scheduler mid-run and watch what happens; write down each component's job
- [ ] **Configuration (0.5 h):** find the same setting in `airflow.cfg`, as an `AIRFLOW__SECTION__KEY` environment variable, and in `airflow config list`; learn which one wins
- [ ] **Core building blocks without TaskFlow sugar (1.5 h):** one DAG using classic `BashOperator` and `PythonOperator` with explicit XCom push/pull, then the same DAG with `@task`; Jinja templating with `{{ ds }}` and `logical_date`; a connection defined via an `AIRFLOW_CONN_...` environment variable; a sensor in `poke` vs `reschedule` vs deferrable mode; test single tasks with `airflow tasks test` and whole DAGs with `airflow dags test`
- [ ] **The metadata database (0.5 h):** query Postgres directly: `dag_run`, `task_instance`, `xcom` tables. Find your last run's task states and durations with SQL
- [ ] **dbt in Airflow, manual way 1 (0.5 h):** one `BashOperator` running `dbt build` for your MP1 project; note what you can't see or retry per model
- [ ] **dbt in Airflow, manual way 2 (1.5 h):** extend your F1 manifest script into a DAG that creates **one `BashOperator` per model** (`dbt run --select <model>` plus `dbt test --select <model>`) and wires dependencies from `depends_on`. This is a mini Cosmos in ~50 lines
- [ ] *Optional:* run Airflow's official `docker-compose.yaml` once to see the CeleryExecutor setup (workers, Redis)

**Done when:** `docs/f2-airflow-internals.md` describes each component's role, which executor you ran and why, what lives in the metadata database, and the pros and cons of your two manual dbt integrations. Go back to `airflow standalone` for daily work afterwards.

### Week 13 — Course ETL project; MP3 start (~5.7 h)
**Lectures (~1.7 h)**
- [ ] [BDB S29 Airflow ETL Pipeline with Postgres and API (96 min)](https://www.udemy.com/course/big-data-engineering-bootcamp-with-gcp-and-azure-cloud/learn/lecture/58188513) — local only; run Postgres with `docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=dev postgres:16`
- [ ] CERT S9 [Amazon Managed Workflows for Apache Airflow](https://www.udemy.com/course/aws-data-engineer/learn/lecture/40394518) (~6 min)

**Hands-on (~4.0 h)**
- [ ] Course NASA APOD ETL running end to end (1.5 h)
- [ ] MP3 steps 1–2 (2.5 h)

### Week 14 — Airflow + Redshift; MP3 core (~5.7 h)
**Hands-on (~5.7 h)**
- [ ] [ULT S2 Batch processing of music streams using Airflow + Redshift (43 min)](https://www.udemy.com/course/ultimate-aws-data-engineering-bootcamp-with-real-world-labs/learn/lecture/45229171) — follow along on your Redshift Serverless + local Airflow; skip its MWAA setup (1.2 h)
- [ ] MP3 steps 3–5 (4.5 h)

### Week 15 — MP3 finish; MP4 start (~6.0 h)
**Hands-on (~6.0 h)**
- [ ] MP3 steps 6–7; **Done when** met (2.5 h)
- [ ] MP4 steps 1–2 (3.5 h)

### Week 16 — MP4 finish (~5.0 h)
**Hands-on (~5.0 h)**
- [ ] MP4 steps 3–8; **Done when** met
- [ ] *Optional:* [dbt S24 Orchestrating dbt with Dagster (60 min)](https://www.udemy.com/course/complete-dbt-data-build-tool-bootcamp-zero-to-hero-learn-dbt/learn/lecture/41980816) — the asset-centric alternative to Airflow

### Week 17 — Lambda + Step Functions foundations (~5.9 h)
**Lectures (~2.1 h)**
- [ ] [AWSDA S9 Data Ingestion using Lambda Functions (107 min)](https://www.udemy.com/course/data-engineering-using-aws-analytics-services/learn/lecture/28005884)
- [ ] CERT S9: [AWS Step Functions](https://www.udemy.com/course/aws-data-engineer/learn/lecture/40356686), [State Machines and States](https://www.udemy.com/course/aws-data-engineer/learn/lecture/41056828) (~20 min)

**Hands-on (~3.8 h)**
- [ ] **Fundamentals first (1.5 h):** write a small state machine **by hand** in Amazon States Language (JSON: `Task`, `Choice`, `Wait`, `Retry`/`Catch`) using the [ASL spec](https://states-language.net/); deploy and run it with only the AWS CLI (`create-state-machine`, `start-execution`, `get-execution-history`)
- [ ] [AWS Step Functions Workshop](https://catalog.workshops.aws/stepfunctions/) (free, self-paced): basics modules (1 h)
- [ ] Only now open Workflow Studio: a state machine that calls a Lambda using the **AWS SDK for pandas** managed layer to read a Parquet file from S3 and return its row count; compare the JSON it generates with your hand-written one (1.3 h)

### Week 18 — Step Functions with Redshift and ECS; MP5 core (~5.9 h)
**Lectures (~1.5 h)**
- [ ] CERT S9: [SQS](https://www.udemy.com/course/aws-data-engineer/learn/lecture/40305768), [SNS](https://www.udemy.com/course/aws-data-engineer/learn/lecture/40305820), [EventBridge](https://www.udemy.com/course/aws-data-engineer/learn/lecture/40305860) (~25 min)
- [ ] [ULT S4 ETL for Rental Apartments using Step Functions, Glue and Redshift (62 min)](https://www.udemy.com/course/ultimate-aws-data-engineering-bootcamp-with-real-world-labs/learn/lecture/45229251) — watch for the Step Functions + Redshift pattern; Glue comes in Phase 3b

**Hands-on (~4.4 h)**
- [ ] MP5 steps 1–4

### Week 19 — MP5 finish; Airflow vs Step Functions (~5.5 h)
**Lectures (~1.0 h)**
- [ ] [ULT S6 Event-driven pipelines for E-Commerce using ECS and Step Functions (61 min)](https://www.udemy.com/course/ultimate-aws-data-engineering-bootcamp-with-real-world-labs/learn/) — open section S6; the ECS task pattern you use for dbt in MP5

**Hands-on (~4.5 h)**
- [ ] MP5 steps 5–7; **Done when** met

### MP3 — Airflow ingestion DAG: S3 → Redshift
1. **Sensing:** a deferrable `HttpSensor` (HEAD request) waits for the month's TLC Parquet URL.
2. **Extract:** download to `s3://<dev-bucket>/raw/yellow/year=YYYY/month=MM/`; weather from the **Open-Meteo** historical API to S3.
3. **Load:** `S3ToRedshiftOperator` (COPY) into `raw`. Idempotent per month: delete that month's rows, then COPY, in one transaction.
4. **Fan-out:** dynamic task mapping over `["yellow", "green"]`.
5. **Resilience:** retries with exponential backoff; a pool capping downloads at 2; `on_failure_callback` → SNS email.
6. **Backfill + reconciliation:** `airflow backfill create` for 2024; a SQL check task comparing loaded row counts with each file's count.
7. **Tests:** DAG integrity + unit tests for helper functions (kept in `src/data_engineering/`), run in CI.

**Done when:** clearing any month and re-running it gives identical row counts in Redshift; tests run in CI.

### MP4 — Your work pipeline in Airflow: dbt → UNLOAD → pandas → modeling dataset
Today's DataCentral job + ML workflow, as one dependency-aware DAG.
1. **dbt:** now use Cosmos `DbtTaskGroup` (dbt-redshift, run from the root venv), so each model and test is its own task. Compare it with your F2 hand-built version: what does Cosmos add (profile mapping, test placement, caching) beyond your ~50 lines?
2. **Trigger:** schedule on the **Asset** MP3 emits when raw data lands, not on a cron.
3. **Extract:** `RedshiftDataOperator` runs `UNLOAD` of the mart that feeds your model (zone-hour demand) to `s3://<dev-bucket>/extracts/run_date=YYYY-MM-DD/` as Parquet.
4. **Features:** a pandas task reads the extract, builds lags, rolling means and weather joins, validates with **pandera**, and writes the modeling dataset to a separate `ml-datasets` bucket partitioned by run date, the same contract your work ML pipeline consumes.
5. **Quality gate:** a failing dbt test or pandera check stops everything downstream; SNS alert on failure.
6. **Backfill:** rerun 3 past dates and confirm each writes only its own partition.
7. **Write-up** in `docs/mp04.md`: this DAG vs your current DataCentral setup (handoff, retries, backfills, alerting, lineage); Cosmos task-per-model vs a single `dbt build` task.
8. **CI:** `.github/workflows/airflow-ci.yml` on PRs touching `airflow/**`: ruff + DAG tests.

**Done when:** one DAG run goes raw → tested marts → UNLOAD → modeling dataset in S3, and a deliberately failing dbt test stops the pandas step.

### MP5 — The same pipeline in AWS Step Functions
Same inputs and outputs as MP4, AWS-native and serverless. Build it in Workflow Studio, export the definition to `stepfunctions/work_pipeline.asl.json`, and deploy with the AWS CLI (`aws stepfunctions update-state-machine`). The state machine, Lambda, ECS task and roles move into Terraform in week 23.
1. **Trigger:** EventBridge Scheduler (daily), passing `run_date` as input.
2. **dbt:** an ECS Fargate task (`ecs:runTask.sync`) running `dbt build --target prod` from a small dbt-redshift Docker image you push to ECR.
3. **Extract:** `redshift-data:ExecuteStatement` runs the UNLOAD, then a `Wait` → `DescribeStatement` → `Choice` loop until it finishes (the Data API has no `.sync` integration).
4. **Features:** a Lambda with the AWS SDK for pandas layer runs the same feature function as MP4 (shared code from `src/data_engineering/`). Note Lambda's limits (15 minutes, 10 GB memory); for larger data, the same code runs as a Fargate task.
5. **Errors:** `Retry` with backoff on every Task; `Catch` → SNS failure email with the execution ARN; SNS success message.
6. **Test:** the TestState API on the polling loop; an execution for a past `run_date` (a one-day backfill); an injected UNLOAD failure.
7. **Write-up** in `docs/mp05.md`: Airflow vs Step Functions for this pipeline (cost when idle, local dev, retries, backfills, observability, dbt integration) and which you'd propose at work.

**Done when:** one execution produces the same modeling dataset as MP4 for the same `run_date` (row counts match), and an injected UNLOAD failure retries, then sends a failure email.

---

## 9. Phase 3a — Terraform foundations (Weeks 20–23)

Learn Terraform properly before using it for the lake. Experiment in `infra/sandbox/` (throwaway), then build what you keep in `infra/modules/` + `infra/envs/dev/`.

**Course notes**
- Do the **✅ Hands-On Lab** videos as labs: attempt first, watch the solution only if stuck. They count as hands-on time below.
- The **☁️ Codespaces labs** run in GitHub Codespaces (free monthly quota on personal accounts), or clone the lab repo into WSL.
- Use your **SSO profile**, never access keys: `provider "aws" { region = var.region }` with `export AWS_PROFILE=<your-sso-profile>`.

### Week 20 — Terraform intro, state, workflow, CLI (~5.8 h)
**Lectures (~2.0 h)**
- [ ] TF S2: [Introduction to Terraform (18 min)](https://www.udemy.com/course/terraform-for-beginners-with-labs/learn/lecture/46658983), [Core Components and Benefits (22 min)](https://www.udemy.com/course/terraform-for-beginners-with-labs/learn/lecture/48247977), [Basics of HashiCorp Terraform (33 min)](https://www.udemy.com/course/terraform-for-beginners-with-labs/learn/lecture/46658985) — skip the two OpenTofu lectures
- [ ] [TF S4 File Structure and Organization (12 min)](https://www.udemy.com/course/terraform-for-beginners-with-labs/learn/lecture/46858837)
- [ ] [TF S5 Understanding Terraform State (11 min)](https://www.udemy.com/course/terraform-for-beginners-with-labs/learn/lecture/48717953)
- [ ] [TF S6 Terraform Workflow (25 min)](https://www.udemy.com/course/terraform-for-beginners-with-labs/learn/lecture/46860239)

**Hands-on (~3.8 h)**
- [ ] [TF S7 Terraform CLI (51 min)](https://www.udemy.com/course/terraform-for-beginners-with-labs/learn/lecture/46858863) — follow along in WSL
- [ ] `infra/sandbox/`: AWS provider via SSO profile, one tagged S3 bucket → `init`, `plan`, `apply`, inspect state, `destroy`
- [ ] Bootstrap a state bucket (`data-engineering-tfstate-<acct>`, versioning on) and move the sandbox to an S3 backend with `use_lockfile = true`; try `terraform state list` / `state show`

### Week 21 — Block types and first configurations (~5.9 h)
**Lectures (~2.5 h)**
- [ ] [TF S8 Terraform Block Types (135 min)](https://www.udemy.com/course/terraform-for-beginners-with-labs/learn/lecture/46858843)
- [ ] [TF S10 Using Terraform Documentation (14 min)](https://www.udemy.com/course/terraform-for-beginners-with-labs/learn/lecture/46819371)

**Hands-on (~3.4 h)**
- [ ] [TF S9 Writing Your First Terraform Configurations (101 min)](https://www.udemy.com/course/terraform-for-beginners-with-labs/learn/lecture/46860259) — follow along
- [ ] Sandbox exercise: `variables.tf` with types + `validation`, `outputs.tf`, data sources (`aws_caller_identity`, `aws_iam_policy_document`) for an IAM role a Lambda could assume

### Week 22 — Making code reusable (~5.8 h)
**Lectures (~2.0 h)**
- [ ] [TF S11 part 1: why reusability, dynamic blocks, locals](https://www.udemy.com/course/terraform-for-beginners-with-labs/learn/lecture/48814171) — concept + demo lectures
- [ ] [TF S11 part 2: meta-arguments (count, for_each, depends_on, provider, lifecycle), built-in functions](https://www.udemy.com/course/terraform-for-beginners-with-labs/learn/lecture/48707455) — concept + demo lectures

**Hands-on (~3.8 h)**
- [ ] S11 hands-on labs (dynamic blocks, locals, for_each) and Codespaces labs #10–13
- [ ] Sandbox refactor: `locals` for naming + tags; `for_each` over `raw`/`clean`/`curated` buckets; `lifecycle { prevent_destroy = true }` on the state bucket; `jsonencode()` / `templatefile()` for a policy

### Week 23 — Modules, import, maintenance (~6.0 h)
**Lectures (~2.6 h)**
- [ ] [TF S12 Introduction to Modules](https://www.udemy.com/course/terraform-for-beginners-with-labs/learn/lecture/48953575) — concept lectures (~75 min)
- [ ] [TF S13 Managing and Maintaining Your Terraform Code (82 min)](https://www.udemy.com/course/terraform-for-beginners-with-labs/learn/lecture/48718551) — replace, upgrades, import

**Hands-on (~3.4 h)**
- [ ] S12 hands-on labs (registry module, writing your own module)
- [ ] Write `infra/modules/s3_lake_bucket` (SSE-KMS, public access block, lifecycle, versioning, tags) with variables, outputs and a README; call it from `infra/envs/dev/`
- [ ] **Import** the MP2 console-made GitHub OIDC provider + IAM role with `import` blocks; `terraform plan` shows **no changes**. Then import the MP5 resources (state machine, Lambda, ECS task definition, EventBridge schedule, IAM roles) the same way
- [ ] Add `.github/workflows/infra-ci.yml`: `fmt -check`, `validate`, `plan` via OIDC on PRs touching `infra/**`
- [ ] *Optional:* [TF S14 Additional Labs (21 min)](https://www.udemy.com/course/terraform-for-beginners-with-labs/learn/lecture/57006017)

**Done when:** `infra/envs/dev` uses your module, the OIDC role and MP5 resources are managed by Terraform with a clean plan, and infra CI runs on PRs.

---

## 10. Phase 3b — AWS lake: Glue, Catalog, Crawler, Athena, Step Functions (Weeks 24–33)

### Week 24 — S3, IAM; lake infrastructure (~5.5 h)
**Lectures (~2.0 h)**
- [ ] [AWSDA S5 Deep Dive into S3 (60 min)](https://www.udemy.com/course/data-engineering-using-aws-analytics-services/learn/lecture/28075458)
- [ ] [AWSDA S6 AWS Security using IAM (59 min)](https://www.udemy.com/course/data-engineering-using-aws-analytics-services/learn/lecture/28075510) — map concepts to your Identity Center setup

**Hands-on (~3.5 h)**
- [ ] MP6 step 1

### Week 25 — Lambda ingestion (~5.0 h)
**Lectures:** none (you covered Lambda, AWSDA S9, in week 17)

**Hands-on (~5.0 h)**
- [ ] MP6 step 2

### Week 26 — Glue components + Catalog (~5.3 h)
**Lectures (~1.8 h)**
- [ ] [AWSDA S11 Overview of Glue Components (53 min)](https://www.udemy.com/course/data-engineering-using-aws-analytics-services/learn/lecture/28005798)
- [ ] [AWSDA S13 Deep Dive into Glue Catalog (57 min)](https://www.udemy.com/course/data-engineering-using-aws-analytics-services/learn/lecture/28005836)

**Hands-on (~3.5 h)**
- [ ] MP6 steps 3–4

### Week 27 — Athena deep dive (~5.6 h)
**Lectures (~2.1 h)**
- [ ] [AWSDA S21 Overview of Amazon Athena (65 min)](https://www.udemy.com/course/data-engineering-using-aws-analytics-services/learn/lecture/28788868)
- [ ] [AWSDA S23 Athena using Python boto3 (38 min)](https://www.udemy.com/course/data-engineering-using-aws-analytics-services/learn/lecture/28788932)
- [ ] CERT S8: [Athena Performance](https://www.udemy.com/course/aws-data-engineer/learn/lecture/40356366), [Athena and CTAS](https://www.udemy.com/course/aws-data-engineer/learn/lecture/41056808), [Apache Iceberg and Athena/EMR/Glue](https://www.udemy.com/course/aws-data-engineer/learn/lecture/49075315) (~25 min)

**Hands-on (~3.5 h)**
- [ ] MP6 steps 5–6; **Done when** met

### Week 28 — PySpark/Glue dev lifecycle (~5.5 h)
**Lectures (~2.0 h)**
- [ ] [AWSDA S10 Development Lifecycle for PySpark (68 min)](https://www.udemy.com/course/data-engineering-using-aws-analytics-services/learn/lecture/28005766)
- [ ] [AWSDA S12 Setup Spark History Server for Glue Jobs (23 min)](https://www.udemy.com/course/data-engineering-using-aws-analytics-services/learn/lecture/28005822)
- [ ] CERT S8: [AWS Glue](https://www.udemy.com/course/aws-data-engineer/learn/lecture/40356180), [Glue, Hive, and ETL](https://www.udemy.com/course/aws-data-engineer/learn/lecture/40356198), [Glue Costs and Anti-Patterns](https://www.udemy.com/course/aws-data-engineer/learn/lecture/40356238), [Glue Studio](https://www.udemy.com/course/aws-data-engineer/learn/lecture/40356256) (~30 min)

**Hands-on (~3.5 h)**
- [ ] MP7 steps 1–2

### Week 29 — Glue APIs, bookmarks, quality, workflows (~5.5 h)
**Lectures (~1.5 h)**
- [ ] [AWSDA S14 Exploring Glue Job APIs (30 min)](https://www.udemy.com/course/data-engineering-using-aws-analytics-services/learn/lecture/28005854)
- [ ] [AWSDA S15 Glue Job Bookmarks (35 min)](https://www.udemy.com/course/data-engineering-using-aws-analytics-services/learn/lecture/28005864)
- [ ] CERT S8: [Glue Data Quality](https://www.udemy.com/course/aws-data-engineer/learn/lecture/40356286), [Glue Flex Jobs](https://www.udemy.com/course/aws-data-engineer/learn/lecture/54600683), [Glue Workflows](https://www.udemy.com/course/aws-data-engineer/learn/lecture/41056796) (~25 min)

**Hands-on (~4.0 h)**
- [ ] MP7 steps 3–6

### Week 30 — Redshift Spectrum; MP7 deploy; MP8 start (~5.7 h)
**Lectures (~1.7 h)**
- [ ] [AWSDA S28 Redshift Federated Queries and Spectrum (104 min)](https://www.udemy.com/course/data-engineering-using-aws-analytics-services/learn/lecture/28972670) — query your S3 lake from Redshift; directly useful at work

**Hands-on (~4.0 h)**
- [ ] MP7 steps 7–8; **Done when** met (1.5 h)
- [ ] MP8 steps 1–2 (2.5 h)

### Week 31 — CI/CD for AWS; MP8 (~6.0 h)
**Lectures (~1.0 h)**
- [ ] [ULT S10 CI/CD for AWS Services using GitHub Actions (51 min)](https://www.udemy.com/course/ultimate-aws-data-engineering-bootcamp-with-real-world-labs/learn/lecture/45229583)
- [ ] [ULT S16 Assignment 5: Automate deployment of Lambda functions (7 min)](https://www.udemy.com/course/ultimate-aws-data-engineering-bootcamp-with-real-world-labs/learn/lecture/45229703)

**Hands-on (~5.0 h)**
- [ ] MP8 steps 3–7; **Done when** met

### Week 32 — dbt on the lake (~5.3 h)
**Lectures (~0.3 h)**
- [ ] CERT S8: [AWS Lake Formation](https://www.udemy.com/course/aws-data-engineer/learn/lecture/40356330) (~15 min) — optional

**Hands-on (~5.0 h)**
- [ ] MP9 steps 1–2

### Week 33 — End-to-end orchestration (~5.0 h)
**Hands-on (~5.0 h)**
- [ ] MP9 steps 3–4; **Done when** met
- [ ] Phase retro in `docs/phase3-retro.md`: what each AWS service is for, monthly cost so far

### MP6 — Partitioned S3 lake with Crawler, Catalog and Athena
1. **Terraform** (`infra/envs/dev`, reusing your week-23 `s3_lake_bucket` module): remote state in S3 with native S3 locking (`use_lockfile = true`, no DynamoDB table needed); AWS provider `default_tags`; buckets `raw/clean/curated` (SSE-KMS, block public access, lifecycle to IA after 30 days); least-privilege roles for Lambda, Glue, Step Functions; extend the **GitHub OIDC role** (imported in week 23) with the permissions CI now needs; Athena workgroup with a 1 GB per-query scan limit; default tags.
2. **Ingest:** Lambda (code in `lambdas/`, logic in `src/`) on an EventBridge schedule downloads a month into `raw/yellow/year=/month=/`; backfill 2024.
3. **Crawl:** Glue Crawler on `raw/`; TLC files change column types across months — inspect how the crawler handles drift and fix it (crawler schema-change policy or an explicit table).
4. **Query:** 5 business questions in Athena (top zones by revenue, tip % by hour, airport share, etc.); record bytes scanned.
5. **Optimize:** CTAS to Snappy Parquet partitioned by month → switch to **partition projection** and remove the crawler from the path. Before/after table of bytes scanned and $ in `docs/mp06.md`.
6. *Stretch:* Lake Formation column-level grant hiding fare columns from an analyst role.

**Done when:** all 5 queries scan ≥80% fewer bytes after optimization; `terraform destroy` + `terraform apply` rebuilds everything; infra CI (from week 23) passes.

### MP7 — Glue ETL job and Glue Workflow
1. Glue PySpark job `glue/jobs/raw_to_curated.py` (thin wrapper; transforms in `src/data_engineering/spark/`): read via Catalog as DynamicFrame → DataFrame logic mirroring MP3 rules → dedupe.
2. Develop + `pytest` locally in the **Glue 5 Docker image** (WSL2: mount the repo and `~/.aws`).
3. **Job bookmarks:** prove incrementality by adding a month and checking the run's input.
4. **Glue Data Quality** (DQDL ruleset): fail on null-rate / row-count breaches.
5. Write **Iceberg** to `curated/`, registered in the Catalog.
6. **Glue Workflow:** crawler → job → validation job with conditional triggers.
7. `.github/workflows/glue-deploy.yml`: OIDC → upload script to S3 → `terraform apply` job definition.
8. Record DPU-hours per run; compare standard vs **Flex** execution.

**Done when:** a new raw month reaches curated Iceberg through the Workflow with no manual step; a deliberately broken file fails the quality gate.

### MP8 — Step Functions part 2: orchestrating Glue and Athena
MP5 built a Step Functions pipeline around Redshift; this one adds Glue's `.sync` jobs, crawler polling, Athena and `Map`.
1. EventBridge schedule → Lambda "is a new month available?" → `Choice`.
2. Glue job via `startJobRun.sync`.
3. Glue Crawler via start → `Wait` → poll loop (no `.sync` for crawlers). (Or skip the crawler entirely if MP6 moved you to projection.)
4. Athena `startQueryExecution.sync` reconciling raw vs curated counts.
5. `Map` over vehicle types; `Retry` with backoff + `Catch` on every task; SNS on success/failure.
6. ASL in `stepfunctions/`, deployed with Terraform (`aws_sfn_state_machine` with `templatefile()` for ARNs); test single states with the **TestState API**; author/visualize with AWS Toolkit Workflow Studio.
7. `docs/mp08.md`: Step Functions vs Glue Workflows vs Airflow — cost, observability, retries, local dev, cross-service reach.

**Done when:** an injected Glue failure is caught, retried twice, and sends a failure email with the execution link.

### MP9 — dbt on the lake, orchestrated end to end
1. Add a `dbt-athena` target to MP1; Iceberg tables with `incremental_strategy='merge'` over curated data.
2. Re-point MP2 CI to Athena: PR builds into a per-PR Glue database; drop it on PR close.
3. Airflow DAG (local `airflow standalone`, SSO profile): start the MP8 state machine (`StepFunctionStartExecutionOperator`) → sensor waits → Cosmos runs dbt-athena.
4. *Optional:* deploy to **MWAA for one 2–3 h session**, then delete it (ask Claude for a cost estimate first).

**Done when:** one Airflow run goes from a new raw file to tested dbt marts in Athena; dbt docs show full lineage.

---

## 11. Phase 4 — PySpark and distributed processing (Weeks 34–41)

Local Spark in WSL2: Java 17 + `pyspark` 3.5.x from the `spark` group; JupyterLab via `uv run jupyter lab`. Spark UI at `localhost:4040`.

### Week 34 — Spark architecture; MP10 baseline (~5.2 h)
**Lectures (~1.7 h)**
- [ ] [DEE S19 Overview of Big Data and Data Lakes (42 min)](https://www.udemy.com/course/data-engineering-essentials-sql-python-and-spark/learn/lecture/37006722)
- [ ] [DEE S20 Overview of Spark and Spark Architecture (60 min)](https://www.udemy.com/course/data-engineering-essentials-sql-python-and-spark/learn/lecture/37006788)

**Hands-on (~3.5 h)**
- [ ] Local Spark working; `spark.sql("select 1")` in Jupyter (0.5 h)
- [ ] Download 2023 taxi data (2023–2024 ≈ 80M rows)
- [ ] MP10 step 1 for 1 and 6 months (3 h)

### Week 35 — DataFrame APIs (~5.8 h)
**Lectures (~2.3 h)**
- [ ] [DEE S33 Getting Started with PySpark DataFrame APIs (28 min)](https://www.udemy.com/course/data-engineering-essentials-sql-python-and-spark/learn/lecture/37025562)
- [ ] [DEE S34 Create Spark DataFrames (46 min)](https://www.udemy.com/course/data-engineering-essentials-sql-python-and-spark/learn/lecture/37025592)
- [ ] [DEE S35 Basic Transformations (64 min)](https://www.udemy.com/course/data-engineering-essentials-sql-python-and-spark/learn/lecture/37025640)

**Hands-on (~3.5 h)**
- [ ] MP10 step 1 at 24 months; step 2

### Week 36 — Joins, windows, Catalyst (~5.9 h)
**Lectures (~2.4 h)**
- [ ] [DEE S36 Joining Data (41 min)](https://www.udemy.com/course/data-engineering-essentials-sql-python-and-spark/learn/lecture/37025776)
- [ ] [DEE S37 Ranking with DataFrame APIs (33 min)](https://www.udemy.com/course/data-engineering-essentials-sql-python-and-spark/learn/lecture/37025844)
- [ ] [DEE S38 Integration of Spark SQL and DataFrame APIs (30 min)](https://www.udemy.com/course/data-engineering-essentials-sql-python-and-spark/learn/lecture/37025894)
- [ ] [DEE S40 Performance Tuning: Catalyst Optimizer (39 min)](https://www.udemy.com/course/data-engineering-essentials-sql-python-and-spark/learn/lecture/37025972)

**Hands-on (~3.5 h)**
- [ ] MP10 step 3, experiments A–C

### Week 37 — Cluster config, file formats, partitioning (~5.9 h)
**Lectures (~2.6 h)**
- [ ] [DEE S41 Performance Tuning: Cluster Configuration (43 min)](https://www.udemy.com/course/data-engineering-essentials-sql-python-and-spark/learn/lecture/37025990)
- [ ] [DEE S42 Inferring Schema from CSV/JSON (21 min)](https://www.udemy.com/course/data-engineering-essentials-sql-python-and-spark/learn/lecture/37026000)
- [ ] [DEE S43 Columnar File Format and Partitioning Strategy (94 min)](https://www.udemy.com/course/data-engineering-essentials-sql-python-and-spark/learn/lecture/37026014)

**Hands-on (~3.3 h)**
- [ ] MP10 step 3, experiments D–F; step 4; **Done when** met

### Week 38 — EMR (~5.8 h)
**Lectures (~2.0 h)**
- [ ] [AWSDA S16 Getting Started with AWS EMR (48 min)](https://www.udemy.com/course/data-engineering-using-aws-analytics-services/learn/lecture/28247048)
- [ ] CERT S8: [Amazon EMR](https://www.udemy.com/course/aws-data-engineer/learn/lecture/40356512), [EMR, AWS Integration, and Storage](https://www.udemy.com/course/aws-data-engineer/learn/lecture/40356520), [EMR Serverless, EMR on EKS](https://www.udemy.com/course/aws-data-engineer/learn/lecture/40356558) (~30 min)
- [ ] [ULT S5 Data lake for rental vehicles using EMR, S3 and Athena (44 min)](https://www.udemy.com/course/ultimate-aws-data-engineering-bootcamp-with-real-world-labs/learn/lecture/45229303)

**Hands-on (~3.8 h)**
- [ ] MP11 steps 1–2

### Week 39 — Deploying Spark apps (~5.5 h)
**Lectures (~1.5 h)**
- [ ] [AWSDA S17 Deploying Spark Applications using EMR (98 min)](https://www.udemy.com/course/data-engineering-using-aws-analytics-services/learn/lecture/29190476) — 1.5× speed, focus on spark-submit and steps
- [ ] [ULT S3 Distributed music streams processing using Airflow, Spark and DynamoDB (32 min)](https://www.udemy.com/course/ultimate-aws-data-engineering-bootcamp-with-real-world-labs/learn/lecture/45229225)

**Hands-on (~4.0 h)**
- [ ] MP11 steps 3–6; **Done when** met

### Week 40 — Spark MLlib (~5.9 h)
**Lectures (~1.9 h)**
- [ ] [PYS S11 Linear Regression (60 min)](https://www.udemy.com/course/spark-and-python-for-big-data-with-pyspark/learn/lecture/6666724)
- [ ] [PYS S13 Decision Trees and Random Forests (52 min)](https://www.udemy.com/course/spark-and-python-for-big-data-with-pyspark/learn/lecture/6666728)

**Hands-on (~4.0 h)**
- [ ] MP12 steps 1–2

### Week 41 — Per-zone models (~5.0 h)
**Lectures:** optional [ULT S7 PySpark Delta lakehouse (32 min)](https://www.udemy.com/course/ultimate-aws-data-engineering-bootcamp-with-real-world-labs/learn/lecture/45229425)

**Hands-on (~5.0 h)**
- [ ] MP12 steps 3–4; **Done when** met

### MP10 — When does pandas stop scaling? (local)
1. Same pipeline (clean → join zones → hourly revenue by zone → top routes with window functions) in **pandas, DuckDB, PySpark**. Record wall time + peak memory at 1, 6, 24 months; note where pandas fails.
2. `explain(mode="formatted")` for each Spark query; annotate scans, pushed filters, exchanges, join strategy.
3. Controlled experiments, one change at a time, with Spark UI evidence:
   - A. AQE on vs off
   - B. 200 shuffle partitions vs tuned
   - C. broadcast join of zones vs sort-merge
   - D. skew (airport zones): salting vs AQE skew-join
   - E. cache vs no cache for a reused DataFrame
   - F. small files: write 10,000 tiny files → read time → compact; partition by month vs day
4. Results table + screenshots in `docs/mp10.md`.

**Done when:** for each change you can point at the Spark UI stage it affected and explain why.

### MP11 — Same Spark job on EMR Serverless and Glue
1. Package MP10 as a `spark-submit` app (`spark/apps/`): zipped venv for deps, args for config, structured logging.
2. Run on **EMR Serverless** (Terraform `aws_emrserverless_application`, auto-stop on) against MP7's curated Iceberg; write Iceberg results; query in Athena.
3. Run the same code as a **Glue** job; list what had to change.
4. Compare startup, runtime, $/run, debugging (EMR persistent Spark UI vs Glue Spark History Server).
5. Orchestrate both: Step Functions EMR Serverless `.sync` state + Airflow `EmrServerlessStartJobOperator`.
6. *Optional:* one EMR-on-EC2 cluster with Spot task nodes and 1-hour idle auto-termination, to see YARN (ask Claude for a cost estimate first).

**Done when:** `docs/mp11.md` has a decision table (EMR Serverless vs Glue vs EMR on EC2) with your measured numbers.

### MP12 — Distributed feature engineering and modeling
1. Zone-hour demand features over 2 years in Spark: lags, rolling windows, Open-Meteo weather, holiday flags.
2. MLlib `Pipeline` + `GBTRegressor`, time-based split.
3. One model per zone in parallel with `groupBy("zone").applyInPandas(...)` (scikit-learn inside).
4. Compare accuracy + training time vs single-machine scikit-learn on a sample.

**Done when:** ~260 per-zone models train in one Spark job; metrics land in an Iceberg table queryable from Athena.

---

## 12. Phase 5 — Capstone on a new dataset (Weeks 42–45)

Rebuild the full stack on data you haven't touched: **Citi Bike trip history + live GBFS station status**, or a public dataset from your own industry (doubles as a work pitch). No course videos.

### Week 42 — Design + ingest (~6 h)
- [ ] Architecture diagram (Mermaid in README) + design doc: sources, layers, SLAs, cost target
- [ ] Terraform: buckets, roles, schedules
- [ ] Lambda ingest of history + GBFS snapshots every 5 min (EventBridge)

### Week 43 — Process at scale (~6 h)
- [ ] Spark job (EMR Serverless or Glue) → Iceberg, Glue Data Quality gates, Catalog registration
- [ ] Unit tests for transforms in `src/`

### Week 44 — Model + orchestrate (~6 h)
- [ ] dbt-athena: staging/intermediate/marts, contracts, unit tests, incremental Iceberg
- [ ] Airflow owns the schedule; calls Step Functions for ingest/process; Cosmos for dbt; alerts on failure

### Week 45 — Serve + ship (~6 h)
- [ ] Feature job + forecasting model (station empty/full risk); results in Athena; small Streamlit view (local)
- [ ] README: architecture, cost-per-run table, 3 design decisions you'd defend
- [ ] 10-minute recorded walkthrough or blog post

**Non-negotiables:** all infra in Terraform (`destroy`/`apply` from scratch works) · CI on every PR (ruff, ty, pytest, DAG tests, Slim CI dbt) + CD on merge via OIDC · idempotent, backfillable runs · failure alerts.

*Stretch:* streaming path from ULT S8/S11 (Kinesis Data Firehose → Iceberg).

### Week 46 — Buffer
- [ ] Catch up on anything slipped, **or** AWS Certified Data Engineer Associate prep: CERT S16 practice exams ([exam 1](https://www.udemy.com/course/aws-data-engineer/learn/quiz/6238944), [exam 2](https://www.udemy.com/course/aws-data-engineer/learn/quiz/7438317)) + [S17 wrap-up](https://www.udemy.com/course/aws-data-engineer/learn/lecture/40332324)

---

## 13. Learning log

Claude appends one line per completed task or session. Format:
`YYYY-MM-DD · Week N · what I did · what broke / what I learned · next`

<!-- log entries below -->

---

## 14. Weekly rhythm and rules of thumb

- **Weekdays (3 × ~40 min):** lectures at 1.25–1.5×, typing every command; no downloading solution code.
- **Weekend (one ~3.5–4 h block):** mini-project work, then 15 min updating `docs/mpNN.md`.
- **Friday (10 min):** AWS cost check (Cost Explorer, tag `project=de-study-plan`) and teardown of anything idle.
- If a week slips: drop optional lectures first, never the mini-project. Use Week 46 as the buffer.
- Every mini-project ends with: merged to `main` via PR with CI green, `docs/mpNN.md` written, tracker updated, log entry added.
