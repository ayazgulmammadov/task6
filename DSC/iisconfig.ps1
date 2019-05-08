Configuration Main
{

    Param (
        [string] $nodeName,
        [string] $certUrl,
        [string] $certThumbprint,
        [securestring] $certPassword
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName CertificateDsc
    Import-DscResource -ModuleName xWebAdministration

    Node $nodeName
    {
        WindowsFeature IIS {
            Name   = "Web-Server"
            Ensure = "Present"
        }
        xRemoteFile copyCert {
            Uri     = "$certUrl"
            DestinationPath = "C:\Certs\iiscert.pfx"
        }
        <#PfxImport importCert {
            Thumbprint = "$certThumbprint"
            Path       = "C:\Certs\iiscert.pfx"
            Location   = "LocalMachine"
            Store      = "WebHosting"
            Credential = "$using:certCredential"
            DependsOn  = "[File]copyCert"
        }#>
        xWebsite newWebSite {
            Ensure       = "Present"
            Name         = "NewWebSite"
            State        = "Started"
            PhysicalPath = "C:\inetpub\wwwroot"
            DependsOn    = @("[Script]installCert", "[WindowsFeature]IIS")
            BindingInfo  = MSFT_xWebBindingInformation {
                Protocol              = "HTTPS"
                Port                  = 443
                certificateThumbprint = "$certThumbprint"
                CertificateStoreName  = "My"
            }
        }
        Script installCert {
          TestScript = {
            if((Get-ChildItem -Path Cert:\LocalMachine\My).Thumbprint -contains $certThumbprint){return $true}
            else{return $false}
          }
          SetScript = {
            Import-PfxCertificate -FilePath "C:\Certs\iiscert.pfx" -Password $certPassword -CertStoreLocation "Cert:\LocalMachine\My"}
          GetScript = {
            return @{
              Result = Get-ChildItem -Path Cert:\LocalMachine\My -Recurse
            }
          }
          DependsOn = "[xRemoteFile]copyCert"
        }
    }
}