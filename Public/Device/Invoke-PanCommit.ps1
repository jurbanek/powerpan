function Invoke-PanCommit {
<#
.SYNOPSIS
Commit, validate, or check for pending changes on a PanDevice.
.DESCRIPTION
Commit or validate configuration changes on a PanDevice. This cmdlet provides a wrapper around the PAN-OS XML API commit and validate functionality.

1) Choose -Commit or -Validate
2) Choose -Full or -Partial
3) Choose to -Force a commit (does not apply to validate). -Force is the PAN-OS "Force Commit" function, not the PowerShell override.

From there, specify additional optional parameters. There are many optional parameters to scope a -Partial commit or validate.
Successful commit and validation requests return a PanJob. The PanJob can be used to monitor the status and final result of commit or validation.

Separately, check for pending changes with standalone -PendingChanges switch. Returns $True or $False.
.NOTES
Invoke-PanCommit abstracts several related capabilities within PAN-OS into a single cmdlet.
Config mode commit, commit partial which are part of XML-API type=commit
Config mode validate, validate partial which are part of XML-API type=op (operational)
Exec mode check pending changes which is part of XML-API type=op (operational)

These logically grouped capabilities are built-into a single cmdlet instead of many constituent cmdlets.
.INPUTS
PanDevice[]
   You can pipe a PanDevice to this cmdlet
.OUTPUTS
PanJob
.EXAMPLE
PS> Get-PanDevice '10.0.0.1' | Invoke-PanCommit -Commit -Full
Standard commit of full configuration. Returns a PanJob.
.EXAMPLE
PS> Get-PanDevice '10.0.0.1' | Invoke-PanCommit -Commit -Partial -Admin "JohnnyU" -Description "Emergency Change"
Partial commit only committing changes by "JohnnyU" with a description. Returns a PanJob.
.EXAMPLE
PS> Get-PanDevice '10.0.0.1' | Invoke-PanCommit -Validate -Full
Standard validation of full configuration. Returns a PanJob.
.EXAMPLE
PS> Get-PanDevice '10.0.0.1' | Invoke-PanCommit -PendingChanges
Returns $True is changes are pending in candidate configuration. $False if there are no pending changes.
#>
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true,HelpMessage='PanDevice(s) to commit configuration changes.')]
        [PanDevice[]] $Device,
        [parameter(Mandatory=$true,Position=1,ParameterSetName='Commit-Full',HelpMessage='Commit switch.')]
        [parameter(Mandatory=$true,Position=1,ParameterSetName='Commit-Partial',HelpMessage='Commit switch.')]
        [Switch] $Commit,
        [parameter(Mandatory=$true,Position=1,ParameterSetName='Validate-Full',HelpMessage='Validate switch. Validate the commit without committing.')]
        [parameter(Mandatory=$true,Position=1,ParameterSetName='Validate-Partial',HelpMessage='Validate switch. Validate the commit without committing.')]
        [Switch] $Validate,
        ####
        #### Experiment with default value of $Full:$true to see if can avoid -Commit -Full explicitness on the PowerShell commandline.
        ####
        [parameter(Mandatory=$true,Position=2,ParameterSetName='Commit-Full',HelpMessage='Partial switch.')]
        [parameter(Mandatory=$true,Position=2,ParameterSetName='Validate-Full',HelpMessage='Partial switch.')]
        [Switch] $Full,
        [parameter(Mandatory=$true,Position=2,ParameterSetName='Commit-Partial',HelpMessage='Partial switch.')]
        [parameter(Mandatory=$true,Position=2,ParameterSetName='Validate-Partial',HelpMessage='Partial switch.')]
        [Switch] $Partial,
        [parameter(ParameterSetName='Commit-Full',HelpMessage='PAN-OS "Force Commit", not PowerShell override.')]
        [parameter(ParameterSetName='Commit-Partial',HelpMessage='PAN-OS "Force Commit", not PowerShell override.')]
        [Switch] $Force,
        [parameter(ParameterSetName='Commit-Full',HelpMessage='Description for commit.')]
        [parameter(ParameterSetName='Commit-Partial',HelpMessage='Description for commit.')]
        [String] $Description,
        [parameter(ParameterSetName='Commit-Partial',HelpMessage='Limit scope to specific Admin(s) changes.')]
        [parameter(ParameterSetName='Validate-Partial',HelpMessage='Limit scope to specific Admin(s) changes.')]
        [String[]] $Admin,
        [parameter(ParameterSetName='Commit-Partial',HelpMessage='Limit scope to specific vsys(s).')]
        [parameter(ParameterSetName='Validate-Partial',HelpMessage='Limit scope to specific vsys(s).')]
        [String[]] $Vsys,
        [parameter(ParameterSetName='Commit-Partial',HelpMessage='Not clear on use but supported by CLI & API.')]
        [parameter(ParameterSetName='Validate-Partial',HelpMessage='Not clear on use but supported by CLI & API.')]
        [Switch] $NoVsys,
        [parameter(ParameterSetName='Commit-Partial',HelpMessage='Exclude Device & Network from scope.')]
        [parameter(ParameterSetName='Validate-Partial',HelpMessage='Exclude Device & Network from scope.')]
        [Switch] $ExcludeDeviceAndNetwork,
        [parameter(ParameterSetName='Commit-Partial',HelpMessage='Exclude Shared Objects from scope.')]
        [parameter(ParameterSetName='Validate-Partial',HelpMessage='Exclude Shared Objects from scope.')]
        [Switch] $ExcludeSharedObject,
        [parameter(ParameterSetName='Commit-Partial',HelpMessage='XPath(s) to include in scope.')]
        [parameter(ParameterSetName='Validate-Partial',HelpMessage='XPath(s) to include in scope.')]
        [String[]] $XPath,
        [parameter(ParameterSetName='Pending-Changes',HelpMessage='Determine pending changes in candidate configuration.')]
        [Switch] $PendingChanges
    )

    Begin {
        # Propagate -Debug and -Verbose to this module function, https://tinyurl.com/y5dcbb34
        if($PSBoundParameters.Debug) { $DebugPreference = 'Continue' }
        if($PSBoundParameters.Verbose) { $VerbosePreference = 'Continue' }
        # Announce
        Write-Debug ($MyInvocation.MyCommand.Name + ':')
    } # Begin block

    Process {
        foreach($DeviceCur in $Device) {
            Write-Debug ($MyInvocation.MyCommand.Name + (': Device: {0}' -f $DeviceCur.Name))
            
            # ParameterSet name Pending-Changes
            if($PSCmdlet.ParameterSetName -eq 'Pending-Changes') {
                Write-Debug ($MyInvocation.MyCommand.Name + ': -PendingChanges')
                $Cmd = '<check><pending-changes></pending-changes></check>'
                $Response = Invoke-PanXApi -Device $DeviceCur -Op -Cmd $Cmd
                if($Response.result -eq 'no') {
                    Write-Debug ($MyInvocation.MyCommand.Name + (': Device : {0} has NO pending changes to be committed.' -f $DeviceCur.Name))
                    return $False
                }
                elseif($Response.result -eq 'yes') {
                    Write-Debug ($MyInvocation.MyCommand.Name + (': Device : {0} HAS pending changes to be committed.' -f $DeviceCur.Name))
                    return $True
                }
            }
            # Any other ParameterSetName (all the Commit- and Validate-)
            else {
                # -Commit and -Validate base
                # $XmlDoc used to build and chain XML elements together
                $XmlDoc = [System.Xml.XmlDocument]::new()
                # Set the Root to <commit> or <validate>
                # $XmlRoot will contain the final XML to be used in Cmd. Build it slowly.
                if($PSBoundParameters.Commit.IsPresent) {
                    Write-Debug ($MyInvocation.MyCommand.Name + ': -Commit')
                    $XmlRoot = $XmlDoc.CreateElement('commit')
                } 
                else {
                    Write-Debug ($MyInvocation.MyCommand.Name + ': -Validate')
                    $XmlRoot = $XmlDoc.CreateElement('validate')
                }
                $XmlDoc.AppendChild($XmlRoot) | Out-Null

                # -Force
                # Force is only relevant for Commit operation, not Validate. ParameterSet definitions control where it can be used
                if($PSBoundParameters.Force.IsPresent) {
                    Write-Debug ($MyInvocation.MyCommand.Name + ': -Force')
                    $XmlForce = $XmlDoc.CreateElement('force')
                    # Trick to get a closing </force> tag on the valueless <force />
                    # https://stackoverflow.com/questions/45270479/force-xmldocument-to-save-empty-elements-with-an-explicit-closing-tag
                    $XmlForce.AppendChild($XmlDoc.CreateWhitespace('')) | Out-Null
                    # Append to root
                    $XmlRoot.AppendChild($XmlForce) | Out-Null
                    # Force requested, XmlForce is go-foward point of working tree
                    $XmlWork = $XmlForce
                }
                else {
                    # Force not requested, XmlRoot is go-foward point of working tree
                    $XmlWork = $XmlRoot
                }

                # -Full and -Partial
                # PAN-OS Continues to amaze
                # Commit partial is <commit><partial>...</partial></commit>
                # Validate partial is <validate><partial>...</partial</validate>
                # Commit full is <commit>...</commit> (no <full></full>, the odd one out)
                # Valid full is <validate><full>...</full></validate>
                if($PSCmdlet.ParameterSetName -like '*-Partial') {
                    Write-Debug ($MyInvocation.MyCommand.Name + ': -Partial')
                    $XmlPartial = $XmlDoc.CreateElement('partial')
                    # Trick for closing tag
                    $XmlPartial.AppendChild($XmlDoc.CreateWhitespace('')) | Out-Null
                    $XmlWork.AppendChild($XmlPartial) | Out-Null
                    # Partial requested, XmlPartial is go-forward point of working tree
                    $XmlWork = $XmlPartial
            
                }
                elseif($PSCmdlet.ParameterSetName -eq 'Validate-Full') {
                    Write-Debug ($MyInvocation.MyCommand.Name + ': (Validate) -Full')
                    $XmlFull = $XmlDoc.CreateElement('full')
                    # Trick for closing tag
                    $XmlFull.AppendChild($XmlDoc.CreateWhitespace('')) | Out-Null
                    $XmlWork.AppendChild($XmlFull) | Out-Null
                    # Validate full, XmlFull is go-forward point of working tree
                    $XmlWork = $XmlFull
                }
                elseif($PSCmdlet.ParameterSetName -eq 'Commit-Full') {
                    Write-Debug ($MyInvocation.MyCommand.Name + ': (Commit) -Full')
                    # Nothing to do for Commit-Full. Go-forward point of working tree does not change
                }

                # -Description <description>My Description</description>
                if($PSBoundParameters.Description) {
                    Write-Debug ($MyInvocation.MyCommand.Name + ': -Description')
                    $XmlDescription = $XmlDoc.CreateElement('description')
                    $XmlDescription.InnerText = $PSBoundParameters.Description
                    $XmlWork.AppendChild($XmlDescription) | Out-Null
                }

                # -Admin <admin><member>Admin1</member><member>Admin2</member></admin>
                if($PSBoundParameters.Admin) {
                    Write-Debug ($MyInvocation.MyCommand.Name + (': -Admin (Count:{0})' -f $PSBoundParameters.Admin.Count))
                    $XmlAdmin = $XmlDoc.CreateElement('admin')
                    foreach($AdminCur in $PSBoundParameters.Admin) {
                        $XmlMember = $XmlDoc.CreateElement('member')
                        $XmlMember.InnerText = $AdminCur
                        # Add the <member> to the <admin>
                        $XmlAdmin.AppendChild($XmlMember) | Out-Null
                    }
                    $XmlWork.AppendChild($XmlAdmin) | Out-Null
                    # # Go-forward point of working tree does not change
                }

                # -Vsys <vsys><member>vsys1</member><member>vsys2</member></vsys>
                if($PSBoundParameters.Vsys) {
                    Write-Debug ($MyInvocation.MyCommand.Name + (': -Vsys (Count:{0})' -f $PSBoundParameters.Vsys.Count))
                    $XmlVsys = $XmlDoc.CreateElement('vsys')
                    foreach($VsysCur in $PSBoundParameters.Vsys) {
                        $XmlMember = $XmlDoc.CreateElement('member')
                        $XmlMember.InnerText = $VsysCur
                        # Add the <member> to the <vsys>
                        $XmlVsys.AppendChild($XmlMember) | Out-Null
                    }
                    $XmlWork.AppendChild($XmlVsys) | Out-Null
                    # # Go-forward point of working tree does not change
                }

                # -NoVsys <novsys></novsys>
                if($PSBoundParameters.NoVsys.IsPresent) {
                    Write-Debug ($MyInvocation.MyCommand.Name + ': -NoVsys')
                    $XmlNoVsys = $XmlDoc.CreateElement('novsys')
                    # Force a closing tag
                    $XmlNoVsys.AppendChild($XmlDoc.CreateWhitespace('')) | Out-Null
                    $XmlWork.AppendChild($XmlNoVsys) | Out-Null
                    # Go-forward point of working tree does not change
                }

                # -ExcludeDeviceAndNetwork <device-and-network>excluded</device-and-network>
                if($PSBoundParameters.ExcludeDeviceAndNetwork.IsPresent) {
                    Write-Debug ($MyInvocation.MyCommand.Name + ': -ExcludeDeviceAndNetwork')
                    $XmlDeviceAndNetwork = $XmlDoc.CreateElement('device-and-network')
                    $XmlDeviceAndNetwork.InnerText = 'excluded'
                    $XmlWork.AppendChild($XmlDeviceAndNetwork) | Out-Null
                    # Go-forward point of working tree does not change
                }

                # -ExcludeSharedObject <shared-object>excluded</shared-object>
                if($PSBoundParameters.ExcludeSharedObject.IsPresent) {
                    Write-Debug ($MyInvocation.MyCommand.Name + ': -ExcludeSharedObject')
                    $XmlSharedObject = $XmlDoc.CreateElement('shared-object')
                    $XmlSharedObject.InnerText = 'excluded'
                    $XmlWork.AppendChild($XmlSharedObject) | Out-Null
                    # Go-forward point of working tree does not change
                }

                # -XPath <object-xpaths><member>/config/devices/entry[@name='localhost.localdomain']/vsys/entry[@name='vsys1']/service</member><member>...</member></object-xpaths>
                if($PSBoundParameters.XPath) {
                    Write-Debug ($MyInvocation.MyCommand.Name + (': -XPath (Count:{0})' -f $PSBoundParameters.XPath.Count))
                    $XmlObjectXPaths = $XmlDoc.CreateElement('object-xpaths')
                    foreach($XPathCur in $PSBoundParameters.XPath) {
                        $XmlMember = $XmlDoc.CreateElement('member')
                        $XmlMember.InnerText = $XPathCur
                        # Add the <member> to the <object-xpaths>
                        $XmlObjectXPaths.AppendChild($XmlMember) | Out-Null
                    }
                    $XmlWork.AppendChild($XmlObjectXPaths) | Out-Null
                    # # Go-forward point of working tree does not change
                }

                # Finished building XML. Make the request.
                if($PSCmdlet.ParameterSetName -like 'Commit-Full') {
                    Write-Debug ($MyInvocation.MyCommand.Name + ': -Commit Cmd: {0}' -f $XmlRoot.OuterXml)
                    $Response = Invoke-PanXApi -Device $DeviceCur -Commit -Cmd $XmlRoot.OuterXml
                }
                elseif($PSCmdlet.ParameterSetName -like 'Commit-Partial') {
                    Write-Debug ($MyInvocation.MyCommand.Name + ': -Commit -Action "partial" Cmd: {0}' -f $XmlRoot.OuterXml)
                    $Response = Invoke-PanXApi -Device $DeviceCur -Commit -Action 'partial' -Cmd $XmlRoot.OuterXml
                }
                elseif($PSCmdlet.ParameterSetName -like 'Validate-*') {
                    Write-Debug ($MyInvocation.MyCommand.Name + ': -Validate Cmd: {0}' -f $XmlRoot.OuterXml)
                    $Response = Invoke-PanXApi -Device $DeviceCur -Op -Cmd $XmlRoot.OuterXml
                }
                # PAN-OS responses are same for commit and validate operations. Can use same logic for both
                # Validate responses are identical to below, just change word "commit" to "validate"
                # PAN-OS gives two different types of responses on success based on whether *pending changes* or not
                # Pending Changes:
                # <response status="success" code="19">
                #   <result>
                #       <msg>
                #           <line>Commit job enqueued with jobid 4</line>
                #       </msg>
                #       <job>4</job>
                #   </result>
                # </response>
                # NO Pending Changes:
                # <response status="success" code="19"><msg>There are no changes to commit.</msg></response>
                if($Response.Status -eq 'success') {
                    # If pending changes and a job
                    if($Response.Result.job) {
                    # Inform an interactive user of the JobID using Write-Host given operation is asynchronous
                    Write-Host $Response.Result.msg.line
                    # Send a PanJob object down the pipeline
                    Get-PanJob -Device $DeviceCur -Id $Response.Result.job
                    }
                    # No pending changes
                    else {
                        Write-Warning $Response.Message
                    }
                }
                # If request to commit did not succeed.
                else {
                    Write-Error ('Commit/Validate request failed. Status: {0} Code: {1} Message: {2}' -f $Response.Status,$Response.Code,$Response.Message)
                }
            } # else Any other ParameterSetName
        } # foreach $DeviceCur
    } # Process block
    End {
    } # End block
} # Function
