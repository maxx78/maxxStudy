/* 得到unicode编码 */
#include <stdlib.h>
#include <stdio.h>
#include <wchar.h>
#include <locale.h>
  
#define MAX_NUM 100  
  
int main()  
{  
    int nLen=0;  
    int i;  
    char str[MAX_NUM]={0};  
    wchar_t wstr[MAX_NUM]={0};  
      
  
    printf("Please Input your string: ");  
    scanf("%s",str);  
  
    setlocale(LC_ALL,"chs");        //设置本地化语言为简体中文  
    mbstowcs(wstr,str,MAX_NUM);     //转化为宽字符  
  
    nLen=wcslen(wstr)+1;            //加上最后结束符 /0  
  
    for(i=0;i<nLen; i++)  
    {  
        printf("0x%04x/t",wstr[i]);  
    }  
    printf("/n");  
  
    return 0;  
} 