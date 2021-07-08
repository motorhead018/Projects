<#PSScriptInfo

.VERSION 0.0.1

.GUID ee1ba506-ac68-45f8-9f37-4555f1902353

.AUTHOR William Bluhm

.COMPANYNAME @Motorhead018

.COPYRIGHT

.TAGS StartMenu,Taskbar,Layout

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES

.PRIVATEDATA

#>

<# 

.DESCRIPTION 
 SMATLE is a GUI driven tool used to create, update and customize Start Menu and Taskbar layouts. SMATLE works as a stand alone tool.
 
 Version 0.0.1 
 -Began creation of my StartMenu and Taskbar Layout Editor.
 #>

 
#===========================================================================
# SMATLE aka StartMenu and Taskbar Layout Editor
#===========================================================================
#
# Written and maintained by: William Bluhm
# Twitter: @Motorhead018
#
#===========================================================================
#
# SMATLE is a GUI driven tool used to create, update and customize Start Menu and Taskbar layouts. SMATLE works as a stand alone tool.
#
# It currently supports the following functions:
# -Importation of previously created layout.xml files.
# -
#
#################################################
#
# Community Contributions to SMATLE
#################################################
# 
# Donna Ryan - Initial layout of powershell script borrowed with pride from her WIM Witch powershell script.

#============================================================================================================
Param(




)

$SMATLEScriptVer = "0.0.1"

#Your XAML goes here :)
#Create base GUI 
$inputXML = @"
<Window x:Class="SMATLE_Tabbed.MainWindow"
		xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:SMATLE_Tabbed"
        mc:Ignorable="d"
        Title="StartMenu and Taskbar Layout Editor - $SMATLEScriptVer" Height="500" Width="800" Background="#FF610536">
    <Grid>
        



"
