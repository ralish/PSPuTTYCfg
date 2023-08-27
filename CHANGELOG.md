Changelog
=========

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
