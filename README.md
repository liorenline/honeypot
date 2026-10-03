# honeypot
# SSH Honeypot on AWS

A production-style SSH honeypot that exposes a fake server to the public internet, records everything attackers do, and turns the raw logs into dashboards. The project is built entirely as code: infrastructure is provisioned with Terraform, the server is configured with Ansible, the application stack runs in Docker Compose, and every change is validated by a CI pipeline in GitHub Actions. A single `terraform apply` followed by `ansible-playbook` takes a clean AWS account to a working honeypot.

## How it works

The honeypot is Cowrie, a medium-interaction SSH honeypot. Port 22 of the server is published directly into the Cowrie container, so anything that tries to connect to SSH lands in a convincing fake Linux shell instead of the real system. Cowrie never executes attacker commands; it emulates them and writes every event as a JSON line: connections, client versions, login attempts with usernames and passwords, entered commands and file download attempts.

Grafana Alloy reads the Cowrie log from a shared Docker volume, parses each JSON line, and ships the events to Loki. Only the event type is promoted to a Loki label, because labels are indexed and high-cardinality values such as IP addresses or passwords would degrade Loki; those fields are extracted at query time instead. Alloy also uses the timestamp from the Cowrie event rather than the time the line was read, so the timeline stays accurate even if the pipeline is delayed. Loki keeps 30 days of data with retention enforced by its compactor. Grafana sits on top with a provisioned data source and a dashboard stored as JSON in the repository, showing login attempts over time, the most common usernames and passwords, executed commands and file downloads.

The real SSH daemon lives on a separate port that is reachable only from a single administrator IP. Grafana and the Alloy UI are bound to the loopback interface and are accessed through an SSH tunnel, so none of the monitoring stack is exposed to the internet.

## Infrastructure

Terraform state is stored in a versioned, encrypted S3 bucket with public access blocked and native S3 state locking. The bucket itself is created by a small bootstrap configuration and protected from accidental deletion. The provider is pinned to the project's AWS account through `allowed_account_ids`, which prevents Terraform from ever acting on a different account if other credentials happen to be present in the environment.

The network is a dedicated VPC with a single public subnet, an internet gateway and an explicit route table, with no NAT gateway to keep costs low. The security group follows least privilege: the trap port is open to everyone, the administrative SSH port is open only to one /32 address, and outbound traffic is limited to HTTP and HTTPS so that malware an attacker tries to pull through the honeypot cannot reach arbitrary ports.

The server is a Graviton `t4g.small` instance running Ubuntu, chosen as the smallest size that runs the full stack comfortably. CPU credits are set to standard mode so sustained load from bots cannot generate surprise charges. The root volume is encrypted, IMDSv2 is mandatory, and the metadata hop limit is set to one so that containers, including the honeypot itself, cannot reach the instance metadata service. The AMI is ignored after creation, which stops a newly published Ubuntu image from silently replacing the server and wiping collected data. An Elastic IP keeps the public address stable. Access to AWS goes through IAM Identity Center with short-lived credentials rather than long-lived access keys, in an account separate from any other workloads.

## Configuration management

The server is configured by five idempotent Ansible roles applied in a deliberate order. The common role updates the system, installs base packages and makes sure time synchronisation is running. The SSH hardening role moves the real daemon to the administrative port, disables password and root login, and validates the configuration before restarting so a broken file can never lock the administrator out. The firewall role loads nftables rules that drop everything not explicitly allowed. The docker role installs the container runtime, and the honeypot role copies the stack to the server, renders secrets into an environment file and starts the containers.

The same playbook works on a fresh server and on an already configured one. A preliminary play checks whether the hardened SSH port is open and, if not, connects on the default port for the first run, after which Ansible switches itself to the new port mid-play. Secrets such as the Grafana admin password are kept in Ansible Vault and committed only in encrypted form. A second run of the playbook reports no changes, which is used as the test that every role is truly idempotent.

## Continuous integration

Every push and pull request runs six parallel checks. YAML files are linted across the whole repository, and Ansible roles are checked with ansible-lint at its strictest production profile. Terraform is checked for formatting and validated in every configuration directory. The Docker Compose file is validated, and the Alloy pipeline configuration is parsed with the same Alloy version that runs on the server, so a syntax error in the log pipeline is caught before deployment rather than as a crashing container. Gitleaks scans the full Git history for leaked secrets. A final set of project-specific checks fails the build if the vault file is not encrypted, if an environment file has been committed, or if the Grafana dashboard JSON contains an instance-specific identifier.

## First observations

Within the first hours online the honeypot received connections from more than a dozen addresses on several continents. Most of them were port scanners that opened a TCP connection and closed it without even starting an SSH handshake, which is the reconnaissance phase that precedes credential brute forcing. This section will be updated as more data is collected.
