#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Sets up Windows 11 for Ansible management via WSL2
.DESCRIPTION
    1. Configures WinRM for Ansible remote management
    2. Installs WSL2 and Ubuntu if not already installed
    3. Installs Ansible and pywinrm in WSL
#>

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Ansible + WSL2 Setup for Windows 11" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# ============================================
# STEP 1: Configure WinRM for Ansible
# ============================================
Write-Host "`n[1/3] Configuring WinRM for Ansible..." -ForegroundColor Yellow

try {
    # Enable PSRemoting
    Write-Host "Enabling PSRemoting..." -ForegroundColor Gray
    Enable-PSRemoting -Force -SkipNetworkProfileCheck | Out-Null
    
    # Configure WinRM service
    Write-Host "Configuring WinRM service..." -ForegroundColor Gray
    Set-Service -Name WinRM -StartupType Automatic
    Start-Service -Name WinRM
    
    # Enable Basic Authentication (for local testing)
    Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true
    
    # Allow unencrypted traffic (localhost only - for testing)
    Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value $true
    
    # Configure firewall rule for WinRM
    if (-not (Get-NetFirewallRule -Name "WINRM-HTTP-In-TCP" -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -Name "WINRM-HTTP-In-TCP" -DisplayName "Windows Remote Management (HTTP-In)" `
            -Enabled True -Direction Inbound -Protocol TCP -LocalPort 5985 | Out-Null
    }
    
    # Increase max memory per shell (helpful for complex playbooks)
    Set-Item -Path WSMan:\localhost\Shell\MaxMemoryPerShellMB -Value 1024
    
    # Test WinRM
    $testResult = Test-WSMan -ComputerName localhost -ErrorAction SilentlyContinue
    if ($testResult) {
        Write-Host "✓ WinRM configured successfully" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ Error configuring WinRM: $_" -ForegroundColor Red
    exit 1
}

# ============================================
# STEP 2: Install WSL2 if not installed
# ============================================
Write-Host "`n[2/3] Checking WSL2 installation..." -ForegroundColor Yellow

try {
    # Check if WSL is installed by checking Windows optional features
    $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -ErrorAction SilentlyContinue
    
    if ($wslFeature.State -ne "Enabled") {
        Write-Host "Installing WSL2..." -ForegroundColor Gray
        wsl --install --no-distribution
        Write-Host "✓ WSL2 installed. A reboot will be required." -ForegroundColor Green
        $needsReboot = $true
    } else {
        Write-Host "WSL is already installed" -ForegroundColor Gray
    }
    
    # Check if Ubuntu is installed
    $distributions = wsl --list --quiet 2>$null
    if ($distributions -notmatch "Ubuntu") {
        Write-Host "Installing Ubuntu distribution..." -ForegroundColor Gray
        wsl --install -d Ubuntu
        Write-Host "✓ Ubuntu installed" -ForegroundColor Green
    } else {
        Write-Host "✓ Ubuntu distribution already installed" -ForegroundColor Green
    }
    
} catch {
    Write-Host "✗ Error installing WSL2: $_" -ForegroundColor Red
    exit 1
}

# ============================================
# STEP 3: Install Ansible in WSL
# ============================================
Write-Host "`n[3/3] Installing Ansible in WSL..." -ForegroundColor Yellow

if ($needsReboot) {
    Write-Host "⚠ WSL2 requires a system reboot before continuing." -ForegroundColor Yellow
    Write-Host "After rebooting, run the following commands in your Ubuntu WSL terminal:" -ForegroundColor Cyan
    Write-Host @"

    sudo apt update && sudo apt upgrade -y
    sudo apt install -y software-properties-common python3-pip git libffi-dev libssl-dev
    sudo apt-add-repository --yes --update ppa:ansible/ansible
    sudo apt install -y ansible
    pip3 install --user pywinrm

"@ -ForegroundColor White
} else {
    try {
        Write-Host "Setting up Ansible in WSL Ubuntu..." -ForegroundColor Gray
        
        $installScript = @"
sudo apt update && sudo apt upgrade -y
sudo apt install -y software-properties-common python3-pip git libffi-dev libssl-dev
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible
pip3 install --user pywinrm
ansible --version
"@
        
        # Execute in WSL
        $installScript | wsl -d Ubuntu bash -c "cat > /tmp/install_ansible.sh && bash /tmp/install_ansible.sh"
        
        Write-Host "✓ Ansible installed successfully in WSL" -ForegroundColor Green
        
        # Verify installation
        Write-Host "`nVerifying Ansible installation..." -ForegroundColor Gray
        wsl -d Ubuntu ansible --version
        
    } catch {
        Write-Host "✗ Error installing Ansible: $_" -ForegroundColor Red
        Write-Host "You may need to manually run the installation in WSL Ubuntu" -ForegroundColor Yellow
    }
}

# ============================================
# Summary and Next Steps
# ============================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Create an Ansible inventory file with Windows host configuration" -ForegroundColor White
Write-Host "2. Test connectivity: wsl ansible windows -m win_ping -i inventory.ini" -ForegroundColor White
Write-Host "3. Run your playbooks: wsl ansible-playbook your-playbook.yml -i inventory.ini" -ForegroundColor White

if ($needsReboot) {
    Write-Host "`n⚠ REBOOT REQUIRED to complete WSL2 installation" -ForegroundColor Red
}
