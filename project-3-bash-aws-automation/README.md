Project 3: Bash Scripting + AWS CLI Automation

A set of Bash scripts that automate basic server health checks and AWS EC2 monitoring — no manual console clicking required.

What this project does

1. Server health check script (myscript.sh)

Prints the current date/time and disk space usage on the server.
Uses a variable to capture the root disk usage percentage.
Uses an if/else condition to print a warning if disk usage goes above 80%, otherwise confirms everything is fine.
Scheduled to run automatically every hour using a cron job — no manual intervention needed.

2. AWS CLI + EC2 monitoring script (aws-check.sh)

Connects to AWS directly from the command line using the AWS CLI.
Uses a for loop to fetch every EC2 instance ID and check its status (running/stopped) one by one.
Uses grep to filter the output down to only the instances that are currently running — useful when there are many instances and you only care about the active ones.
Tools and concepts used
Bash scripting: variables, command substitution, if/else conditionals, for loops
Linux utilities: awk, tr, grep
Cron job scheduling (crontab) for automated, recurring execution
AWS CLI, integrated directly into shell scripts to query live AWS infrastructure
How to run
bash
chmod +x myscript.sh aws-check.sh
./myscript.sh
./aws-check.sh

To schedule the health check to run automatically every hour:

bash
crontab -e
# then add this line:
0 * * * * /home/ec2-user/myscript.sh >> /home/ec2-user/script-output.log 2>&1
Security note

While building this, I initially configured AWS CLI credentials directly on the EC2 instance using an IAM user's access key — this is fine for learning, but in a production environment the correct practice is to attach an IAM Role to the instance instead of hardcoding access keys, since keys can be accidentally exposed. I also learned firsthand why credentials should never be shared or pasted anywhere outside a secure terminal, after accidentally exposing a key and immediately rotating it in IAM.

What I learned
How to automate repetitive server checks instead of doing them manually.
How Bash scripts can call the AWS CLI to interact with real cloud infrastructure programmatically — the same underlying approach used for real DevOps/Cloud automation tooling.
Why credential hygiene (rotating exposed keys, preferring IAM Roles over hardcoded keys) matters in real cloud environments.
