resource "aws_ebs_volume" "front_data" {
  count = 2

  # Le volume DOIT être dans la même AZ que l'instance
  availability_zone = var.availability_zone
  size              = 5        # Go, assez pour lv_www (2g) + lv_apache_logs (1g)
  type              = "gp3"

  tags = {
    Name = "front${count.index + 1}-data"
  }
}

resource "aws_volume_attachment" "front_data" {
  count = 2

  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.front_data[count.index].id
  instance_id = local.fronts[count.index].id
}