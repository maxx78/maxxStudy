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
__ProjectName__ = 'MyLuaGame'
#原工程的几个关键目录
projectDict = {\
'srcDir' : 'src',\
'resDir' : 'res',\
'exeDir' : 'runtime\\win32',\
'dllDir' : 'runtime\\win32'\
}

selfDir = os.getcwd()



#包名
packageName = __ProjectName__ + time.strftime('_win32_debug_%Y_%m_%d_1')
print 'please input your package number, default number is the smallest in numbers not seen'
packageNumber = raw_input()
if packageNumber.isdigit():
	packageName = __ProjectName__ + time.strftime('_win32_debug_%Y_%m_%d_')
	packageName = packageName + packageNumber
else:
	packageNamePre = __ProjectName__ + time.strftime('_win32_debug_%Y_%m_%d_')
	for x in range(1, 100):
		if not os.path.exists(packageNamePre + ('%d' % x)):
			packageName = packageNamePre + ('%d' % x)
			break
	else:
		print 'there is too many package, please clear up somes'
		sys.exit()

#print packageName


#生成的包的目录相关
jjsgDir = os.path.join(selfDir, packageName)
jjsgSrcDir = os.path.join(jjsgDir, 'src')
jjsgResDir = os.path.join(jjsgDir, 'res')

#Tools文件夹所在的目录
toolsDir = os.path.abspath(os.path.join(selfDir, os.path.pardir))
#原工程目录
projectDir = os.path.join(toolsDir, __ProjectName__)
srcDir = os.path.join(projectDir, projectDict['srcDir'])
resDir = os.path.join(projectDir, projectDict['resDir'])
cocosDllDir = os.path.join(projectDir, projectDict['dllDir'])
exeDir = os.path.join(projectDir, projectDict['exeDir'])

#print projectDir
#print srcDir
#print resDir
#print cocosDllDir
#print exeDir

#7za.exe 的路径
file7za = os.path.join(selfDir, '7z', '7za.exe')
print file7za

def copyExe():
	print 'copy exe start'
	exeFile = os.path.join(exeDir, __ProjectName__ + '.exe')
	if os.path.exists(exeFile):
		shutil.copy(exeFile, jjsgDir)
		print 'copy exe success'
	else:
		print 'the exeFile can\'t find, please check the exeDir'
		sys.exit()

def copyCocosDll():
	print 'copy cocosDll start'
	if os.path.exists(cocosDllDir):
		for file in os.listdir(cocosDllDir):
			a, b = os.path.splitext(file)
			if(b == '.dll'):
				dllFile = os.path.join(cocosDllDir, file)
				shutil.copy(dllFile, jjsgDir)
		print 'copy cocosDll success'
	else:
		print 'the cocosDllDir can\'t find, please check the cocosDllDir'
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
copyCocosDll()

#拷贝exe
copyExe()

#拷贝src目录下的全部文件
print 'copy src start'
copyFiles(srcDir, jjsgSrcDir)
print 'copy src success'

#拷贝res目录下的全部文件
print 'copy res start'
copyFiles(resDir, jjsgResDir)
print 'copy res success'

print 'copy end!'


print 'nwo you can input (y/n) to compress'
isCompression = False
isCompression = raw_input()
if cmp(isCompression, 'y') == 0 :
	compressProject()


print 'the python is end, input anykey to exit'
raw_input()