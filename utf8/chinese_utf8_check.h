#ifndef __CHINESE_UTF8_ILL__
#define __CHINESE_UTF8_ILL__

#include <string>
#include <vector>
#include <algorithm>

class CTCUTF8Handle
{
public:
    typedef uint32_t char_encoding_type;

    typedef struct char_encoding_data_s
    {
        uint8_t                 m_ucCharByteNum;
        char_encoding_type      m_uiEncodingINT;
    }char_encoding_data_t;

public:
    /**
     * @desc:通过UTF-8字符的第一个字节判断怎么字符所占字节数
     * @param ucChar,字符第一个字节
     * @return int,字符所占字节数
     */
    static int32_t GetByteNumOFWord(unsigned char ucChar)
    {
        if((ucChar & 0x80) != 0)
        {
            if(((ucChar & 0xF0) ^ 0xF0) == 0)
            {
                return (4);
            }

            if(((ucChar & 0xE0) ^ 0xE0) == 0)
            {
                return (3);
            }

            if(((ucChar & 0xC0) ^ 0xC0) == 0)
            {
                return (2);
            }

            return (-1);
        }
        else
        {
            return (1);
        }
    }
    /**
     * 把UTF-8字符序列编码成整形序列
     * @param strStr,UTF-8字符序列
     * @param stEncodedArray,整形序列
     */
    static void EncodeWordsToIntArray(const std::string& strStr, std::vector<char_encoding_data_t>& stEncodedArray)
    {
        size_t uiIndex = 0;

        char_encoding_data_t stEncodingData;
        while(uiIndex < strStr.size())
        {
            uint32_t uiCode = 0;
            int32_t iByteNum = GetByteNumOFWord((unsigned char)strStr[uiIndex]);
            if(iByteNum <= 0)
            {
                uiIndex ++;
                continue;
            }
            else if(1 == iByteNum)
            {
                uiCode = (uiCode << 8) + ((unsigned int)strStr[uiIndex] & 0xFF);
            }
            else if(2 == iByteNum)
            {
                uiCode = (uiCode << 8) + ((unsigned int)strStr[uiIndex] & 0xFF);
                uiCode = (uiCode << 8) + ((unsigned int)strStr[uiIndex + 1] & 0xFF);
            }
            else if(3 == iByteNum)
            {
                uiCode = (uiCode << 8) + ((unsigned int)strStr[uiIndex] & 0xFF);
                uiCode = (uiCode << 8) + ((unsigned int)strStr[uiIndex + 1] & 0xFF);
                uiCode = (uiCode << 8) + ((unsigned int)strStr[uiIndex + 2] & 0xFF);
            }
            else if(4 == iByteNum)
            {
                uiCode = (uiCode << 8) + ((unsigned int)strStr[uiIndex] & 0xFF);
                uiCode = (uiCode << 8) + ((unsigned int)strStr[uiIndex + 1] & 0xFF);
                uiCode = (uiCode << 8) + ((unsigned int)strStr[uiIndex + 2] & 0xFF);
                uiCode = (uiCode << 8) + ((unsigned int)strStr[uiIndex + 3] & 0xFF);
            }

            stEncodingData.m_ucCharByteNum = iByteNum;
            stEncodingData.m_uiEncodingINT = uiCode;
            stEncodedArray.push_back(stEncodingData);
            uiIndex += (size_t)iByteNum;
        }
    }
};

class CIllegalChineseUTF8Char
{
public:
    typedef struct unicode_illegal_char_s
    {
        unsigned int uiStart;
        unsigned int uiEnd;
    }chinese_illegal_unicode_char_t;

    /**
     * 检查字符串是否有非法字符
     */
    static bool CheckStringHasIllegalChar(const std::string& iStr);

private:
    /**
     * 把unicode转换为UTF8
     */
    int32_t ConvUnicode2UTF8Encoding(unsigned int uiUnicode, unsigned int& uiUTF8)
    {
        if(uiUnicode <= 0x0000007F)
        {
            // * U-00000000 - U-0000007F:  0xxxxxxx
            uiUTF8 = uiUnicode & 0x7F;

            return (1);
        }
        else if((uiUnicode >= 0x00000080) && (uiUnicode <= 0x000007FF))
        {
            // * U-00000080 - U-000007FF:  110xxxxx 10xxxxxx
            uiUTF8 = ((uiUnicode >> 6) & 0x1F) | 0xC0;

            uiUTF8 = (uiUTF8 << 8) + ((uiUnicode & 0x3F) | 0x80);

            return (2);
        }
        else if((uiUnicode >= 0x00000800) && (uiUnicode <= 0x0000FFFF))
        {
            // * U-00000800 - U-0000FFFF:  1110xxxx 10xxxxxx 10xxxxxx
            uiUTF8 = ((uiUnicode >> 12) & 0x0F) | 0xE0;

            uiUTF8 = (uiUTF8 << 8) + (((uiUnicode >>  6) & 0x3F) | 0x80);

            uiUTF8 = (uiUTF8 << 8) + ((uiUnicode & 0x3F) | 0x80);

            return (3);
        }
        else if((uiUnicode >= 0x00010000) && (uiUnicode <= 0x001FFFFF))
        {
            // * U-00010000 - U-001FFFFF:  11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
            uiUTF8 = ((uiUnicode >> 18) & 0x07) | 0xF0;

            uiUTF8 = (uiUTF8 << 8) + (((uiUnicode >> 12) & 0x3F) | 0x80);

            uiUTF8 = (uiUTF8 << 8) + (((uiUnicode >>  6) & 0x3F) | 0x80);

            uiUTF8 = (uiUTF8 << 8) + ((uiUnicode & 0x3F) | 0x80);

            return (4);
        }

        return 0;
    }
    /**
     * 根据unicode编码的iIllSet构造UTF8的illset
     */
    void BuildIllegalSet(std::vector<uint32_t>& stIllegalCharSet)
    {
        chinese_illegal_unicode_char_t iIllSet[] = {
            { 0x00A9, 0x00A9 },
            { 0x00AE, 0x00AE },
            { 0x203C, 0x203C },
            { 0x2049, 0x2049 },
            { 0x2122, 0x2122 },
            { 0x2139, 0x2139 },
            { 0x2194, 0x2199 },
            { 0x21A9, 0x21AA },
            { 0x231A, 0x231B },
            { 0x23E9, 0x23EC },
            { 0x23F0, 0x23F0 },
            { 0x23F3, 0x23F3 },
            { 0x25AA, 0x25AB },
            { 0x25B6, 0x25B6 },
            { 0x25C0, 0x25C0 },
            { 0x25FB, 0x2601 },
            { 0x260E, 0x260E },
            { 0x2611, 0x2611 },
            { 0x2614, 0x2615 },
            { 0x261D, 0x261D },
            { 0x263A, 0x263A },
            { 0x2648, 0x2653 },
            { 0x2660, 0x2660 },
            { 0x2663, 0x2663 },
            { 0x2665, 0x2666 },
            { 0x2668, 0x2668 },
            { 0x267B, 0x267B },
            { 0x267F, 0x267F },
            { 0x2693, 0x2693 },
            { 0x26A0, 0x26A1 },
            { 0x26AA, 0x26AB },
            { 0x26BD, 0x26BE },
            { 0x26C4, 0x26C5 },
            { 0x26CE, 0x26CE },
            { 0x26D4, 0x26D4 },
            { 0x26EA, 0x26EA },
            { 0x26F2, 0x26F3 },
            { 0x26F5, 0x26F5 },
            { 0x26FA, 0x26FA },
            { 0x26FD, 0x26FD },
            { 0x2934, 0x2935 },
            { 0x2B05, 0x2B07 },
            { 0x2B1B, 0x2B1C },
            { 0x2B50, 0x2B50 },
            { 0x2B55, 0x2B55 },
            { 0x3030, 0x3030 },
            { 0x303D, 0x303D },
            { 0x3297, 0x3297 },
            { 0x3299, 0x3299 },
            { 0x1F004, 0x1F004 },
            { 0x1F0CF, 0x1F0CF },
            { 0x1F300, 0x1F5FF },

            { 0xFF00, 0xFFEF },
            { 0x2E80, 0x2EFF },
            { 0x3000, 0x303F },
            { 0x31C0, 0x31EF },
            { 0x2F00, 0x2FDF },
            { 0x2FF0, 0x2FFF },
            { 0x3100, 0x312F },
            { 0x31A0, 0x31BF },
            { 0x3040, 0x309F },
            { 0x30A0, 0x30FF },
            { 0x31F0, 0x31FF },
            { 0xAC00, 0xD7AF },
            { 0x1100, 0x11FF },
            { 0x3130, 0x318F },
            { 0x4DC0, 0x4DFF },
            { 0xA000, 0xA4CF },
            { 0x2800, 0x28FF },
            { 0x3200, 0x33FF },
            { 0x2600, 0x27BF },
            { 0xFE10, 0xFE1F },

            { 0xFE30, 0xFE4F },
            { 0x24C2, 0x24C2 },
            { 0x2702, 0x27B0 },
            { 0x1F170, 0x1F251 },
            { 0x1F601, 0x1F64F },
            { 0x1F680, 0x1F6C0 },
            { 0x1F600, 0x1F636 },
            { 0x1F681, 0x1F6C5 },
            { 0x1F30D, 0x1F567 },
            //▁▂▃▄▅▆▇█▉▊
            { 0x2581, 0x258A}
        };

        stIllegalCharSet.clear();
        size_t uiIllegalWordSet = sizeof(iIllSet) / sizeof(chinese_illegal_unicode_char_t);
        for(size_t i = 0; i < uiIllegalWordSet; i ++)
        {
            for(unsigned int j = iIllSet[i].uiStart; j <= iIllSet[i].uiEnd; j ++)
            {
                unsigned int uiCharEncoding;
                int iRet = ConvUnicode2UTF8Encoding(j, uiCharEncoding);
                if(0 == iRet)
                {
                    continue;
                }

                stIllegalCharSet.push_back(uiCharEncoding);
            }
        }
    }
};


bool CIllegalChineseUTF8Char::CheckStringHasIllegalChar(const std::string& iStr)
{
    // 得到输入string的UTF8编码，存入iStrUTF8Set
    std::vector<CTCUTF8Handle::char_encoding_data_t> iStrUnicodeSet;
    CTCUTF8Handle::EncodeWordsToIntArray(iStr, iStrUnicodeSet);
    std::vector<uint32_t> iStrUTF8Set;
    for(size_t i = 0, n = iStrUnicodeSet.size(); i < n; i ++)
    {
        iStrUTF8Set.push_back(iStrUnicodeSet[i].m_uiEncodingINT);
    }

    class CIllegalChineseUTF8Char iCheckUTF8;

    std::vector<uint32_t> stIllegalCharSet;
    iCheckUTF8.BuildIllegalSet(stIllegalCharSet);

    std::sort(iStrUTF8Set.begin(), iStrUTF8Set.end());
    std::sort(stIllegalCharSet.begin(), stIllegalCharSet.end());

    size_t iSize_iStrUTF8Set = iStrUTF8Set.size();
    size_t iSize_stIllegalCharSet = stIllegalCharSet.size();

    for(size_t i = 0, j = 0; i < iSize_iStrUTF8Set && j < iSize_stIllegalCharSet; )
    {
        if (iStrUTF8Set[i] == stIllegalCharSet[j])
            return true;
        if (iStrUTF8Set[i] > stIllegalCharSet[j])
            j = j + 1;
        else
            i = i + 1;
    }

    return false;
}

#endif /* __CHINESE_UTF8_ILL__ */