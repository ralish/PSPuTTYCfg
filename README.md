PSPuTTYCfg
==========

[![pwsh ver](https://img.shields.io/powershellgallery/v/PSPuTTYCfg)](https://www.powershellgallery.com/packages/PSPuTTYCfg)
[![pwsh dl](https://img.shields.io/powershellgallery/dt/PSPuTTYCfg)](https://www.powershellgallery.com/packages/PSPuTTYCfg)
[![license](https://img.shields.io/github/license/ralish/PSPuTTYCfg)](https://choosealicense.com/licenses/mit/)

[![Open in Visual Studio Code](https://open.vscode.dev/badges/open-in-vscode.svg)](https://open.vscode.dev/ralish/PSPuTTYCfg)

A PowerShell module to manage PuTTY sessions on Windows platforms as JSON configurations.

- [Usage](#usage)
- [Requirements](#requirements)
- [Installing](#installing)
- [License](#license)

Usage
-----

The module exports two commands to handle the import and export of PuTTY sessions:

- `Export-PuTTYSession`
- `Import-PuTTYSession`

Both functions support JSON files and the Windows registry as an export destination and import source respectively.

Some simple usage examples:

```posh
# Imports PuTTY sessions from the PuTTY Sessions registry key
$Sessions = Import-PuTTYSession -Registry

# Exports PuTTY sessions in the $Sessions variable to the $HOME\PuTTY directory (the directory must exist)
$Sessions | Export-PuTTYSession -Path $HOME\PuTTY

# Imports PuTTY sessions stored as JSON files in the $HOME\PuTTY directory
$Sessions = Import-PuTTYSession -Path $HOME\PuTTY

# Exports PuTTY sessions in the $Sessions variable, overwriting existing sessions, to the PuTTY Sessions key
$Sessions | Export-PuTTYSession -Registry -Force
```

### Schema support

The JSON configuration is fully documented via an associated [JSON schema](schemas/session.jsonc). JSON configurations exported by the module include a `$schema` key referencing the schema, enabling text completion and configuration validation in editors with JSON schema support (e.g. [Visual Studio Code](https://code.visualstudio.com/)).

### Session inheritance

Where this module really shines is in its support for configuration inheritance. This feature enables you to define PuTTY sessions with their settings populated from a "*hierarchy*" of inherited configurations. If you're managing a large number of PuTTY sessions which are largely the same (very likely!) this capability can let you much more easily manage and modify your session configurations.

Let's walk through an example to best illustrate how this works:

1. Within PuTTY create a saved session with your preferred defaults. We'll assume this session is named "*Defaults*".
2. Import the saved session while excluding settings which match PuTTY's defaults:  
   `$Session = Import-PuTTYSession -Registry -ExcludeDefault -Filter 'Defaults'`
3. Export the session to a JSON configuration file:  
   `$Session | Export-PuTTYSession -Path $HOME`

At this point you should have a `Defaults.json` file in your home directory containing the session configuration excluding default settings.

Now create a session configuration which inherits from this configuration and sets a hostname and username. Create the file `MySession.json` with content:

```json
{
  "$schema": "https://raw.githubusercontent.com/ralish/PSPuTTYCfg/stable/schemas/session.jsonc",
  "inherits": [
    "Defaults"
  ],
  "connection": {
    "host": "my-ssh-connection.network.com",
    "data": {
      "username": "my-user"
    }
  }
}
```

Finally, import this JSON configuration and export it to the Windows registry so PuTTY can use it:

1. Import the JSON sessions located in our home directory:  
   `$Session = Import-PuTTYSession -Path $HOME`
2. Optionally inspect its settings and inheritance hierarchy:  
   `$Session | ? Name -eq 'MySession'`
3. Export the session to the Windows registry for PuTTY:  
   `$Session | ? Name -eq 'MySession' | Export-PuTTYSession -Registry`

Open PuTTY to see your new configuration which will be using the same settings as the *Defaults* configuration (minus those we've overridden).

Multiple inheritance is supported (a single session specifying multiple inherited configurations), as well as recursive resolution of inherited sessions (inherited sessions which themselves inherit sessions). Settings are applied from inherited sessions in the order in which they are processed, with inherited sessions listed earlier having lower precedence than those specified later. Circular inheritance is not supported and will throw an error when detected during session import.

Requirements
------------

- PowerShell 5.0 (or later)

PuTTY is not required to use the module, but it's unlikely to be of much use without it ...

Installing
----------

### PowerShellGet (included with PowerShell 5.0)

The module is published to the [PowerShell Gallery](https://www.powershellgallery.com/packages/PSPuTTYCfg):

```posh
Install-Module -Name PSPuTTYCfg
```

### ZIP File

Download the [ZIP file](https://github.com/ralish/PSPuTTYCfg/archive/stable.zip) of the latest release and unpack it to one of the following locations:

- Current user: `C:\Users\<your.account>\Documents\WindowsPowerShell\Modules\PSPuTTYCfg`
- All users: `C:\Program Files\WindowsPowerShell\Modules\PSPuTTYCfg`

### Git Clone

You can also clone the repository into one of the above locations if you'd like the ability to easily update it via Git.

### Did it work?

You can check that PowerShell is able to locate the module by running the following at a PowerShell prompt:

```posh
Get-Module PSPuTTYCfg -ListAvailable
```

License
-------

All content is licensed under the terms of [The MIT License](LICENSE).
