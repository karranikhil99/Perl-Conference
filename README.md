# 🐳 Kubernetes Pod Alert Script (Perl)

This project provides a Perl-based monitoring script that detects failing pods in a Kubernetes cluster (e.g., Minikube) and sends email alerts when a pod is in an error state.

## 📂 Files

- `pod_alert.pl` – Monitors pods and sends alert emails on failure.
- `three-pods.yaml` – Sample Kubernetes manifest for deploying three pods.

## 🔧 Requirements

- Perl (tested on Strawberry Perl for Windows)
- Modules:
  - `Email::Sender::Simple`
  - `Email::Sender::Transport::SMTP::TLS`
  - `Email::MIME`
  - `Try::Tiny`
- `kubectl` CLI installed and configured
- SMTP credentials (App Password if using Gmail)

## 🚀 Usage

### 1. Deploy Test Pods
```bash
kubectl apply -f three-pods.yaml
