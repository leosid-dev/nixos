##Nixos declarative config with minimalistic approach but agnostic architecture
  - Use flakes with uptodate schema with unstable and stable version pinning
  - use home manager via flakes for user config
  - the module architecture's intent should be balanced on its categorization and configurability
  - ask before making any sensible selections on your own with pros/con context 
  
####Phase-1(Flakes and module development)
  - Flakes toplevel should be agnostic to system/host configuration and user management(hm) and maintain a modular/layered architecture(ASPECT-ORIENTED)
  - Modules make use of pure functions as much as possible for robust evaluations and use layered architecture for customizability(ASPECT-ORIENTED)
  - Start with system configuration with a neat sensible defaults
  - use niri as compositor, noctalia v5 for shell and login management via hm
  - add minimal sensible system packages with unstable/stable selection for packages
  - ADD/SET ALL THE ENVIRONMENT VARIABLES/PACKAGES REQUIRED FOR UNIFORM USER EXPERIENCE INTEGRATION (like shell, themes, fonts, portals, compositors and window manager compatabilities, etc)
  
####Phase-2(Customized hardware configuration and utilities for controlling performance/efficiency characteristics)
  - probe the current system - Lenovo Thinkbook 16 ARP - ryzen 7 7735hs, 680m igpu, 16 gigs ram. probe and enumerate all the relevant system resources for exact specs
  - ensure all the drivers and kernel modules required are declared (main system, acpi, chipset, pci peripherals, storage(ssd), thunderbolt/usb4, wifi/bluetooth ,etc.. (only applicable ones))
  - the sound experience is worse than windows due to absence of dolby support. need a novel way (either via alsa, pipewire with pulse support to mitigate this performance degradation)
