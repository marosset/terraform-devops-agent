param (
    [string] $devOpsUrl,
    [string] $pat,
    [string] $pool,
    [string] $windowsUserName,
    [string] $windowsPassword
)

mkdir c:\vsts-agent
curl.exe https://vstsagentpackage.azureedge.net/agent/2.164.6/vsts-agent-win-x64-2.164.6.zip -o vsts-agent.zip
mkdir c:\vsts-agent
Expand-Archive .\vsts-agent.zip -DestinationPath c:\vsts-agent\
C:\vsts-agent\config.cmd --unattended --url $devOpsUrl --auth pat --token $pat --pool $pool --agent $env:COMPUTERNAME --replace --runAsService --windowsLogonAccount $windowsUserName --windowsLogonPassword $windowsPassword --overwriteAutoLogon --noRestart