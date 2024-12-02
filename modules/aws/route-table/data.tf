
resource "time_sleep" "this" {
  create_duration = "1s"
  depends_on = [
    aws_route_table.this,
  ]
}

data "aws_route_table" "existing" {
  for_each       = { for s in local.subnet_ids : s.subnet_id => s if s.create == true }
  route_table_id = each.value.id
  depends_on = [
    aws_route_table.this,
  ]
}
