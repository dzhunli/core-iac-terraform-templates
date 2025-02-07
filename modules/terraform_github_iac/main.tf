terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 6.5.0"
    }
  }
}

provider "github" {
  token = var.github_token
  
}

resource "github_repository" "iac_repo" {
  name        = var.repo_name
  description = "Infrastructure as Code repository"
  visibility  = "public"
  has_issues  = false
  has_wiki    = false
  has_projects = false
  auto_init   = true
  vulnerability_alerts = true
  archive_on_destroy   = true
  allow_auto_merge            = false
  allow_merge_commit          = true
  allow_rebase_merge          = true
  allow_squash_merge          = true
  delete_branch_on_merge      = false
  merge_commit_message        = "PR_TITLE"
  merge_commit_title          = "MERGE_MESSAGE"
  squash_merge_commit_message = "COMMIT_MESSAGES"
  squash_merge_commit_title   = "COMMIT_OR_PR_TITLE"
  web_commit_signoff_required = false
  gitignore_template          = "Terraform"
}

resource "github_branch" "main" {
  repository = github_repository.iac_repo.name
  branch     = "main"
}

resource "github_branch_protection" "main_protection" {
  repository_id = github_repository.iac_repo.node_id
  pattern       = "main"
  enforce_admins = true
}

resource "github_actions_secret" "secrets" {
  for_each    = var.secrets
  repository  = github_repository.iac_repo.name
  secret_name = each.key
  plaintext_value = each.value
}
resource "time_sleep" "wait_for_repo" {
  depends_on = [github_repository.iac_repo]
  create_duration = "10s"  
}
resource "github_repository_file" "tflint_conf" {
  depends_on = [time_sleep.wait_for_repo]
  repository          = github_repository.iac_repo.name
  file               = "ci-conf/.tflint.hcl"
  content     = templatefile("${path.module}/tflint.tpl", {})
  commit_message      = "init lint config"
  overwrite_on_create = true
}
resource "github_repository_file" "changelog_conf" {
  depends_on = [time_sleep.wait_for_repo]
  repository          = github_repository.iac_repo.name
  file               = "ci-conf/changelog.yaml"
  content     = file("${path.module}/changelog.tpl")
  commit_message      = "init changelog config"
  overwrite_on_create = true
}
resource "github_repository_file" "workflow" {
  depends_on = [time_sleep.wait_for_repo]
  repository          = github_repository.iac_repo.name
  file               = ".github/workflows/lint.yml"
  content     = file("${path.module}/workflow_lint.tpl")
  commit_message      = "init lint workflow"
  overwrite_on_create = true
}
resource "github_repository_file" "generate_release" {
  depends_on = [time_sleep.wait_for_repo]
  repository          = github_repository.iac_repo.name
  file               = ".github/workflows/release.yml"
  content     = file("${path.module}/workflow_release.tpl")
  commit_message      = "init lint config"
  overwrite_on_create = true
}
resource "github_repository_file" "modules" {
  depends_on = [time_sleep.wait_for_repo]
  repository          = github_repository.iac_repo.name
  file               = "modules/.gitkeep"
  content     = ""
  commit_message      = "init directories"
  overwrite_on_create = true
}
resource "github_repository_file" "env_dev" {
  depends_on = [time_sleep.wait_for_repo]
  repository          = github_repository.iac_repo.name
  file               = "environments/dev/.gitkeep"
  content     = ""
  commit_message      = "init directories"
  overwrite_on_create = true
}
resource "github_repository_file" "env_staging" {
  depends_on = [time_sleep.wait_for_repo]
  repository          = github_repository.iac_repo.name
  file               = "environments/staging/.gitkeep"
  content     = ""
  commit_message      = "init directories"
  overwrite_on_create = true
}
resource "github_repository_file" "env_production" {
  depends_on = [time_sleep.wait_for_repo]
  repository          = github_repository.iac_repo.name
  file               = "environments/production/.gitkeep"
  content     = ""
  commit_message      = "init directories"
  overwrite_on_create = true
}
variable "github_token" {}
variable "repo_name" {}
variable "secrets" {
  type    = map(string)
  default = {}
}

