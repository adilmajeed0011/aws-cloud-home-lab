# AWS Cloud Home Lab — Project 2: Multi-Tier Network (Public + Private Subnet)

**Author:** Adil Majeed
**Date:** August 2026
**Goal:** Design and build a two-tier AWS network — a public tier reachable from the internet and a private tier reachable only from within the network — mirroring how real production environments separate a public-facing web tier from an internal/database tier.

## Overview

Building on Project 1 (a single public web server), this project introduces network segmentation: a private subnet with no direct internet access, isolated behind security group rules so it can only be reached through the public tier. This is the same pattern used in production AWS environments to protect internal resources such as databases from direct internet exposure.

## IP Addressing Plan

A deliberate, professional CIDR scheme was used instead of arbitrary ranges:

| Resource | CIDR / Range | Notes |
|---|---|---|
| VPC (`adil-lab-vpc`) | `10.0.0.0/16` | 65,536 addresses — private (RFC 1918) range, the block AWS itself recommends for VPCs |
| Public Subnet (`adil-lab-public-subnet-1a`) | `10.0.1.0/24` | 256 addresses, internet-facing tier |
| Private Subnet (`adil-lab-private-subnet-1a`) | `10.0.2.0/24` | 256 addresses, internal-only tier |

Using consistent `10.0.x.0/24` blocks per subnet keeps the addressing scheme predictable and easy to extend (e.g. `10.0.3.0/24` for a future tier) — a standard convention in real-world AWS environments.

## Architecture

```
Internet
   │
   ▼
Internet Gateway (adil-lab-igw)
   │
   ▼
Public Route Table (adil-lab-public-rt)  ──  0.0.0.0/0 → IGW
   │
   ▼
Public Subnet (10.0.1.0/24)
   │
   ▼
adil-lab-public-sg
   ├── Inbound: HTTP (80) → 0.0.0.0/0
   └── Inbound: SSH  (22) → my IP only
   │
   ▼
EC2: adil-lab-web-server  ← reachable from the internet


Private Subnet (10.0.2.0/24)
   │
   ▼
Private Route Table (adil-lab-private-rt)  ──  local only (no IGW route)
   │
   ▼
adil-lab-private-sg
   └── Inbound: SSH (22) → 10.0.1.0/24 only  (public subnet, not the internet)
   │
   ▼
EC2: adil-lab-db-server  ← NOT reachable from the internet, only from the public subnet
```

## Key Security Design Choices

- The private subnet's route table has **no route to the Internet Gateway** — only the default `local` route. This means the private subnet cannot send or receive internet traffic at all, regardless of security group settings.
- The private instance was launched with **no public IP address** assigned.
- The private security group only accepts SSH from `10.0.1.0/24` (the public subnet's own range) — not from the internet, and not even directly from my own PC's IP.
- The only way into the private server is through the public server first — the same "jump host" / bastion pattern used in real production networks to protect internal systems.

## Testing / Proof

**Test 1 — Public server is reachable from the internet:**
```
PS C:\Users\Adil Majeed\desktop> ssh -i "adil-key-for-ec2.pem" ec2-user@3.230.0.242
Amazon Linux 2023
[ec2-user@ip-10-0-1-60 ~]$
```
Connected successfully from my own PC — confirms the public tier works as expected.

**Test 2 — Private server is reachable only from inside the network, not directly:**
```
[ec2-user@ip-10-0-1-60 ~]$ ssh -i adil-key-for-ec2.pem ec2-user@10.0.2.139
The authenticity of host '10.0.2.139' can't be established.
...
Amazon Linux 2023
[ec2-user@ip-10-0-2-139 ~]$
```
From inside the public server, the jump to the private server (`10.0.2.139`) succeeded. A direct SSH attempt to `10.0.2.139` from outside the VPC would time out, since the instance has no public IP and its security group only trusts the public subnet.

## Key Learnings

- How route tables — not just security groups — control whether a subnet has internet access; a subnet with no IGW route is private by definition, even before any security group rules are applied.
- How to design a CIDR addressing scheme deliberately (VPC → subnet ranges) rather than picking arbitrary numbers, and why AWS recommends the `10.0.0.0/8` private range for this.
- The "bastion host" / jump-host access pattern: reaching an internal server only via a trusted public-facing server, never directly.
- A real debugging lesson: an unsaved security group rule looks correct on screen but has no effect until "Save rules" is clicked — this caused an earlier connection-timeout that took some troubleshooting to trace.

## Next Steps

- Automate this entire setup with Terraform (Infrastructure as Code) instead of manual console steps.
- Replace the key-copy jump method with SSH agent forwarding, the more secure production approach (no private key ever stored on the bastion server).
- Add a NAT Gateway so the private server can reach the internet for updates, without being reachable *from* the internet.
