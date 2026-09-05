Project 3: AWS Networking Lab as Infrastructure as Code (Terraform)

This project rebuilds the same AWS networking lab from Project 1 and Project 2 in this repo — but instead of clicking through the AWS Console by hand, the entire environment is defined as code using Terraform. Running one command (terraform apply) creates the whole network and server; running terraform destroy tears it all down again, cleanly and repeatably.

Why Infrastructure as Code

Manually building infrastructure in the AWS Console works, but it isn't repeatable, isn't version-controlled, and is easy to get wrong when doing it a second time. Terraform solves this: the same main.tf file can be applied over and over to produce an identical environment, it can be reviewed like any other code (via Git), and it can be safely torn down when not needed — which also avoids unnecessary AWS costs.

Architecture
Resource	Purpose
VPC (10.20.0.0/16)	The private network everything else lives inside
Public Subnet (10.20.1.0/24)	Where the EC2 instance is launched
Internet Gateway	Gives the VPC a path to the public internet
Route Table	Routes 0.0.0.0/0 traffic through the Internet Gateway; associated with the public subnet
Security Group	Firewall — allows inbound SSH (port 22) from one IP only, allows all outbound traffic
EC2 Instance (t3.micro)	Amazon Linux 2023 server, launched using a dynamically-resolved latest AMI (via a Terraform data source)

Traffic flow: Internet → Internet Gateway → Route Table → Public Subnet → Security Group → EC2 Instance.

How it was built
Installed Terraform and the AWS CLI locally, and configured the CLI (aws configure) using a dedicated IAM user created specifically for Terraform to use (not a personal/root account).
Followed least-privilege practice for that IAM user: started with only VPC-related permissions, then added AmazonEC2FullAccess once EC2 resources were introduced (rather than granting broad access upfront).
Wrote the VPC, subnet, Internet Gateway, route table, and security group as separate Terraform resource blocks, with each one referencing the previous by ID (e.g. aws_subnet references aws_vpc.adil_tf_vpc.id) instead of hardcoding IDs.
Used a Terraform data source to automatically look up the latest Amazon Linux 2023 AMI, rather than hardcoding an AMI ID that would eventually go stale.
Ran terraform plan before every terraform apply to preview changes before they were made to real AWS infrastructure.
Verified the result by SSHing into the new EC2 instance's public IP, confirming the full network chain (VPC → Subnet → IGW → Route Table → Security Group → EC2) works end to end.
Security notes
SSH access is restricted to a single IP address (/32), not open to the internet.
No AWS access keys or .pem private key files are committed to this repository — only the Terraform configuration itself.
The IAM user Terraform authenticates as was scoped up incrementally (VPC access first, then EC2 access) rather than given broad permissions from the start.
Key learnings
The difference between a Terraform resource (something Terraform creates) and a data source (something Terraform looks up that already exists).
How Terraform resources reference each other by ID, so changing one resource automatically updates anything that depends on it.
Troubleshooting IAM permission errors surfaced directly by Terraform/AWS (e.g. ec2:DescribeImages access denied) by identifying the missing action and attaching the right policy.
terraform plan / terraform apply as a safe preview-then-execute workflow, compared to making changes directly in the AWS Console.
Proof

Add a screenshot here of terraform apply completing successfully, and of the SSH session into the EC2 instance (ec2-user@ip-10-20-1-240).

Note on the repo copy of this code

The security group's SSH rule in main.tf uses a placeholder IP (203.0.113.10/32) instead of a real one — replace it with your own current public IP before running this yourself. The real IP used during development was deliberately left out of this public repo.
