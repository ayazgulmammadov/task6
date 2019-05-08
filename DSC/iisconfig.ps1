Configuration Main
{

    Param (
        [string] $nodeName,
        [string] $certUrl,
        [string] $certThumbprint,
        [PSCredential] $certCredential
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
        xPfxImport importCert {
            Thumbprint = "$certThumbprint"
            Path       = "C:\Certs\iiscert.pfx"
            Location   = "LocalMachine"
            Store      = "My"
            Credential = "$certCredential"
            DependsOn  = "[xRemoteFile]copyCert"
        }
        xWebsite newWebSite {
            Ensure       = "Present"
            Name         = "NewWebSite"
            State        = "Started"
            PhysicalPath = "C:\inetpub\wwwroot"
            DependsOn    = @("[xPfxImport]importCert", "[WindowsFeature]IIS")
            BindingInfo  = MSFT_xWebBindingInformation {
                Protocol              = "HTTPS"
                Port                  = 443
                certificateThumbprint = "$certThumbprint"
                CertificateStoreName  = "My"
            }
        }
        <#Script installCert {
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
        }#>
    }
}