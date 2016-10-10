resource "aws_iam_user" "ose" {
  name = "ose-cloudprovider"
}

resource "aws_iam_access_key" "ose" {
  user = "${aws_iam_user.ose.name}"
}

resource "aws_iam_user_policy" "ose" {
  name = "Policy"
  user = "${aws_iam_user.ose.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["ec2:*"],
      "Resource": ["*"]
    },
    {
      "Effect": "Allow",
      "Action": ["elasticloadbalancing:*"],
      "Resource": ["*"]
    },
    {
      "Effect": "Allow",
      "Action": ["route53:*"],
      "Resource": ["*"]
    }
  ]
}
EOF
}
