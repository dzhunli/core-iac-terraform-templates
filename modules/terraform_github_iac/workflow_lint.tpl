name: "LINT: Terraform IaC Pipeline"
on:
  push:
    branches-ignore:
      - "*no_ci*"
  pull_request:
    branches-ignore:
      - "*"
jobs:
  terraform:
    name: 'Terraform Linting'
    runs-on: ubuntu-latest
    defaults:
      run:
        shell: bash
    steps:
    - name: Checkout
      uses: actions/checkout@v3

    - name: Setup TFLint
      uses: terraform-linters/setup-tflint@v3
      with:
        tflint_version: latest

    - name: Show TFLint version
      run: tflint --version

    - name: Init TFLint
      run: tflint --init

    - name: Install Terraform
      run: |
        wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        sudo apt update && sudo apt install terraform

    - name: Terraform Init
      run: terraform init

    - name: Terraform Format
      run: terraform fmt

    - name: Run TFLint
      id: lint
      run: |
        echo "### Terraform Linting Warnings:" >> $GITHUB_STEP_SUMMARY
        echo "\`\`\`" >> $GITHUB_STEP_SUMMARY
        tflint --config=ci-conf/.tflint.hcl --chdir=./  --recursive >> $GITHUB_STEP_SUMMARY
        echo "\`\`\`" >> $GITHUB_STEP_SUMMARY