#!/usr/bin/env python
# -*- coding: utf-8 -*-

__author__ = 'maxx'
#thanks for Peter Fan


import os
import os.path
import time
import shutil
import subprocess
import sys

#原工程的工程名字
__preProjectName__ = 'AuroraGame'
#现在工程取的名字
__nowProjectName__ = 'jjsg'
#原工程的几个关键目录
projectDict = {\
'resourcesDir' : 'Resources',\
'dllDir' : r'proj.win32\Debug.win32',\
'exeFile' : r'proj.win32\Debug.win32\ACTGame.exe'\
}

selfDir = os.getcwd()


#包名
packageName = __nowProjectName__ + time.strftime('_win32_debug_%Y_%m_%d_1')
print 'please input your package number, default number is the smallest in numbers not seen'
packageNumber = raw_input()
if packageNumber.isdigit():
	packageName = __nowProjectName__ + time.strftime('_win32_debug_%Y_%m_%d_')
	packageName = packageName + packageNumber
else:
	packageNamePre = __nowProjectName__ + time.strftime('_win32_debug_%Y_%m_%d_')
	for x in range(1, 100):
		if not os.path.exists(packageNamePre + ('%d' % x)):
			packageName = packageNamePre + ('%d' % x)
			break
	else:
		print 'there is too many package, please clear up somes'
		sys.exit()

print packageName


#生成的包的目录相关
jjsgDir = os.path.join(selfDir, packageName)
jjsgDllDir = jjsgDir
jjsgResourcesDir = jjsgDir
jjsgExeDir = jjsgDir

#tools文件夹所在的目录
toolsDir = os.path.abspath(os.path.join(selfDir, os.path.pardir))

#原工程目录
projectDir = os.path.join(toolsDir, __preProjectName__)
resourcesDir = os.path.join(projectDir, projectDict['resourcesDir'])
dllDir = os.path.join(projectDir, projectDict['dllDir'])
exeDir = os.path.join(projectDir, projectDict['exeFile'])

#print projectDir
#print resourcesDir
#print dllDir
#print exeDir

#7za.exe 的路径
file7za = os.path.join(selfDir, '7z', '7za.exe')
#print file7za

def copyExe():
	print 'copy exe start...'
	exeFile = exeDir
	if os.path.exists(exeFile):
		shutil.copy(exeFile, jjsgDir)
		print 'copy exe success'
	else:
		print 'the exeFile can\'t find, please check the exeDir'
		sys.exit()

def copyDll():
	print 'copy dll start...'
	if os.path.exists(dllDir):
		for file in os.listdir(dllDir):
			a, b = os.path.splitext(file)
			if(b == '.dll'):
				dllFile = os.path.join(dllDir, file)
				shutil.copy(dllFile, jjsgDllDir)
		print 'copy dll success'
	else:
		print 'the dllDir can\'t find, please check the dllDir'
		sys.exit()

def copyFiles(sourceDir, targetDir):
	if not os.path.exists(sourceDir):
		print 'the sourceDir can\'t find, please check the dir'
		sys.exit()
		return

	for file in os.listdir(sourceDir):
		sourceFile = os.path.join(sourceDir, file)
		targetFile = os.path.join(targetDir, file)
		if os.path.isfile(sourceFile):
			if not os.path.exists(targetDir):
				os.makedirs(targetDir)
			if not os.path.exists(targetFile) or ( os.path.exists(targetFile) and (os.path.getsize(sourceFile) != os.path.getsize(targetFile)) ):
				open(targetFile, "wb").write(open(sourceFile, "rb").read())
		if os.path.isdir(sourceFile):
			copyFiles(sourceFile, targetFile)

def create_developer():
	developerFile = os.path.join(jjsgDir, 'ACTGame_developer.bat')
#	print developerFile
	if os.path.exists(developerFile):
		os.remove(developerFile)

#	theStr = 'cd ..\\Resources' + '\n'
	theStr = 'start ..\\' + packageName + '\\ACTGame.exe -developer 960 640'
#	print theStr

	open(developerFile, "wb").writelines(theStr)

def compressProject():
	print 'now is compressing...'
	if not os.path.exists(file7za):
		print 'the 7za.exe can\'t find, please check the file7zaDir'
		sys.exit()
		return

	jjsgPackageZip = os.path.join(selfDir, packageName + '.zip')
	if os.path.exists(jjsgPackageZip):
		os.remove(jjsgPackageZip)

	command = ' '.join([
                "\"%s\"" % file7za,
                "\"a\"",
                "\"%s\"" % jjsgPackageZip,
                "\"%s\"" % jjsgDir
            ])

#	print command

	ret = subprocess.call(command)
	if ret != 0:
		print 'compress fail, please check the Parameters or this is a unknow error'
		sys.exit()
	else:
		print 'compress success'

	


print 'start, please wait...'

#删除原包
if os.path.exists(jjsgDir):
	shutil.rmtree(jjsgDir)

#创建新包目录
print 'create directory'
os.mkdir(jjsgDir)


#拷贝cocos2d的dll    
copyDll()

#拷贝exe
copyExe()

#拷贝resourses目录下的全部文件
print 'copy resourses start...'
print 'there are many file, maybe need some time'
copyFiles(resourcesDir, jjsgResourcesDir)
print 'copy resourses success'

print 'create developer.bat'
create_developer()
print 'create .bat success'

print 'copy end!'



print 'now you can input (y/n) to compress'
isCompression = False
isCompression = raw_input()
if cmp(isCompression, 'y') == 0 :
	compressProject()


print 'the python is end, input anykey to exit'
raw_input()