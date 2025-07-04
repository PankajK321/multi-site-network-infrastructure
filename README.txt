Multi-Site Network Infrastructure Project
A comprehensive multi-site network infrastructure implementation featuring centralized NFS storage, secure inter-site connectivity, and real-time file synchronization across geographically distributed Ubuntu servers.

Project Overview
Objective: Design and implement a scalable, secure multi-site network infrastructure supporting Realtime collaboration and centralized data management.

Technology Stack:
•	Operating System: Ubuntu Server 22.04 LTS
•	Networking: Multi-subnet architecture with VPN connectivity
•	Storage: Network File System (NFS) v4.2
•	Security: Firewall rules, access controls, permission management
•	Management: SSH-based remote administration 

Architecture
    [Ubuntu-HQ - NFS Server]
           192.168.10.10
                 |
       +---------+---------+
       |                   |
[Ubuntu-Branch]       [Ubuntu-Remote]
  192.168.20.10        192.168.30.10
    NFS Client          NFS Client


Implementation Phases
Phase 1: Network Infrastructure
•	Multi-subnet network topology
•	Inter-site connectivity verification
•	Basic security implementation

Phase 2: Centralized Storage
•	NFS server deployment on Ubuntu-HQ
•	NFS client configuration on Branch/Remote sites
•	Real-time file synchronization
•	Permission and security management

Technologies Used
•	Ubuntu Server 22.04 LTS - Operating system platform
•	NFS v4.2 - Network file system protocol
•	SSH - Secure remote administration
•	UFW - Uncomplicated Firewall
•	Netplan - Network configuration
•	systemd - Service management

Security Features
•	Network-level security: Firewall rules restricting access to authorized subnets
•	File-level permissions: Directory-specific read/write access controls
•	User authentication: Secure SSH-based management
•	Data integrity: Real-time synchronization with checksums 
•	Real-time file synchronization across multiple sites
•	Centralized storage management with distributed access
•	Scalable architecture supporting additional sites
•	High availability with automatic failover capabilities
•	Performance optimization for low-latency file access.
