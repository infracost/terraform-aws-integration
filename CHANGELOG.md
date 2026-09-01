# Changelog

## [0.4.0](https://github.com/infracost/terraform-aws-integration/compare/v0.3.2...v0.4.0) (2026-09-01)


### Features

* add optional infracost-bedrock role for invoking Claude models ([#18](https://github.com/infracost/terraform-aws-integration/issues/18)) ([5eaf19e](https://github.com/infracost/terraform-aws-integration/commit/5eaf19eaebefbaa3b3beeecb8882aad5050d9fa2))

## [0.3.2](https://github.com/infracost/terraform-aws-integration/compare/v0.3.1...v0.3.2) (2026-07-06)


### Bug Fixes

* gate aws_organizations_organization data source on enable_data_exports ([#13](https://github.com/infracost/terraform-aws-integration/issues/13)) ([9953e8b](https://github.com/infracost/terraform-aws-integration/commit/9953e8b17f2d4794ecc598801e4b754de8d7aa37))
* remove bcm-pricing-calculator:* iam permission ([#16](https://github.com/infracost/terraform-aws-integration/issues/16)) ([8000903](https://github.com/infracost/terraform-aws-integration/commit/8000903a707359ee684d6001e0f0adc38e1a02d3))

## [0.3.1](https://github.com/infracost/terraform-aws-integration/compare/v0.3.0...v0.3.1) (2026-06-26)


### Bug Fixes

* grant Transit Gateway and Client VPN describe for idle checks ([#11](https://github.com/infracost/terraform-aws-integration/issues/11)) ([b94e441](https://github.com/infracost/terraform-aws-integration/commit/b94e441fc76adcd835b1985140629520d04013f3))

## [0.3.0](https://github.com/infracost/terraform-aws-integration/compare/v0.2.0...v0.3.0) (2026-06-15)


### Features

* add anomaly monitor provisioning submodule ([#9](https://github.com/infracost/terraform-aws-integration/issues/9)) ([2e5fb20](https://github.com/infracost/terraform-aws-integration/commit/2e5fb208b5af312679994f0b13b9534046e5e437))

## [0.2.0](https://github.com/infracost/terraform-aws-integration/compare/v0.1.2...v0.2.0) (2026-06-03)


### ⚠ BREAKING CHANGES

* remove account_region output and aws_region data source ([#7](https://github.com/infracost/terraform-aws-integration/issues/7))

### Miscellaneous

* remove account_region output and aws_region data source ([#7](https://github.com/infracost/terraform-aws-integration/issues/7)) ([a5dcbe9](https://github.com/infracost/terraform-aws-integration/commit/a5dcbe94a885a64d27891d4f0d2db0342beeaafe))

## [0.1.2](https://github.com/infracost/terraform-aws-integration/compare/v0.1.1...v0.1.2) (2026-05-29)


### Miscellaneous

* add managed view only access and clean permissions ([#4](https://github.com/infracost/terraform-aws-integration/issues/4)) ([5834454](https://github.com/infracost/terraform-aws-integration/commit/5834454b934dfdbf5ec759a4044500d66a8f96ea))

## [0.1.1](https://github.com/infracost/terraform-aws-integration/compare/v0.1.0...v0.1.1) (2026-05-28)


### Miscellaneous

* add cloudtrail lookup for cost spike correlation ([#2](https://github.com/infracost/terraform-aws-integration/issues/2)) ([0c46ead](https://github.com/infracost/terraform-aws-integration/commit/0c46ead7373125b590583c5e82a1b8a33bed9ca5))

## 0.1.0 (2026-05-26)


### Miscellaneous

* initial commit from cross-account-link ([6d4bf8c](https://github.com/infracost/terraform-aws-integration/commit/6d4bf8c7ff1523bf0fd9ba5c5b798af63a6e4869))
