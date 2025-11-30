Changelog
=========

v0.2.18
-------

- `Import-PuTTYSession`: Settings which take a path now expand environment variables  
  Applies to the following settings:
  - `/connection/ssh/auth/authKeyFile`
  - `/connection/ssh/auth/authCertFile`
  - `/connection/ssh/auth/gssapiCustomLib`
  - `/connection/ssh/x11/x11AuthFile`
  - `/logging/path`
  - `/terminal/bell/customAction`

  Using this feature currently breaks round-trip exports to JSON as the environment variables will be expanded in the exported session (i.e. the exported file will differ from the imported file).

v0.2.17
-------

- Add support for PuTTY v0.83 and use as default version

v0.2.16
-------

- `Import-PuTTYSession`: Fix import from registry when only a single session is present

v0.2.15
-------

- Add support for PuTTY v0.82 and use as default version

v0.2.14
-------

- Add support for PuTTY v0.81 and use as default version

v0.2.13
-------

- Add support for PuTTY v0.80 and use as default version

v0.2.12
-------

- Add support for PuTTY v0.79 and use as default version

v0.2.11
-------

- *PowerShell 5.x compatibility fixes*
  - Perform JSON indentation ourselves before saving
  - Don't write a UTF-8 BOM when saving JSON sessions
  - Remove JSON comments before deserialising
  - Remove usage of `-NoEnumerate` in `ConvertFrom-Json`
- Fix handling where import path has no sessions
- Add additional enum values for `ProxyMethod`

v0.2.10
-------

- Add support for PuTTY v0.78 and use as default version

v0.2.9
------

- Fix incorrect parameter type when processing inherited sessions

v0.2.8
------

- Minor code clean-up & developer tooling improvements

v0.2.7
------

- Add support for PuTTY v0.77 and use as default version

v0.2.6
------

- Add progress bar support to all commands

v0.2.5
------

- Add support for PuTTY v0.76 and use as default version

v0.2.4
------

- Add support for PuTTY v0.75 and use as default version

v0.2.3
------

- Create the saved sessions registry key on import if necessary

v0.2.2
------

- Fix broken catch statements on `ItemNotFoundException` due to unqualified name

v0.2.1
------

- Fix *PSPuTTYCfg* typos in `README.md`

v0.2.0
------

- Initial stable release
