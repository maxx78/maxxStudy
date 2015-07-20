#!/usr/bin/env python
# -*- coding: utf-8 -*-


#原工程的工程名字
__preProjectName__ = 'AuroraGame'
#sln在原工程的路径
__slnFileDir__ = r'proj.win32\ACTGame.sln'

#build模式 'Debug' 'Release'
build_mode = 'Debug'
#target
targetName = 'ACTGame'

job_number = 4

import os
import os.path
import shutil
import subprocess
import re
import sys
if sys.platform == 'win32':
    import _winreg


def _get_msbuild_version():
    try:
        reg_path = r'SOFTWARE\Microsoft\MSBuild'

        reg_key = _winreg.OpenKey(
            _winreg.HKEY_LOCAL_MACHINE,
            reg_path
        )

        try:
            i = 0
            while True:
                reg_subkey = _winreg.EnumKey(reg_key, i)
                yield reg_subkey
                i += 1
        except:
            pass

    except WindowsError as e:
        message = "MSBuild is not installed yet!"
        print(e)

def _get_newest_msbuild_version():
    newest_version = None
    newest_version_number = 0

    version_pattern = re.compile('(\\d+)\\.(\\d+)')

    for version in _get_msbuild_version():
        if version:
            match = version_pattern.match(version)
            if match:
                version_number = int(match.group(1)) * 10 + int(match.group(2))
                if version_number > newest_version_number:
                    newest_version_number = version_number
                    newest_version = version

    return newest_version

def _get_msbuild_path():
    newest_msbuild_version = _get_newest_msbuild_version()

    if newest_msbuild_version:
        reg_path = r'SOFTWARE\Microsoft\MSBuild\ToolsVersions\%s' % newest_msbuild_version
        reg_key = _winreg.OpenKey(
            _winreg.HKEY_LOCAL_MACHINE,
            reg_path
        )

        reg_value, reg_value_type = _winreg.QueryValueEx(reg_key, 'MSBuildToolsPath')
        return reg_value

    else:
        return None

if sys.platform != 'win32':
    print 'this is not win32'
    sys.exit()

msbuild_path = _get_msbuild_path()
if msbuild_path == None:
    print 'can\'t find msbuild from reg'
    sys.exit()
else:
    msbuild_path = os.path.join(msbuild_path, 'MSBuild.exe')


if not os.path.exists(msbuild_path):
    print 'can\'t find the msbuild file'
    sys.exit()

#print msbuild_path


toolsDir = os.path.abspath(os.path.join(os.getcwd(), os.path.pardir))
projectDir = os.path.join(toolsDir, __preProjectName__)
slnFile = os.path.join(projectDir, __slnFileDir__)


# '/target:%s' % targetName,
# print targetName
# raw_input()

build_command = ' '.join([
    '\"%s\"' % msbuild_path,
    '\"%s\"' % slnFile,
    '/property:Configuration=%s' % build_mode,
    '/maxcpucount:%s' % job_number
    ])

#print build_command

ret = subprocess.call(build_command)

if ret != 0:
    print 'build fail, this is a unknow error'
    sys.exit()
else:
    print 'build success'

print 'please input anykey to exit'
raw_input()

