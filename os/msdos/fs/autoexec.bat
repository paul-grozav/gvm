:: ========================================================================== ::
:: Author: Tancredi-Paul Grozav <paul@grozav.info>
:: ========================================================================== ::
@ECHO OFF
echo # =========================================================================== #
echo Tancredi-Paul Grozav ^<paul@grozav.info^>
set PATH=%PATH%;C:\FREEDOS;C:\mtcp;
:: Initialize network
:: net initialize
:: nwlink
:: net start
set MTCPCFG=C:\mtcp\mtcp.cfg
C:\mtcp\ne2000.com 0x60
C:\mtcp\dhcp.exe
echo # =========================================================================== #
:: ========================================================================== ::
