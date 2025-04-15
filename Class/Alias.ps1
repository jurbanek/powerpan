# Define aliases using Set-Alias here
# Advanced Function [Alias()] blocks do NOT make it to Global scope. Need to use Set-Alias instead.

# Get-PanObject
Set-Alias -Name Get-PanAddress -Value Get-PanObject -Scope Global

# Rename-PanObject
Set-Alias -Name Rename-PanAddress -Value Rename-PanObject -Scope Global

# Move-PanObject
Set-Alias -Name Move-PanAddress -Value Move-PanObject -Scope Global

# Remove-PanObject
Set-Alias -Name Remove-PanAddress -Value Remove-PanObject -Scope Global

# Copy-PanObject
Set-Alias -Name Copy-PanAddress -Value Copy-PanObject -Scope Global
