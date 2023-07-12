data "amazon-ami" "amazon-linux" {
  filters = {
    name                = "amzn-ami-*-x86_64-gp2"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["024329120042"]
  region      = "eu-west-2"
}

locals {
  amazon_linux_name = "amazon-linux-${var.alias}-${var.ami_time_suffix}"
}

source "amazon-ebs" "amazon-linux" {
  ami_description      = "Encrypted Amazon Linux image made from off the shelf AMI"
  ami_name             = local.amazon_linux_name
  source_ami           = data.amazon-ami.amazon-linux.id
  region               = "eu-west-2"
  encrypt_boot         = true
  kms_key_id           = var.kms_id
  instance_type        = "m5.large"
  communicator         = "ssh"
  ssh_interface        = "session_manager"
  ssh_username         = "ec2-user"
  iam_instance_profile = "${var.alias}-ec2-default-instance-role"
  pause_before_ssm     = "3m"
  vpc_id               = var.vpc_id
  subnet_id            = var.subnet_id
  run_tags = {
    Name        = "amazon-linux-${var.alias}-temp"
    Persistence = "Ignore"
  }
  tags = {
    Application    = "Mobile Devices"
    Environment    = var.hcs_env
    Function       = "Digital Workplace"
    Name           = local.amazon_linux_name
    Packer_version = packer.version
    Source_AMI     = "{{ .SourceAMIOwner }}/{{ .SourceAMIName }}"
    Source_AMI_ID  = "{{ .SourceAMI }}"
    Timestamp      = "{{isotime \"2006-01-02 15:04:05\"}}"
  }
}

build {
  sources = ["source.amazon-ebs.amazon-linux"]

  provisioner "shell" {
    inline = ["echo Connected via SSM at '${build.User}@${build.Host}:${build.Port}'"]
  }
}
