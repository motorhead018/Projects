#This script can be used to update the TPM firmware on HP devices
#Used in conjunction with the PDF "A User Guide for TPM Config and HpqPswd.pdf"

#Command line syntax: TpmConfig -s -aTPMSpecVersion -pBiosPasswordFile

tpmconfig64.exe -s -a2.0 -p