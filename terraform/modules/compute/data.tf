# Reserved for future data sources.
data "aws_ami" "windows_server" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
