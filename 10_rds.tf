#DB생성
resource "aws_db_instance" "cd_mydb" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "8.0.23"
  instance_class         = "db.t3.micro"
  name                   = "petclinic"
  identifier             = "cd"
  username               = "root"
  password               = "petclinic"
  availability_zone      = "ap-northeast-2a"
  # multi_az = true                    # 멀티 az
  db_subnet_group_name   = aws_db_subnet_group.cd_dbsg.id
  vpc_security_group_ids = [aws_security_group.sg_peer_db.id]
  skip_final_snapshot    = true
  backup_window          = "10:00-10:30"  #자동 백업이 생성되는 시간
  backup_retention_period = 4             #백업 보관 날짜
  apply_immediately      = true           #db 수정사항 즉시 적용
  tags = {
    "Name" = "cd-db"
  }
}
#DB서브넷 그룹
resource "aws_db_subnet_group" "cd_dbsg" {
  name       = "cd-dbsg"
  subnet_ids = [aws_subnet.cd_dbpeer1.id, aws_subnet.cd_dbpeer2.id]
}
#스냅샷 생성
resource "aws_db_snapshot" "test" {
  db_instance_identifier = aws_db_instance.cd_mydb.id
  db_snapshot_identifier = "testsnapshot1234"
}
# 자동 백업
/*resource "aws_db_instance" "backup" {
  instance_class      = "db.t2.micro"
  name                = "petclinic_backup"
  snapshot_identifier = data.aws_db_snapshot.test.id

  lifecycle {
    ignore_changes = [snapshot_identifier]
  }
}
*/