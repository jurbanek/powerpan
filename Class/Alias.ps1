# Define aliases using Set-Alias here
# Advanced Function [Alias()] blocks do NOT make it to Global scope. Need to use Set-Alias instead.

# Get-PanObject
Set-Alias -Name Get-PanAddress -Value Get-PanObject -Scope Global
Set-Alias -Name Get-PanService -Value Get-PanObject -Scope Global
Set-Alias -Name Get-PanAddressGroup -Value Get-PanObject -Scope Global
Set-Alias -Name Get-PanServiceGroup -Value Get-PanObject -Scope Global

# Rename-PanObject
Set-Alias -Name Rename-PanAddress -Value Rename-PanObject -Scope Global
Set-Alias -Name Rename-PanService -Value Rename-PanObject -Scope Global
Set-Alias -Name Rename-PanAddressGroup -Value Rename-PanObject -Scope Global
Set-Alias -Name Rename-PanServiceGroup -Value Rename-PanObject -Scope Global

# Move-PanObject
Set-Alias -Name Move-PanAddress -Value Move-PanObject -Scope Global
Set-Alias -Name Move-PanService -Value Move-PanObject -Scope Global
Set-Alias -Name Move-PanAddressGroup -Value Move-PanObject -Scope Global
Set-Alias -Name Move-PanServiceGroup -Value Move-PanObject -Scope Global

# Remove-PanObject
Set-Alias -Name Remove-PanAddress -Value Remove-PanObject -Scope Global
Set-Alias -Name Remove-PanService -Value Remove-PanObject -Scope Global
Set-Alias -Name Remove-PanAddressGroup -Value Remove-PanObject -Scope Global
Set-Alias -Name Remove-PanServiceGroup -Value Remove-PanObject -Scope Global

# Copy-PanObject
Set-Alias -Name Copy-PanAddress -Value Copy-PanObject -Scope Global
Set-Alias -Name Copy-PanService -Value Copy-PanObject -Scope Global
Set-Alias -Name Copy-PanAddressGroup -Value Copy-PanObject -Scope Global
Set-Alias -Name Copy-PanServiceGroup -Value Copy-PanObject -Scope Global

# Construct-PanObject (unapproved verb given unique semantics)
Set-Alias -Name Construct-PanAddress -Value Construct-PanObject -Scope Global
Set-Alias -Name Construct-PanService -Value Construct-PanObject -Scope Global
Set-Alias -Name Construct-PanAddressGroup -Value Construct-PanObject -Scope Global
Set-Alias -Name Construct-PanServiceGroup -Value Construct-PanObject -Scope Global
