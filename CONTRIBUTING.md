# Contributing to Libre Devops Repositories

Your contributions mean a lot to us, and we are excited to include the community at every opportunity.

Our goal is to make the process of contributing seamless and straightforward, whether you're:

- Reporting an issue
- Reviewing the existing code
- Proposing a correction
- Suggesting a new feature
- Interested in becoming a maintainer

## Our Development Environment is GitHub

We leverage GitHub for hosting our code, managing issues, feature requests, and for processing pull requests.

## If You're Not Yet a Maintainer

The most effective way to suggest changes to our codebase is through pull requests, following the [Github Flow](https://guides.github.com/introduction/flow/index.html). We eagerly await your pull requests!

## Code Etiquette and Procedure

While the following workflow is tailored for Terraform submissions, it generally applies to other codes as well:

1. Fork the repository and branch out from `main`.
2. Ensure you've verified your code with `terraform validate`, `tfsec`, `checkov`, or other linting/security tools. 3. We have a script to help manage our common workflow - `Run-AzTerraform.ps1`
3. Use `terraform fmt -recursive` or another formatter like [prettier](https://prettier.io/) to format your Terraform code. We have a script for this as well - `Terraform-Release.ps1`
4. Files and variables should adhere to the "What You See Is What You Get" (WYSIWYG) naming guideline. For instance, in a terraform repo:
```shell
terraform-${provider}-${purpose}/ # For example, the provider can be 'azurerm' and the purpose can be 'virtual-network'
|
├── ${purpose}/main.tf # The primary function of the Terraform code, e.g., for a virtual network, it would be named 'vnet.tf'
├── variables.tf      # For input variables
├── LICENSE       # Exclusively the MIT License
├── locals.tf     # If locals are required
├── outputs.tf     # For output variables
├── README.md     # Documentation
```
1. Every `README.md` must be informative. For Terraform, always include a code example that successfully executes the module, and a markdown-formatted output from [terraform-docs](https://github.com/terraform-docs/terraform-docs):
```shell
terraform-docs markdown . >> README.md
```

Our `Terraform-Release.ps1` script will help with this.

1. Organize all variables alphabetically. In Terraform, this can be achieved with the following utility script:
Our `Terraform-Release.ps1` script will help with this.
2. Now, you're ready to submit your pull request!

## All Contributions are Subject to the MIT License

In essence, when you provide code changes, your contributions automatically fall under the same [MIT License](http://choosealicense.com/licenses/mit/) that governs the project. If this raises concerns, please reach out to the maintainers.

## Reporting Bugs

For tracking and addressing public bugs, we utilize GitHub [issues](https://github.com/briandk/transcriptase-atom/issues). Simply [open a new issue]() to report a bug. It's that simple!

## How to Write Comprehensive Bug Reports

**Exceptional Bug Reports** typically include:

- A concise summary or background
- Steps to reproduce the issue
  - Be as detailed as possible
  - Provide sample code when feasible
- Your initial expectations
- The actual result
- Additional notes or observations, such as potential reasons for the issue or attempted solutions

Comprehensive bug reports are invaluable to us. Truly, we can't emphasize this enough.

## Licensing Terms

By offering your contributions, you consent to license them under the MIT License.
