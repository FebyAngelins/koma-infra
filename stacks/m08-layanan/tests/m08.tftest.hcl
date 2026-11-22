# Uji tanpa kredensial AWS (mock provider):  tofu init -backend=false && tofu test

mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111122223333" }
  }
  mock_data "aws_region" {
    defaults = { region = "ap-southeast-2" }
  }
  mock_data "aws_vpc" {
    defaults = { id = "vpc-0a1b2c3d4e5f60718", cidr_block = "172.31.0.0/16" }
  }
  mock_data "aws_subnets" {
    defaults = { ids = ["subnet-0aaa1111bbbb2222c", "subnet-0ddd3333eeee4444f"] }
  }
  mock_data "aws_ecr_repository" {
    defaults = {
      arn            = "arn:aws:ecr:ap-southeast-2:111122223333:repository/koma-121450001-m08-api"
      repository_url = "111122223333.dkr.ecr.ap-southeast-2.amazonaws.com/koma-121450001-m08-api"
    }
  }
  mock_data "aws_ecr_image" {
    defaults = { image_digest = "sha256:0000000000000000000000000000000000000000000000000000000000000000" }
  }
  mock_resource "aws_sns_topic" {
    defaults = { arn = "arn:aws:sns:ap-southeast-2:111122223333:koma-121450001-m08-prod-pesanan" }
  }
  mock_resource "aws_sqs_queue" {
    defaults = {
      arn = "arn:aws:sqs:ap-southeast-2:111122223333:koma-uji"
      url = "https://sqs.ap-southeast-2.amazonaws.com/111122223333/koma-uji"
    }
  }
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::111122223333:role/koma-uji" }
  }
  mock_resource "aws_lambda_function" {
    defaults = { arn = "arn:aws:lambda:ap-southeast-2:111122223333:function:koma-uji" }
  }
  mock_resource "aws_lb" {
    defaults = {
      arn      = "arn:aws:elasticloadbalancing:ap-southeast-2:111122223333:loadbalancer/app/koma-121450001-m08/50dc6c495c0c9188"
      dns_name = "koma-121450001-m08-123.ap-southeast-2.elb.amazonaws.com"
    }
  }
  mock_resource "aws_lb_target_group" {
    defaults = { arn = "arn:aws:elasticloadbalancing:ap-southeast-2:111122223333:targetgroup/koma-uji/73e2d6bc24d8a067" }
  }
  mock_resource "aws_lb_listener" {
    defaults = { arn = "arn:aws:elasticloadbalancing:ap-southeast-2:111122223333:listener/app/koma-uji/50dc6c495c0c9188/f2f7dc8efc522ab2" }
  }
  mock_resource "aws_ecs_cluster" {
    defaults = { arn = "arn:aws:ecs:ap-southeast-2:111122223333:cluster/koma-121450001-m08" }
  }
  mock_resource "aws_ecs_task_definition" {
    defaults = { arn = "arn:aws:ecs:ap-southeast-2:111122223333:task-definition/koma-uji:1" }
  }
}

variables {
  nim          = "121450001"
  kelompok     = "k00"
  cidr_saya    = "36.70.1.2/32"
  cost_center  = "CC-201"
  data_class   = "rahasia"
  versi_stabil = "8.0.0"
}

run "stabil_saja" {
  command = apply

  assert {
    condition     = length(aws_ecs_service.api) == 1 && length(aws_lb_target_group.api) == 1
    error_message = "tanpa versi_canary hanya ada layanan dan target group stabil"
  }
  assert {
    condition     = aws_lb_listener.http.default_action[0].forward[0].target_group != null
    error_message = "listener meneruskan ke target group stabil"
  }
  assert {
    condition     = jsondecode(aws_ecs_task_definition.api["stabil"].container_definitions)[0].image == "111122223333.dkr.ecr.ap-southeast-2.amazonaws.com/koma-121450001-m08-api:8.0.0"
    error_message = "image stabil dari registri sendiri dengan tag versi_stabil"
  }
  assert {
    condition     = aws_appautoscaling_target.stabil.max_capacity == 3 && aws_appautoscaling_target.stabil.min_capacity == 1
    error_message = "auto scaling stabil 1-3 task"
  }
  assert {
    condition     = aws_ecs_task_definition.api["stabil"].cpu == "256" && aws_ecs_task_definition.api["stabil"].memory == "512"
    error_message = "preset kecil 256 CPU unit, 512 MB"
  }
}

# TODO D.4  run "canary_dua_puluh_persen" (apply, versi_canary 8.1.0, bobot 20): dua layanan, bobot 80/20,
#           image canary bertag 8.1.0
# TODO D.4  run penolakan: bobot tanpa versi_canary, skala_maks 4, ukuran besar, versi tidak sah
