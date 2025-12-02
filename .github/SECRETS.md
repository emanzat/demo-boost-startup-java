# GitHub Secrets Configuration Guide

This document lists all GitHub Secrets required for the CI/CD pipeline to function properly.

## Required Secrets

Configure these secrets in your GitHub repository:
`Settings` → `Secrets and variables` → `Actions` → `New repository secret`

### Docker Hub Authentication

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `DOCKERHUB_USERNAME` | Your Docker Hub username | `myusername` |
| `DOCKERHUB_TOKEN` | Docker Hub access token (NOT password) | Generate at https://hub.docker.com/settings/security |

**How to create Docker Hub token:**
1. Go to https://hub.docker.com/settings/security
2. Click "New Access Token"
3. Name it "GitHub Actions CI/CD"
4. Copy the token and save it as `DOCKERHUB_TOKEN` secret

---

### SSH Deployment Configuration

| Secret Name | Description | Example | Value |
|-------------|-------------|---------|-------|
| `DEPLOY_SERVER` | Deployment server IP or hostname | `135.125.223.14`  | `` |
| `DEPLOY_SSH_USER` | SSH username for deployment server | `ubuntu` | - |
| `DEPLOY_SSH_PRIVATE_KEY` | SSH private key for authentication | Full private key content (see below) | - |
| `DEPLOY_SSH_PORT` | SSH port (optional, defaults to 22) | `22` or `2222` | - |

**How to generate SSH key pair:**

```bash
# On your local machine, generate a new SSH key pair
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/deploy_key

# Copy the PUBLIC key to your deployment server
ssh-copy-id -i ~/.ssh/deploy_key.pub deploy@135.125.223.14

# Or manually add to server's authorized_keys:
# cat ~/.ssh/deploy_key.pub | ssh deploy@135.125.223.14 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

# Display the PRIVATE key to copy to GitHub Secrets
cat ~/.ssh/deploy_key
```

**Format for `DEPLOY_SSH_PRIVATE_KEY`:**
```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
...
(full private key content)
...
-----END OPENSSH PRIVATE KEY-----
```

---

### Optional Secrets

| Secret Name | Description | Required? |
|-------------|-------------|-----------|
| `CODACY_PROJECT_TOKEN` | Codacy project token for code quality analysis | Optional - if using Codacy |

---

## Server Prerequisites

### On deployment server (135.125.223.14):

1. **Install Docker:**
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

2. **Configure firewall:**
```bash
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 8080/tcp # Application port
sudo ufw enable
```

3. **Create deployment user (if not exists):**
```bash
sudo adduser deploy
sudo usermod -aG docker deploy
```

4. **Add SSH public key to authorized_keys:**
```bash
# Switch to deploy user
sudo su - deploy

# Create .ssh directory
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Add your public key
nano ~/.ssh/authorized_keys
# Paste the public key from ~/.ssh/deploy_key.pub

# Set permissions
chmod 600 ~/.ssh/authorized_keys
```

5. **Test SSH connection:**
```bash
# From your local machine
ssh -i ~/.ssh/deploy_key deploy@135.125.223.14
```

---

## Security Best Practices

1. **Never commit secrets to git**
   - Use `.gitignore` to exclude sensitive files
   - Use GitHub Secrets for all credentials

2. **Use least privilege principle**
   - Create dedicated deploy user with minimal permissions
   - Use SSH keys instead of passwords
   - Rotate secrets regularly

3. **Monitor access**
   - Review GitHub Actions logs regularly
   - Set up alerts for failed deployments
   - Monitor server access logs

4. **Network security**
   - Use firewall rules to restrict access
   - Consider using VPN or SSH tunneling
   - Keep server and Docker updated

---

## Verification Checklist

Before running the pipeline, verify:

- [ ] `DOCKERHUB_USERNAME` is set
- [ ] `DOCKERHUB_TOKEN` is set and valid
- [ ] `DEPLOY_SERVER` is set to `135.125.223.14`
- [ ] `DEPLOY_SSH_USER` is set
- [ ] `DEPLOY_SSH_PRIVATE_KEY` is set with full private key
- [ ] SSH connection works: `ssh deploy@135.125.223.14`
- [ ] Docker is installed on deployment server
- [ ] Deployment user is in docker group
- [ ] Firewall allows ports 22 and 8080
- [ ] Server can pull from Docker Hub

---

## Testing the Configuration

Test SSH deployment manually:
```bash
# Test SSH connection
ssh deploy@135.125.223.14 "docker --version"

# Test Docker Hub authentication
docker login -u YOUR_USERNAME -p YOUR_TOKEN

# Test full deployment flow
ssh deploy@135.125.223.14 "docker pull YOUR_USERNAME/demo-boost-startup-java:latest"
```

---

## Troubleshooting

### Common Issues

**1. "Permission denied (publickey)" error:**
- Verify SSH private key is correctly copied to GitHub Secrets
- Check that public key is in server's `~/.ssh/authorized_keys`
- Verify file permissions: `authorized_keys` should be 600

**2. "Cannot connect to Docker daemon" error:**
- Verify deploy user is in docker group: `groups deploy`
- Restart SSH session or reboot server after adding to group

**3. "Image pull failed" error:**
- Verify Docker Hub credentials are correct
- Check that image name matches: `username/repo-name:tag`
- Ensure image was successfully pushed in previous step

**4. Port already in use:**
- Stop old container: `docker stop demo-boost-startup-java`
- Remove old container: `docker rm demo-boost-startup-java`
