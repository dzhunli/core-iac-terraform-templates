name: "RELEASE: Terraform IaC Pipeline"
on:
  pull_request:
    types:
      - closed
    branches:
      - main
permissions:
  contents: write
  issues: read
  pull-requests: write
jobs:
  terraform:
    if: github.event.pull_request.merged == true
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
  tag:
    needs: terraform
    runs-on: ubuntu-latest
    outputs:
      tag_name: ${{ steps.set-tag.outputs.tag_name }}
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
          ref: main
      - name: Get latest tag
        id: get-latest-tag
        run: |
          git fetch --tags
          latest_tag=$(git describe --tags `git rev-list --tags --max-count=1` || echo "v0.0.0")
          echo "latest_tag=$latest_tag" >> $GITHUB_ENV
      - name: Generate new tag
        id: set-tag
        run: |
          IFS='.' read -r -a parts <<< ${latest_tag#v}
          major=${parts[0]}
          minor=${parts[1]}
          patch=${parts[2]}
          new_tag="v$major.$minor.$((patch + 1))"
          echo "new_tag=$new_tag" >> $GITHUB_ENV
          echo $new_tag
          echo "tag_name=$new_tag" >> $GITHUB_OUTPUT
        env:
          latest_tag: ${{ env.latest_tag }}
      - name: Push new tag using token
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git tag ${{ steps.set-tag.outputs.tag_name }}
          git remote set-url origin https://x-access-token:${{ secrets.REALESE_KEY }}@github.com/${{ github.repository }}
          git push origin ${{ steps.set-tag.outputs.tag_name }}                                                                                                                                                                               
  release:                                                                                                                                                                                                                                    
    needs: tag                                                                                                                                                                                                                                
    runs-on: ubuntu-latest                                                                                                                                                                                                                     
    steps:                                                                                                                                                                                                                                    
    - name: Checkout code
      uses: actions/checkout@v4
      with:
        fetch-depth: 0
        ref: main
    - name: Generate release changelog
      uses: varrcan/generate-pretty-changelog-action@v1
      with:
        config: ci-conf/changelog.yaml
    - name: Create GitHub release
      uses: softprops/action-gh-release@v2
      with:
        tag_name: ${{ needs.tag.outputs.tag_name }}
        body_path: CHANGELOG.md
        files: |
          $(find . -type f -not -path './*')
          $(find . -type d -not -path './*')
      env:
        GITHUB_TOKEN: ${{ secrets.REALESE_KEY }}