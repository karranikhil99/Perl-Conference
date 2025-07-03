# Kubernetes Pod Monitoring and Alert System (Perl)

## Overview

This solution provides a Perl-based monitoring tool for Kubernetes pods that automatically detects failures and sends email notifications. Designed primarily for local development environments like Minikube, it can be easily configured for any Kubernetes cluster.

## Key Components

- **Monitoring Script**: `pod_alert.pl` - Continuously checks pod health status
- **Sample Deployment**: `three-pods.yaml` - Example Kubernetes pod configuration for testing

## Setup Requirements

### Software Dependencies
- Perl environment (Strawberry Perl recommended for Windows users)
- Essential Perl modules:
  - Email::Sender::Simple
  - Email::Sender::Transport::SMTP::TLS
  - Email::MIME
  - Try::Tiny
- Kubernetes CLI (`kubectl`) properly configured

### Email Configuration
- Valid SMTP credentials (for Gmail, requires App Password with 2-Step Verification)

## Getting Started

### 1. Deploy Test Pods
Initialize the sample pod configuration with:
```bash
kubectl apply -f three-pods.yaml
```

### 2. Configure Email Settings
Edit the script's email parameters with your SMTP details:

```perl
my $transport = Email::Sender::Transport::SMTP::TLS->new({
    host     => 'smtp.gmail.com',
    port     => 587,
    username => 'your_email@gmail.com',
    password => 'your_app_password',  # Gmail users: Generate App Password
});
```

**Note for Gmail Users**:  
Create an App Password at:  
[https://myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords)

### 3. Launch Monitoring
Execute the monitoring script:
```bash
perl pod_alert.pl
```

## System Operation

- Periodically executes `kubectl get pods` to assess pod health
- Identifies problematic states including:
  - `Error`
  - `CrashLoopBackOff` 
  - `ImagePullBackOff`
- Generates email alerts with comprehensive pod status details

## Alert Message Example

```
Subject: Kubernetes Pod Failure Notification

Timestamp: Thu Jul 3 10:47:34 2025

Pod Name    Status      Restarts   Uptime
-----------------------------------------
pod-one     Running     0          23s
pod-three   Error       2          19s
pod-two     Running     0          23s
```

## Customization Options

The solution can be adapted to:

- Modify failure detection criteria
- Integrate with alternative notification channels (Slack, Mattermost, etc.)
- Adjust monitoring frequency
- Support different SMTP providers