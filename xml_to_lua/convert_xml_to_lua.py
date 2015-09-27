import os
import shutil
#import platform

#compress cmd in muti platform
#os_platform = platform.system()

exec_cmd_path_pattern = "xml2table "

xml_file_name_list = [
    "vip",
    "activity",
]

def get_config_dir():
    config_dir = '../../AuroraGame/res/config'
    return config_dir

def get_lua_dir():
    config_dir = '../../AuroraGame/src/luaScript/config/xml'
    return config_dir

config_path = get_config_dir()
lua_path = get_lua_dir()
for file_name in xml_file_name_list:
    xml_file = file_name + '.xml'
    lua_file = file_name + '.lua'
    xml_file = os.path.join(config_path, xml_file)
    lua_file = os.path.join(lua_path, lua_file)
    print 'convert %s to %s' %(xml_file, lua_file)
    os.popen(exec_cmd_path_pattern + xml_file + ' ' + lua_file, 'r')