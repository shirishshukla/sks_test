module-rds-arora-cluster
==========

An AWS RDS Cluster module.

Module Input Variables
---------------
- `cluster_tags` - Additional Cluster tags to be applied.
- `rds_db_port` - RDS DB Port Default aurora-postgresql 5432 else 3306
- `rds_vpc_id`  - VPC ID for creating security group else will be created in default VPC.
- `rds_subnets` - List of subnet IDs used by rds database subnet group to be created.
- `rds_cluster_security_group_ids` - Additional security group ids to associate with this RDS cluster. Note this is a list.
- `rds_cluster_security_group_name` - Name of Security group to be created for RDS.
- `rds_cluster_source_security_group_id` - This is the source security group that will have traffic ingress to the rds cluster.
- `rds_cluster_apply_immediately` - Specifies whether any database modifications are applied immediately, or during the next maintenance window. Default is false
- `rds_cluster_azs` - The availablity zones in which this RDS cluster should be launched in. Note, this is a list.
- `rds_cluster_backup_retention_period` - he number of days a backup should be kept before rotation. Default is 5.
- `rds_cluster_identifier` - The identifier for this RDS cluster.
- `rds_cluster_database_name` - The name of the database in this RDS cluster.
- `rds_cluster_db_parameter_group_name` - The database parameter group name for this RDS cluster.
- `rds_cluster_db_subnet_group_name` - The subnet ID for this cluster this RDS cluster.
- `rds_cluster_engine_type` - The engine type for this RDS cluster.
- `rds_cluster_engine_version` - The engine version for the engine type for this RDS cluster.
- `rds_cluster_master_password` - The master password for this RDS cluster.
- `rds_cluster_master_username` - The master password for this RDS cluster.
- `rds_cluster_preferred_backup_window` - The preferred  backup window for this RDS cluster. Defaults to 07:00-09:00.
- `rds_cluster_skip_final_snapshot` - On destroy with Terraform, this will skip the final snapshot for this RDS cluster. Defaults to false.
- `rds_cluster_storage_encrypted` - Encrypt the storage or data at rest for this RDS cluster. Defaults to true.
- `rds_cluster_instance_count` - The count or number of instance members that should be about of this RDS cluster.
- `rds_cluster_instance_class` - The type of EC2 intances that should be used in this RDS cluster.
- `rds_cluster_publicly_accessible` - This will make this RDS cluster publicly accessible. Default to false.
- `storage_encrypted` - Whether to enable storage encryption default enabled.
- `fox_owner` - The owner who will be responsible for this resource life.
- `fox_environment` - Fox Environment Name this resource will exist in.
- `fox_charge_code` - Fox Charge Code for BU
- `fox_application` - Fox Application Name

Usage
-----
Sample Example

```js
module "module-rds-cluster" {
  source                                   = "../../module-rds-arora-cluster"
  fox_application                          = "FMC Vidispine RDS"
  fox_charge_code                          = "791-00-815121-2514"
  fox_environment                          = "FMC Sandbox"
  fox_owner                                = "Caley Goff"
  rds_cluster_security_group_ids           = [ "sg-xxxxxx" ]
  rds_vpc_id                               = ['vpc-xxxxxx']
  rds_subnets                              = ['subnet-xxxxxx']
  rds_cluster_security_group_name          = "RDS Security Group"
  rds_cluster_apply_immediately            = "true"
  rds_cluster_azs                          = ["us-west-2a", "us-west-2b", "us-west-2c"]
  rds_cluster_backup_retention_period      = "5"
  rds_cluster_identifier                   = "rds-cluster"
  rds_cluster_database_name                = "fmcdatabase"
  rds_cluster_db_parameter_group_name      = "default.aurora-postgresql9.6"
  rds_cluster_db_subnet_group_name         = "${data.terraform_remote_state.sandbox_tfstate.master_db_subnet_group}"
  rds_cluster_engine_type                  = "aurora-postgresql"
  rds_cluster_engine_version               = "9.6.3"
  rds_cluster_master_password              = "some-password-do-not-commit-me-to-source-control"
  rds_cluster_master_username              = "some-username-do-not-commit-me-to-source-control"
  rds_cluster_preferred_backup_window      = "07:00-09:00"
  rds_cluster_skip_final_snapshot          = "false"
  rds_cluster_instance_count               = "3"
  rds_cluster_instance_class               = "db.r4.large"
  rds_cluster_publicly_accessible          = "false"
  rds_cluster_parameter_group_name         = "<this_rds_cluster_parameter_group_name>"
  rds_cluster_parameters                   =  [
                                                {
                                                  name  = "general_log"
                                                  value = 2
                                                },
                                                {
                                                  name  = "slow_query_log"
                                                  value = 1
                                                }
                                              ]
  rds_db_parameter_group_name             = "<this_rds_db_parameter_group_name>"
  rds_db_parameters                       = [
                                              {
                                                name  = "innodb_autoinc_lock_mode"
                                                value = 2
                                              }
                                            ]
```

Outputs
-------

- `rds_cluster_endpoint` - The DNS address for this instance. May not be writable.
- `rds_cluster_security_group` - The security group ID of the security group this RDS instance exists in.


### END 
