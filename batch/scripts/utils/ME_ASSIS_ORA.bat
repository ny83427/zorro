@echo off
title Preparing Oracle database enviroment for ME......

if not defined SID call C:\Users\%username%\Downloads\MFGScripts\Set_Parameters.bat SINGLETEST
rem TODO: add oracle database creation and settings script here

echo We finished all things on oracle database level at : %date% %time%