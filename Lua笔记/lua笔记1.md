# lua学习笔记 

`write by maxx`

* [系统时间](#systemTime)
* [闭包](#closure)
* [字符串](#string)
* [table的一些操作](#LuaTable)
	* [取长度](#tableLength)
	* [插入和删除](#tableOP)
	* [排序](#tableSort)
	* [连接](#tableConcat)
* [尾调用](#LuaTailCall)
* [泛型for](#LuaFor)
* [require](#LuaRequire)
* [协程](#LuaCroutine)

<h2 id="systemTime">**系统时间**</h2>

```
local iNowTime = os.date("*t")
local iLeftDay = 8 - iNowTime.wday
if iLeftDay == 7 then
    iLeftDay = 0
end
local iLeftHour = 0 - iNowTime.hour
local iLeftMin = 0 - iNowTime.min
if iLeftMin < 0 then
    iLeftMin = iLeftMin + 60
    iLeftHour = iLeftHour - 1
end
if iLeftHour < 0 then
    iLeftHour = iLeftHour + 24
    iLeftDay = iLeftDay - 1
end
```
<h2 id="closure">**闭包**</h2>

lua内部的函数体可以访问外部的局部变量，在函数内部我们将称之为外部的局部变量upvalue

<h2 id="string">**字符串**</h2>

`string.find(Moban, sonStr)`
```
string.find(Moban, sonStr) --> s, e
	第一次匹配的起，终位置
```
`string.format()`
```
类似sprintf()
	string.format() 第一个参数为字符串格式，后面的参数可以任意多个，用于填充第一个参数中的格式控制符，最后返回完整的格式化后的字符串
		格式控制符以%开头，常用的有以下几种  
	%s 接受一个字符串并按照给定的参数格式化该字符串 %d    - 接受一个数字并将其转化为有符号的整数格式 
	%f 接受一个数字并将其转化为浮点数格式(小数)，默认保留6位小数，不足位用0填充 
	%x 接受一个数字并将其转化为小写的十六进制格式 %X    - 接受一个数字并将其转化为大写的十六进制格式

	例:
	str = string.format("字符串：%s\n整数：%d\n小数：%f\n十六进制数：%X","qweqwe",1,0.13,348)
```
`unpack()`
```
	npack(list [, i [, j]])
	return list[i], list[i+1], ... , list[j]
	注意不是返回组合字符串，而是返回多个结果值！
```

<h2 id="LuaTable">**table的一些操作**</h2>

<h3 id="tableLength">**取table长度**</h3>

`#table`
```
table t 的长度被定义成一个整数下标 n 。它满足 t[n] 不是 nil 而 t[n+1] 为 nil；此外，如果 t[1] 为 nil ，n 就可能是零。
```
`table.maxn()`
```
返回最大数字key
```
`getn`
```
然而我并不知道这个是什么^_^
但是对于数组而言，getn就是取数组大小
```
<h3 id="tableOP">**table的插入和删除**</h3>

* 插入
```
table.insert(table, pos, value)
table.insert(table, value) --队尾
```

* 删除
```
table.remove(table, pos)
pos为空的时候，则默认队尾
<font color="red">返回删除元素值</font>
```

<font color="red">返回删除元素值</font>

<h3 id="tableSort">**table排序**</h3>
```
table.sort(table, cmp)
```

<h3 id="tableConcat">**连接**</h3>
```
table.concat(bable, sep, start, end)
sep:隔开符号
start:默认1
end：默认总长
```


<h2 id="LuaTailCall">**尾调用**</h2>

个人感觉就是不调用，和闭包的特性一起用，很神奇

<h2 id="LuaFor">**泛型for**</h2>

```
for <var-list> in <exp-list> do
	<body>
end
```

* 初始化，计算in后面表达式的值，表达式应该返回范性for需要的三个值：迭代函数，状态常量和控制变量；与多值赋值一样，如果表达式返回的结果个数不足三个会自动用nil补足，多出部分会被忽略。
* 将状态常量和控制变量作为参数调用迭代函数（注意：对于for结构来说，状态常量没有用处，仅仅在初始化时获取他的值并传递给迭代函数）。
* 将迭代函数返回的值赋给变量列表。
* 如果返回的第一个值为nil循环结束，否则执行循环体。
* 回到第二步再次调用迭代函数。

`for var_1, ..., var_n in explist do block end 等价`

```
do
    local _f, _s, _var = explist
    while true do
        local var_1, ... , var_n = _f(_s, _var)
        _var = var_1
        if _var == nil then break end
        block
    end
end
如果我们的迭代函数是f，状态常量是s，控制变量的初始值是a0，那么控制变量将循环：a1=f(s,a0)、a2=f(s,a1)、⋯⋯，直到ai=nil。
```

<h2 id="LuaRequire">**require**</h2>

`http://blog.csdn.net/aisajiajiao/article/details/19332397`

* 机制
```
--require 函数的实现  
function require(name)  
    if not package.loaded[name] then  
        local loader = findloader(name) //这一步演示在代码中以抽象函数findloader来表示  
        if loader == nil then  
            error("unable to load module" .. name)  
        end  
        package.loaded[name] = true  
        local res = loader(name)  
        if res ~= nil then  
            package.loaded[name] = res  
        end  
    end  
    return package.loaded[name]  
end 
```

* 指定路径
```
package.path = XXX
替换“?”号
```

<h2 id="LuaCroutine">**协程**</h2>

* 状态  
挂起态（suspended） 运行态 停止态（dead）

* 参数传递  
resume会把参数给协程函数  
yield也会把参数给resume函数

