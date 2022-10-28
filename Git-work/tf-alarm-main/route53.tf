# Private Hosted Zone

resource "aws_route53_zone" "bta" {
  name = var.route53_zone
  vpc {
    vpc_id = data.terraform_remote_state.bt-vpc.outputs.vpc_id
  }
  lifecycle {
    ignore_changes = [vpc]
  }
}
