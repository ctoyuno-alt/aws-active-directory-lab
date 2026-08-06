Describe "PowerShell Script Syntax Validation" {
    $scriptFiles = Get-ChildItem -Path "$PSScriptRoot/../../powershell" -Recurse -Filter "*.ps1"

    It "Should find PowerShell script files" {
        $scriptFiles.Count | Should -BeGreaterThan 0
    }

    Context "Script Syntax" {
        foreach ($file in $scriptFiles) {
            It "Script '$($file.Name)' should parse without syntax errors" {
                $errors = $null
                $tokens = $null
                [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
                $errors.Count | Should -Be 0
            }
        }
    }
}
