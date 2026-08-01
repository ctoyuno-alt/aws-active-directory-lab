module "bootstrap" {
  source = "../../modules/bootstrap"

  bucket_name = "${var.project_name}-${var.environment}-bootstrap"

  tags = local.common_tags
}
