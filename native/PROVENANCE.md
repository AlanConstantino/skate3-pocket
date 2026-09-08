# Native proxy source provenance

The official v0.1.19 libmain.so is not an input to compilation and is not
patched. The APK assembly must copy it byte-for-byte and verify SHA-256:
`5c952868cf4e5b15a6e6d6b228adf83c6b3633884ba0237f28264af4e5796a39`.

`vendor/libadrenotools` was copied from the clean local checkout of
https://github.com/bylaws/libadrenotools at
`8fae8ce254dfc1344527e05301e43f37dea2df80`.
Its `lib/linkernsbypass` submodule is
https://github.com/bylaws/liblinkernsbypass at
`aa3975893d83ef1bc84c321ec60c65fbf1287887`.
Git metadata was excluded. Vendored source and license files are unchanged.

The proxy uses only ADRENOTOOLS_DRIVER_CUSTOM. The GPU turbo, guest-memory
mapping and BCn modification options are not enabled.

Java must load the absolute nativeLibraryDir/libvulkan.so path and initialize
it before loading the official libmain.so. Native libraries must be extracted
(`useLegacyPackaging=true`). Driver files must be in app-private storage.
The process must restart to change the selected driver.

The custom path verifies a surface-free instance first and refuses to proceed
unless every enumerated physical device identifies its driver as Mesa Turnip.
The engine's vkCreateInstance calls are also checked and logged. Errors do not
silently select System Driver. The platform loader is retained for the process
lifetime, matching the selected driver's lifetime.
