provider "aws" {
    region      = "ap-south-1"
}

resource "aws_s3_bucket" "s3_bucket" {
    bucket = "my-first-tf-bucket-ankit"
    
    tags = {
        Name = "My Bucket"
        Env  = "Dev"
    }
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.s3_bucket.id
  acl    = "private"
}


resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.s3_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}