# PreStart-UI

This is an SCCM task sequence pre-start GUI intended to capture data relevant to the post-OSD use of the PC. The GUI presents options to label the computer with Department, Category, and Function, which  is then stamped in the registry after OSD. This information is automatically inventoried in SCCM as an Installed Software and can be used to create device collections. This script has one variant for PE and another for within Windows, as indicated by the name. 

PreStart_PE provides the option to clean the hard drive (helpful in avoiding errors imaging a device with non-bitlocker encryption), maintaning direct associations after OSD, and configuring the PC as an autologon device using a domain account. 

PreStart_Windows provides the option to backup user data before OSD, maintan direct associations after OSD, and configure the PC as an autologon device using a domain account. 
