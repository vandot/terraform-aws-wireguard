data "template_file" "user_data" {
  template = file("${path.module}/templates/user-data.txt")

  vars = {
    wg_server_private_key = data.aws_ssm_parameter.wg_server_private_key.value
    wg_server_net         = var.wg_server_net
    wg_server_port        = var.wg_server_port
    peers                 = join("\n", data.template_file.wg_client_data_json.*.rendered)
    eip_id                = var.eip_id
  }
}

data "template_file" "wg_client_data_json" {
  template = file("${path.module}/templates/client-data.tpl")
  count    = length(var.wg_client_public_keys)

  vars = {
    client_pub_key = element(values(var.wg_client_public_keys[count.index]), 0)
    client_ip      = element(keys(var.wg_client_public_keys[count.index]), 0)
  }
}

# We're using ubuntu images - this lets us grab the latest image for our region from Canonical
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-16.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

# turn the sg into a sorted list of string
locals {
  sg_wireguard_external = sort([aws_security_group.sg_wireguard_external.id])
}

# clean up and concat the above wireguard default sg with the additional_security_group_ids
locals {
  security_groups_ids = compact(concat(var.additional_security_group_ids, local.sg_wireguard_external))
}

resource "aws_launch_configuration" "wireguard_launch_config" {
  name_prefix                 = "wireguard-${var.env}-lc-"
  image_id                    = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.ssh_key_id
  iam_instance_profile        = aws_iam_instance_profile.wireguard_profile.name
  user_data                   = data.template_file.user_data.rendered
  security_groups             = local.security_groups_ids
  associate_public_ip_address = var.associate_public_ip_address

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "wireguard_asg" {
  name_prefix          = "wireguard-${var.env}-asg-"
  max_size             = var.wg_server_count
  min_size             = var.wg_server_count
  launch_configuration = aws_launch_configuration.wireguard_launch_config.name
  vpc_zone_identifier  = var.subnet_ids
  health_check_type    = "EC2"
  termination_policies = ["OldestInstance"]
  target_group_arns    = var.target_group_arns

  lifecycle {
    create_before_destroy = true
  }

  tags = [
    {
      key                 = "Name"
      value               = "wireguard-${var.env}"
      propagate_at_launch = true
    },
    {
      key                 = "Project"
      value               = "wireguard"
      propagate_at_launch = true
    },
    {
      key                 = "tf-managed"
      value               = "True"
      propagate_at_launch = true
    },
  ]
}

