# --- CloudWatch Dashboard ---
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "Custom-Dashboard"
  dashboard_body = jsonencode({
    widgets = [
      # Backend ASG
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            [
              "AWS/EC2", "CPUUtilization",
              "AutoScalingGroupName", var.asg_backend,
            ],
          ]
          period = 300
          stat   = "Average"
          region = var.primary_region
          title  = "Backend ASG CPU Utilization"
        }
      },
      # Frontend ASG
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            [
              "AWS/EC2", "CPUUtilization",
              "AutoScalingGroupName", var.asg_frontend,
            ]
          ]
          period = 300
          stat   = "Average"
          region = var.primary_region
          title  = "Frontend ASG CPU Utilization"
        }
      },
      # DocumentDB
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/DocDB", "CPUUtilization", "DBClusterIdentifier", var.docdb_cluster_identifier],
          ]
          period = 300
          stat   = "Average"
          region = var.primary_region
          title  = "DocumentDB Cluster CPU Utilization"
        }
      },
      # ElastiCache
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            for cluster_id in var.elasticache_member_clusters :
            ["AWS/ElastiCache", "DatabaseMemoryUsagePercentage", "CacheClusterId", cluster_id]
          ]
          period = 300
          stat   = "Average"
          region = var.primary_region
          title  = "ElastiCache Instances Memory Usage"
        }
      },
      # NAT Gateway
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/NATGateway", "BytesInFromSource", "NatGatewayId", var.nat_gateway_id],
            ["AWS/NATGateway", "BytesOutToDestination", "NatGatewayId", var.nat_gateway_id]
          ]
          period = 300
          stat   = "Sum"
          region = var.primary_region
          title  = "NAT Gateway"
        }
      },
      # Backend Load Balancer
      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", "app/${var.lb_backend_name}/${var.lb_backend_arn_suffix}"],
            ["AWS/ApplicationELB", "UnHealthyHostCount", "LoadBalancer", "app/${var.lb_backend_name}/${var.lb_backend_arn_suffix}"],
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "app/${var.lb_backend_name}/${var.lb_backend_arn_suffix}"],
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", "app/${var.lb_backend_name}/${var.lb_backend_arn_suffix}"],
            ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "LoadBalancer", "app/${var.lb_backend_name}/${var.lb_backend_arn_suffix}"],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", "app/${var.lb_backend_name}/${var.lb_backend_arn_suffix}"],
          ]
          period = 300
          stat   = "Sum"
          region = var.primary_region
          title  = "Backend ALB"
        }
      },
      # Frontend Load Balancer
      {
        type   = "metric"
        x      = 12
        y      = 18
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", "app/${var.lb_frontend_name}/${var.lb_frontend_arn_suffix}"],
            ["AWS/ApplicationELB", "UnHealthyHostCount", "LoadBalancer", "app/${var.lb_frontend_name}/${var.lb_frontend_arn_suffix}"],
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "app/${var.lb_frontend_name}/${var.lb_frontend_arn_suffix}"],
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", "app/${var.lb_frontend_name}/${var.lb_frontend_arn_suffix}"],
            ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "LoadBalancer", "app/${var.lb_frontend_name}/${var.lb_frontend_arn_suffix}"],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", "app/${var.lb_frontend_name}/${var.lb_frontend_arn_suffix}"]
          ]
          period = 300
          stat   = "Sum"
          region = var.primary_region
          title  = "Frontend ALB"
        }
      }
    ]
  })
}

