# 1. Create the Glue Catalog Database to store crawled metadata
resource "aws_glue_catalog_database" "my_database" {
  name = "yahoo_terraform_db"
}

# 2. Manually define the table with the correct partition names
resource "aws_glue_catalog_table" "my_table" {
  name          = "transformed_data"
  database_name = aws_glue_catalog_database.my_database.name

  # ⬇️ ADD THIS PARAMETER ⬇️
  parameters = {
    "UPDATED_BY_CRAWLER" = "yahoo-terraform-crawler" # Must match your crawler name exactly
  }


  partition_keys {
    name = "year"
    type = "string"
  }
  partition_keys {
    name = "month"
    type = "string"
  }
  partition_keys {
    name = "day"
    type = "string"
  }

  storage_descriptor {
    location      = "s3://yahoo-terraform/transformed/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }
  }
}

# 2. Update Crawler to inherit from this table
resource "aws_glue_crawler" "my_crawler" {
  database_name = aws_glue_catalog_database.my_database.name
  name          = "yahoo-terraform-crawler"
  role          = aws_iam_role.batch_ecs_task_role.arn

  # 1. Change from s3_target to catalog_target
  catalog_target {
    database_name = aws_glue_catalog_database.my_database.name
    tables        = [aws_glue_catalog_table.my_table.name]
  }

  # ⬇️ ADD THIS BLOCK TO FIX THE ERROR ⬇️
  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  # 2. Ensure configuration is set to inherit
  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
    }
  })
}
