#!/bin/bash
# ============================================================================ #
# Author: Tancredi-Paul Grozav <paul@grozav.info>
# ============================================================================ #
# 1. On a Windows host, go to :
# https://www.microsoft.com/en-us/software-download/windows10
#   And download the Media creation tool, for example my file is called:
#   MediaCreationTool_22H2.exe
# Accept the license
# What do you want to do? - Create installation media (USB flash drive, DVD or
#   ISO file) for another PC
# Uncheck "Use the recommended options for this PC" and select:
#   Language: English (United States)
#   Edition: Windows 10
#   Architecture: 64-bit (x64)
# Then at "Choose which media to use" choose "ISO file". Choose where to save
#   the .iso file.
# Wait for the download to progress and finish.
# Finish
#
# 2. Download Win10XPE from github:
# https://github.com/ChrisRfr/Win10XPE/archive/refs/heads/master.zip
# Extract the zip with the Windows zip extractor. In the project's folder you
# will see some .7z files, those all form one archive, that we need to extract.
# You will need 7-zip to extract these. Install it from here:
#  https://7-zip.org/download.html
# Open the .7z.001 file with 7-zip and extract the WIN10XPE folder. Then you run
# the WIN10XPE.exe file.
#
# Mount the windows .iso file by right clicking it and selecting Mount.
#
# Inside WIN10XPE.exe select source and pick the virtual DVD drive where your
#   .iso file is mounted. Actually that will fail, saying there is no
#   install.wim image file in the source directory. This is because the iso was
#   created with the MediaCreation tool, which creates a file named install.esd
#   so we will have to convert it.
#
# Run PowerShell as an administrator, then, inside run the command:
# dism /Get-WimInfo /WimFile:E:\sources\install.esd
#   Where E: is the virtual DVD drive created by mounting your windows .iso
#   file.
#   This will show the indexes of the various Windows versions available in that
#   .iso file. Take note on the one you prefer. Say index 6 for "Windows 10 Pro"
#
# In same admin PowerShell, run:
# mkdir C:\data\Win10Source
# dism /Export-Image /SourceImageFile:E:\sources\install.esd /SourceIndex:6 /DestinationImageFile:C:\data\Win10Source\install.wim /Compress:max /CheckIntegrity
#   This will take a while. It will create the C:\data\Win10Source path where it
#   will create the install.wim file that WIN10XPE needs.
#
# Then create the source dir by copying the other files too:
# mkdir C:\data\Win10Source\sources
# move C:\data\Win10Source\install.wim C:\data\Win10Source\sources\
# copy E:\sources\boot.wim C:\data\Win10Source\sources\
#
# Now point your WIN10XPE to the C:\data\Win10Source source folder.
#
# Alternatively we could look into downloading the Windows iso directly from the
#   WIN10XPE program. Or, Open your browser's Developer Tools (press F12), click
#   the Device Toolbar icon (or Ctrl + Shift + M), and select a mobile device
#   (like an iPhone or iPad). Refresh the webpage. Because Microsoft detects a
#   non-Windows mobile user agent, it will bypass the Media Creation Tool
#   prompt and let you download the multi-edition ISO containing install.wim
#   directly.
#
# 3. Once WIN10XPE detected the sources (sources/boot.wim and
#   sources/install.wim), you can configure the build as such:
# WIN10XPE:
#   Build_Core:
#     checked: true
#     Main_Interface:
#       Shell: Explorer
#       WinPE_cache_size: 512MiB
#       Network_Drivers: checked
#   Apps:
#     Components:
#       PowerShell_Core: checked
#     HW_Info:
#       HWinfo: checked
#     System_Tools:
#       XPE_StartUp:
#         XPEStartup.cmd: Customize :Startup_X86 section with your commands.
#   Create_ISO:
#     Image_and_ISO:
#       Max_Compression_Required_for_iPXE: checked
#
# Then just click Play to build it.
#
# It might complain about incompatibilities with win 10 ... continue anyway
# We will need these files it creates:
# Win10XPE\ISO\sources\boot.wim
# WIN10XPE\ISO\boot\boot.sdi
# WIN10XPE\ISO\boot\bcd
#
# boot.wim contains your embedded script (along with the entire Windows PE
# filesystem, registry, and system binaries).
# The other two files never change:
# boot.sdi is a static Microsoft system binary (RAM disk driver structure).
# BCD is a static boot menu configuration file.
#
# Gather files:
# mkdir C:\data\win10_output
# copy C:\data\Win10XPE\ISO\sources\boot.wim C:\data\win10_output\
# copy C:\data\Win10XPE\ISO\boot\boot.sdi C:\data\win10_output\
# copy C:\data\Win10XPE\ISO\boot\bcd C:\data\win10_output\
# ============================================================================ #

# then boot with ipxe from http

# #!ipxe
# dhcp

# # Set server root URL
# set boot-url http://192.168.1.100/winpe

# # Download files to client RAM via HTTP
# kernel ${boot-url}/wimboot
# initrd ${boot-url}/BCD         BCD
# initrd ${boot-url}/boot.sdi    boot.sdi
# initrd ${boot-url}/boot.wim    boot.wim

# # Execute Win10XPE inside RAM
# boot

# uses ~1.4 GiB of RAM
# ============================================================================ #
set -x &&

script_dir="$(cd $(dirname ${0}); pwd)" &&
bin_dir="/home/paul/data/binaries_h313/network/containers/http/boot/FreeDOS" &&
bin_dir="${1}" &&




set +x &&
exit 0
# ============================================================================ #
