BeforeAll {
   $ModuleName = "PowerPAN"
   $Here = Split-Path -Path $PSCommandPath -Parent   
}

Describe -Tag ('Unit','Acceptance') $("$ModuleName Module Tests") {
   Context 'Module Setup' {
      It "Has root module $ModuleName.psm1" {
         Join-Path -Path $Here -ChildPath "$ModuleName.psm1" | Should -Exist
      }

      It "Has manifest file $ModuleName.psd1" {
         Join-Path -Path $Here -ChildPath "$ModuleName.psd1" | Should -Exist
         Join-Path -Path $Here -ChildPath "$ModuleName.psd1" | Should -FileContentMatch "$ModuleName.psm1"
      }

      It "$ModuleName class files exist in Class directory" {
         Join-Path -Path $Here -ChildPath "Class/*.ps1" | Should -Exist
      }

      It "$ModuleName Format.ps1xml files exist in Format directory" {
         "$Here\Format\*.Format.ps1xml" | Should -Exist
      }

      It "$ModuleName private function files exist in Private directory" {
         "$Here\Private\*.ps1" | Should -Exist
      }

      It "$ModuleName public function files exist in Public directory" {
         "$Here\Public\*.ps1" | Should -Exist
      }

      It "$ModuleName.psm1 is valid PowerShell code" {
         $FileContent = Get-Content -Path "$Here\$ModuleName.psm1" -ErrorAction Stop
         $Errors = $null
         $null = [System.Management.Automation.PSParser]::Tokenize($FileContent, [ref]$Errors)
         $Errors.Count | Should -Be 0
      }
   } # Context 'Module Setup'
}
