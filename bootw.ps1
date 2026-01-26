#Requires -Version 5.1
#Requires -RunAsAdministrator

# ============================================
# STEP 4: Install GitHub CLI on Windows
# ============================================
Write-Host "`n[4/5] Installing GitHub CLI on Windows..." -ForegroundColor Yellow

try {
    # Check if gh is already installed
    $ghInstalled = Get-Command gh -ErrorAction SilentlyContinue
    
    if (-not $ghInstalled) {
        Write-Host "Installing GitHub CLI via winget..." -ForegroundColor Gray
        
        # Check if winget is available
        $wingetInstalled = Get-Command winget -ErrorAction SilentlyContinue
        
        if ($wingetInstalled) {
            winget install --id GitHub.cli --exact --silent --accept-package-agreements --accept-source-agreements
            Write-Host "✓ GitHub CLI installed successfully" -ForegroundColor Green
            
            # Refresh PATH
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        } else {
            Write-Host "⚠ winget not found. Please install GitHub CLI manually from https://cli.github.com/" -ForegroundColor Yellow
            Write-Host "Alternative: choco install gh or scoop install gh" -ForegroundColor Gray
        }
    } else {
        Write-Host "✓ GitHub CLI already installed" -ForegroundColor Green
    }
    
} catch {
    Write-Host "⚠ Could not install GitHub CLI automatically: $_" -ForegroundColor Yellow
    Write-Host "Please install manually from https://cli.github.com/" -ForegroundColor Gray
}

# ============================================
# STEP 5: Clone Private Repositories
# ============================================
Write-Host "`n[5/5] Setting up private repositories..." -ForegroundColor Yellow

# Define repositories to clone on Windows
$WindowsRepos = @(
    @{ Repo = "asapdev10/notes"; Path = "$env:USERPROFILE\.dotfiles" },
    @{ Repo = "asapdev10/scripts"; Path = "$env:USERPROFILE\.scripts" }
)

if ($needsReboot) {
    Write-Host "⚠ Skipping repository clone - reboot required first" -ForegroundColor Yellow
    Write-Host "`nAfter reboot, run these commands:" -ForegroundColor Cyan
    Write-Host @"

    # Authenticate with GitHub
    gh auth login
    
    # Clone Ansible playbook in WSL
    wsl gh repo clone $PlaybookRepo ~/.ansible
    
    # Clone Windows repositories
"@ -ForegroundColor White
    
    foreach ($repoInfo in $WindowsRepos) {
        Write-Host "    gh repo clone $($repoInfo.Repo) $($repoInfo.Path)" -ForegroundColor White
    }
    Write-Host ""
    
} else {
    try {
        # Check if gh CLI is available on Windows
        $ghInstalled = Get-Command gh -ErrorAction SilentlyContinue
        
        if ($ghInstalled) {
            # Check GitHub authentication status on Windows
            Write-Host "Checking GitHub authentication on Windows..." -ForegroundColor Gray
            $authStatus = gh auth status 2>&1
            
            if ($authStatus -notmatch "Logged in") {
                Write-Host "Authenticating with GitHub..." -ForegroundColor Gray
                gh auth login
            } else {
                Write-Host "✓ Already authenticated with GitHub" -ForegroundColor Green
            }
            
            # Clone Windows repositories
            Write-Host "`nCloning Windows repositories..." -ForegroundColor Yellow
            foreach ($repoInfo in $WindowsRepos) {
                $repo = $repoInfo.Repo
                $path = $repoInfo.Path
                
                if (-not (Test-Path $path)) {
                    Write-Host "  Cloning $repo..." -ForegroundColor Gray
                    gh repo clone $repo $path
                    Write-Host "  ✓ Cloned to $path" -ForegroundColor Green
                } else {
                    Write-Host "  Repository already exists at $path, pulling latest..." -ForegroundColor Gray
                    Push-Location $path
                    git pull
                    Pop-Location
                    Write-Host "  ✓ Updated $repo" -ForegroundColor Green
                }
            }
            
        } else {
            Write-Host "⚠ GitHub CLI not available on Windows. Skipping Windows repository clones." -ForegroundColor Yellow
        }
        
        # Install and configure gh CLI in WSL
        Write-Host "`nInstalling GitHub CLI in WSL..." -ForegroundColor Gray
        $ghInstallWSL = @"
set -e
type -p curl >/dev/null || sudo apt install curl -y
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh -y
"@
        $ghInstallWSL | wsl -d Ubuntu bash
        Write-Host "✓ GitHub CLI installed in WSL" -ForegroundColor Green
        
        # Authenticate gh CLI in WSL (shares credentials with Windows if using same method)
        Write-Host "`nChecking GitHub authentication in WSL..." -ForegroundColor Gray
        $wslAuthStatus = wsl -d Ubuntu gh auth status 2>&1
        
        if ($wslAuthStatus -notmatch "Logged in") {
            Write-Host "Authenticating with GitHub in WSL..." -ForegroundColor Gray
            wsl -d Ubuntu gh auth login
        } else {
            Write-Host "✓ Already authenticated in WSL" -ForegroundColor Green
        }
        
        # Clone Ansible playbook repository in WSL
        Write-Host "`nCloning Ansible playbook in WSL..." -ForegroundColor Yellow
        $wslPlaybookPath = "~/.ansible"
        
        $clonePlaybookWSL = @"
set -e
if [ ! -d "$wslPlaybookPath" ]; then
    echo "Cloning $PlaybookRepo to $wslPlaybookPath..."
    gh repo clone $PlaybookRepo $wslPlaybookPath
    echo "Repository cloned successfully"
else
    echo "Repository already exists, pulling latest changes..."
    cd $wslPlaybookPath
    git pull
    echo "Repository updated"
fi
"@
        $clonePlaybookWSL | wsl -d Ubuntu bash
        Write-Host "✓ Ansible playbook repository ready in WSL" -ForegroundColor Green
        
    } catch {
        Write-Host "⚠ Error setting up repositories: $_" -ForegroundColor Yellow
        Write-Host "`nManual clone commands:" -ForegroundColor Gray
        Write-Host "  Windows: gh repo clone <repo> <path>" -ForegroundColor Gray
        Write-Host "  WSL: wsl gh repo clone $PlaybookRepo ~/.ansible" -ForegroundColor Gray
    }
}

# ============================================
# Summary and Next Steps
# ============================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if (-not $needsReboot) {
    Write-Host "`nYour playbooks are located at:" -ForegroundColor Yellow
    Write-Host "  $PlaybookPath" -ForegroundColor White
    
    Write-Host "`nNext Steps:" -ForegroundColor Yellow
    Write-Host "1. Review your Ansible inventory in $PlaybookPath" -ForegroundColor White
    Write-Host "2. Test Windows connectivity: wsl ansible localhost -m win_ping -i inventory.ini" -ForegroundColor White
    Write-Host "3. Run your playbooks: cd $PlaybookPath && wsl ansible-playbook local.yml" -ForegroundColor White
    
    Write-Host "`nSample inventory configuration for Windows host:" -ForegroundColor Yellow
    Write-Host @"
[windows]
localhost

[windows:vars]
ansible_connection=winrm
ansible_port=5985
ansible_user=$env:USERNAME
ansible_password=YourPassword
ansible_winrm_transport=basic
ansible_winrm_server_cert_validation=ignore
"@ -ForegroundColor Gray
}

if ($needsReboot) {
    Write-Host "`n⚠⚠⚠ REBOOT REQUIRED ⚠⚠⚠" -ForegroundColor Red
    Write-Host "Please restart your computer to complete WSL2 installation" -ForegroundColor Yellow
    Write-Host "After reboot, re-run this script to complete setup" -ForegroundColor Yellow
}
