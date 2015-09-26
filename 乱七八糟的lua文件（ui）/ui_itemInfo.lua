local ui_itemInfo = class("ui_itemInfo", ui_base)

ui_itemInfo.uiJson = "ui/ItemInfoUI/ItemInfoUI.csb"

g_newestItemInfoUI = nil

local TOTAL_PATH_BUTTON_NUMBER = 4
local MAX_DUNGEON_PATH_NUMBER = 3

function GetItemInfoUI()
    return g_newestItemInfoUI
end

local function GetPathsByItemID(iItemID)
    local ret = {}
    local iIndex = 0

    local function PathHash(path)
        if path.type == "FubenOutput" then
            return path.m_iDungeonType * 1000000 + path.m_iChapterID * 1000 + path.m_iDungeonID
        elseif path.type == "HeCheng" then
            return -10
        elseif path.type == "DailyFuben" then
            return -9
        elseif path.type == "JueDou" then
            return -11
        elseif path.type == "Shop" then
            return -8
        end
    end
    -- ============== 决斗神殿 ============== --
    local duelCfg = CDailyDungeonCfgMgr:GetInstance()
    -- 策划保证产出一样
    local l_simpleItemList = duelCfg:GetDuelReward(1, 1)
    local bIsDule = false
    for i = 0, l_simpleItemList:Size() - 1 do
        local ele = l_simpleItemList:ObjectAt(i)
        if ele.m_iID == iItemID then
            bIsDule = true
        end
    end
    if bIsDule then
        iIndex = iIndex + 1
        ret[iIndex] =
            {
                type = "JueDou",
                --target = iItemID,
                --list = itemCfg.m_stComposeItemList
            }
    end

    -- ============== 合成 ============== --
    local itemCfgMgr = CItemCfgMgr:GetInstance()
    local itemCfg = itemCfgMgr:GetItemCfg(iItemID)
    if itemCfg.m_stComposeItemList:Size() > 0 then
        iIndex = iIndex + 1
        ret[iIndex] =
            {
                type = "HeCheng",
                target = iItemID,
                list = itemCfg.m_stComposeItemList
            }
    end

    -- ============== 日常副本 ============== --
    local dailyCfg = CDailyDungeonCfgMgr:GetInstance().daily_dungeon_map_
    local dailyDungeonMark = false
    for _, dailyDungeon in pairs(dailyCfg) do
        if IsModuleOpen(GetDailyDungeonModuleNameByType(dailyDungeon.type_id)) then
            for _, oneDD in pairs(dailyDungeon.one_type_daily_dungeon_map) do
                if not dailyDungeonMark then
                    for i = 0, oneDD.base_reward_item_list:Size() - 1 do
                        local obj = oneDD.base_reward_item_list:ObjectAt(i)
                        if obj.m_iID == iItemID then
                            dailyDungeonMark = true
                            break
                        end
                    end
                end
                if not dailyDungeonMark then
                    for _, v in pairs(oneDD.random_reward_item_list.m_vecItems) do
                        if v.m_iItemID == iItemID then
                            dailyDungeonMark = true
                            break
                        end
                    end
                end
                if dailyDungeonMark then
                    iIndex = iIndex + 1
                    ret[iIndex] =
                        {
                            type = "DailyFuben",
                            id = oneDD.type_id,
                            name = oneDD.name
                        }
                    break
                end
            end
            if dailyDungeonMark then break end
        end
    end




    if iIndex >= TOTAL_PATH_BUTTON_NUMBER then
        return ret
    end
    -- ============== 副本 ============== --


    local cachePlayer = CPP():GetMyPlayerCache()
    local taskNpcCfg = CTaskNPCConfig:GetInstance()
    local function CantEnterAnyMore(iChapterID, iDungeonType, iDungeonID)
        -- 序章不能再进
        if iChapterID < 1 then
            return true
        end

        -- 已经打赢过的副本
        if cachePlayer:GetDungeonScore(iChapterID, iDungeonType, iDungeonID) > 0 then
            -- 没boss的不能再进
            if not taskNpcCfg:IsBossInDungeon(iDungeonType, iChapterID, iDungeonID) then
                return true
            else
                return false
            end
        end

        -- 没打赢过的，肯定有机会再进

        return false
    end

    -- he he
    local BattleInfoOfType =
    {
        [1] = "m_normalBattleInfo",
        [2] = "m_hardBattleInfo",
        [3] = "m_devilBattleInfo"
    }
    local dungeonPathNumber = 0
    for iChapterID, stChapter in pairs(CMapConfig:GetInstance().m_arrStChapterInfos) do
    for sectionIdex, sectionInfo in pairs(stChapter.m_vecSectionInfo) do
    for i = 1, 3 do
    for mapEditorIndex, stMapInfo in pairs(sectionInfo[BattleInfoOfType[i]].m_baseInfo.m_vecMapInfo) do
    if not CantEnterAnyMore(iChapterID, stMapInfo.m_iDungeonType, stMapInfo.m_iDungeonID) then
    local bFind = false
    for _, v in pairs(stMapInfo.m_reward.m_randomReward.m_vecItems) do
    if v.m_iItemID == iItemID then
        iIndex = iIndex + 1
        ret[iIndex] =
            {
                type = "FubenOutput",
                m_iDungeonType = i - 1,
                m_iChapterID = iChapterID,
                m_iDungeonID = stMapInfo.m_iDungeonID
            }
        for sortI = iIndex - 1, 1, -1 do
            if PathHash(ret[sortI]) > PathHash(ret[sortI + 1]) then
                ret[sortI], ret[sortI + 1] = ret[sortI + 1], ret[sortI]
            end
        end

        dungeonPathNumber = dungeonPathNumber + 1
        if dungeonPathNumber >= MAX_DUNGEON_PATH_NUMBER or iIndex >= TOTAL_PATH_BUTTON_NUMBER then
            return ret
        end

        bFind = true
    end
    if bFind == true then break end
    end
    if bFind == true then break end
    end
    if bFind == true then break end
    end
    if bFind == true then break end
    end
    end
    end

      -- ==============   商店   ============== --
    local l_shoptype = {[1] = "Normal",[2] = "Honor", [3] = "Hero",[4] = "Equip"  ,[5] = "Reward" ,[6] = "Army" }
    local mallManager = MallManager:GetInstance()
    local mallManagerInfo = mallManager.m_malls_info
    local mallCfg = CMallConfigManager:GetInstance()
    for i = 1,6 do
        local mallConfig = mallCfg:GetMallConfig(i)
        if mallConfig ~= nil then
            local canGo = mallManagerInfo[i].m_can_enter
            local mallInfo = mallConfig.goods_list
            for k=1, #mallInfo do
                local goods_id = mallInfo[k].goods_id
                local m_iID =  mallInfo[k].item.m_iID
                if iItemID == m_iID then
                    iIndex = iIndex + 1
                    ret[iIndex] =
                    {
                        type = "Shop",
                        shopType = l_shoptype[i],
                        shopID = i,
                        isShopOpen = canGo
                    }
                    break
                end
            end
        end
    end

    return ret
end

local function PushPanelIntoListView(panel, listView)
    panel:retain()
    panel:removeFromParent()
    listView:pushBackCustomItem(panel)
    panel:release()
end

function ui_itemInfo:OnItemChanged(_, luaType)
    -- self:RefreshItemCount()
    self:RefreshPathInfo()
    self:RefreshBottomButtonInfo()
end

function ui_itemInfo:OnDungeonProgressChanged(_, luaType)
    self:RefreshPathInfo()
end

local function CheckItemEnough(targetID)
    local cfg = CItemCfgMgr:GetInstance():GetItemCfg(targetID)
    local cachePlayer = CPP():GetMyPlayerCache()
    local composeList = cfg.m_stComposeItemList
    for i = 0, composeList:Size() - 1 do
        local ele = composeList:ObjectAt(i)
        if cachePlayer:GetItemCount(ele.m_iID) < ele.m_iCount then
            return false
        end
    end
    return true
end

local function CheckSoulStoneEnough(targetID)
    local cfg = CPP():GetGeneralCfgMgr()
    local num = cfg:GetComposeSoulStoneNum(targetID)
    local id = cfg:GetSoulStoneID(targetID)
    local cachePlayer = CPP():GetMyPlayerCache()
    if cachePlayer:GetItemCount(id) < num then
        return false
    end
    return true
end

local l_bottomButtonValid =
{
    ["compose"] = {func = CheckItemEnough},
    ["composeGeneral"] = {func = CheckSoulStoneEnough},

}
function ui_itemInfo:RefreshBottomButtonInfo()
    for _, btn in ipairs(self.DownButton) do
        local btnType = btn.buttonType
        local ele = l_bottomButtonValid[btnType]
        if ele ~= nil then
            local ok = (ele.func)(btn.value)
            GreyButton(btn, not ok)
            btn:setTouchEnabled(ok)
        else
            GreyButton(btn, false)
            btn:setTouchEnabled(true)
        end
    end
end

function ui_itemInfo:RefreshItemCount()

    local iItemID = self.m_currentID
    local lItemUniqueKey = self.m_currentUniqueKey

    local idType = GetItemType(iItemID)

    local itemCount = 0
    local arg = {}
    if idType == "equip" then
        return
    else
        -- 配置
        if lItemUniqueKey == nil then
            itemCount = self.CachePlayer:GetItemCount(iItemID)
        else
            itemCount = self.CachePlayer:GetItemCountByUniqueKey(lItemUniqueKey)
        end

    end
	ChangeObject(self.ItemIcon, {num = itemCount})

	--如果有武将信息要检查是否可装备
	if itemCount > 0 and self.m_generalInfo then
		self:SetGeneralEquipInfo(self.m_generalInfo)
	end
end

function ui_itemInfo:close()
    g_newestItemInfoUI = nil

    self:removeFromParent()
    ReloadFile("ui/ui_itemInfo")
end

function ui_itemInfo:OnExit()    
    self.super.OnExit(self)
    g_newestItemInfoUI = nil
end

function ui_itemInfo:ctor(uiClass, notOpenInPack)
	self = self.super.ctor(self)

    g_newestItemInfoUI = self

	self.m_Panel_shield : addTouchEventListener(
 	function (btn, eventType)
 		if eventType == ccui.TouchEventType.ended then
            self:close()
 		end
 	end)

	self.m_Panel_store:setVisible(false)

	-- 获得信息
	self.CachePlayer = CPP():GetMyPlayerCache()
    self.ItemCfg = CItemCfgMgr:GetInstance()
    self.EquipCfg = CEquipmentConfig:GetInstance()
    self.EquipExtCfg = CEquipExtConfig:GetInstance()

    -- 初始化
    self.m_bNotOpenInPack = (notOpenInPack == true)
	self.m_Panel_shield : setVisible(self.m_bNotOpenInPack)
	self.m_currentUniqueKey = nil
	self.m_currentID = nil

    registerGlobalEvent("ENUM_ITEM_CHANGED", self, self.OnItemChanged)
    registerGlobalEvent("DUNGEON_PROGRESS_MODIFY", self, self.OnDungeonProgressChanged)

	return self
end


--如果是武将装备额外设置一些信息 arg = {generalCard, pos}
function ui_itemInfo:SetGeneralEquipInfo(arg)
	self.m_generalInfo = arg

	local generalCard = arg.generalCard
	self.m_Button_equip:setVisible(true)
	local generalConfig = self.m_generalConfig:GetGeneralInfoByID(generalCard.m_iGeneralCardID)
	local equipType = generalConfig.m_vecEquipTypes[arg.pos]
	local equip = self.m_generalConfig:GetGeneralEquipInfo(equipType, generalCard.m_iQuality)
	local itemID = equip.m_iItemID
	local itemCount = self.CachePlayer:GetItemCount(itemID)

	self:SetItemInfo({id = itemID, belongUI = "general", shortof = 1})

    local hasButton = true

	if itemCount == 0 or generalCard.m_vecEquip[arg.pos] == 1 then
		self.m_Label_EquipCondition:setVisible(false)
		self.m_Button_equip:setVisible(false)
        hasButton = false
	elseif itemCount > 0 and generalCard.m_iLevel < equip.m_iLevel then
		self.m_Label_EquipCondition:setVisible(true)
		self.m_Label_EquipCondition:setText(common.utils.text_by_key("item_can_equip", tostring(equip.m_iLevel)))
		self.m_Button_equip:setVisible(false)
	elseif itemCount > 0 and generalCard.m_iLevel >= equip.m_iLevel then
		self.m_Label_EquipCondition:setVisible(false)
		self.m_Button_equip:setVisible(true)
		self.m_Button_equip:addTouchEventListener(function(sender, eventType)
			if eventType == ccui.TouchEventType.ended then
				self.Protocol:RequestWearGeneralEquip(generalCard.m_iGeneralCardID, arg.pos)
                self:close()
			end
		end)
	end

    self:ReflashListView(hasButton, true)
end

--重新设置中间滚动层
function ui_itemInfo:ReflashListView(hasButton, hasAttr)
    local bottomY = hasButton and self.m_Panel_button:getContentSize().height or 0
    local listHeight = self.m_Panel_bottom_z1:getContentSize().height
    local listWidth = self.m_Panel_listViewBottom:getContentSize().width
    if hasButton then
        listHeight = listHeight - self.m_Panel_button:getContentSize().height
    end
    if hasAttr then
        listHeight = listHeight - self.m_Panel_infoBottomWithAttr:getContentSize().height
    else
        listHeight = listHeight - self.m_Panel_infoBottom:getContentSize().height
    end
    self.m_Panel_listViewBottom:setPositionY(bottomY)
    self.m_Panel_listViewBottom:setContentSize({width = listWidth, height = listHeight})
    self.ListView : setContentSize({width = listWidth, height = listHeight})
    self.m_Image_viewListMaskUp:setPositionY(listHeight - 17)
end

--------------------------------------------------------
--------------------- 操作函数 start --------------------
--------------------------------------------------------

-- 打开宝箱
function ui_itemInfo:OnClickOpenChest(uniqueKey)

    local pPlayer = CPP():GetMyPlayerCache()
    local pItem = pPlayer:GetItem(uniqueKey)
    if pItem == nil then
        return
    end

    local pItemCfg = CItemCfgMgr:GetInstance():GetItemCfg(pItem.m_iItemID)
    if pItemCfg == nil then
        return
    end

    if (pItemCfg.m_iMinPlayerLevel > pPlayer:GetLevel()) then
        PushNotify(common.utils.text_by_key("item_need_level", tostring(pItemCfg.m_iMinPlayerLevel)))
        return
    end
    CPP():GetLogicProtoMgr():RequestOpenChest(pItem.m_iItemID)
end

-- 合成
function ui_itemInfo:OnClickComposeGeneral(targetID)
    local cfg = CPP():GetGeneralCfgMgr()
    local need = cfg:GetComposeSoulStoneNum(targetID)
    local needID = cfg:GetSoulStoneID(targetID)

    if self.CachePlayer:GetItemCount(needID) < need then
        PushNotify(common.utils.text_by_key("item_hecheng_material_out"))
        return
    end
    CPP():GetLogicProtoMgr():RequestComposeGeneralCard(targetID)
end
-- 合成
function ui_itemInfo:OnClickComposeItem(targetID)
    local cfg = self.ItemCfg:GetItemCfg(targetID)
    for i = 0, cfg.m_stComposeItemList:Size() - 1 do
        local ele = cfg.m_stComposeItemList:ObjectAt(i)
        if self.CachePlayer:GetItemCount(ele.m_iID) < ele.m_iCount then
            PushNotify(common.utils.text_by_key("item_hecheng_material_out"))
            return
        end
    end
    CPP():GetLogicProtoMgr():RequestComposeItem(targetID)
end

-- 出售
function ui_itemInfo:AddSellFunc(obj, func)
    self.SellFuncObj = obj
    self.SellFunc = func
end
function ui_itemInfo:OnClickSellItem(uniqueKey)
    if self.SellFuncObj and self.SellFunc then
        self.SellFunc(self.SellFuncObj, uniqueKey)
    end
end

--激活
function ui_itemInfo:OnClickActiveFashionWing(id)
	self.Protocol:RequestActivateFashionWing(id)
end

local l_buttonInfo = {
    ["composeGeneral"] = {name = "合成武将", func = "OnClickComposeGeneral"},
    ["compose"] = {name = "合成", func = "OnClickComposeItem"},
    ["open"] = {name = "打开", func = "OnClickOpenChest"},
    ["sell"] = {name = "出售", func = "OnClickSellItem"},
    ["active"] = {name = "激活", func = "OnClickActiveFashionWing"},
}
--------------------------------------------------------
--------------------- 操作函数  end ----------------------
--------------------------------------------------------

--[[
catalog：物品类型（类型id越小的，在背包越优先显示在前面）
1：宝箱（不可堆叠），功能：打开
2：可合成材料（可堆叠），功能：合成、出售
3：宝石（可堆叠），功能：合成、出售
4：武将灵魂石（可堆叠），功能：合成、出售
5：其他材料（可堆叠），功能：出售
6：进阶材料（可堆叠），功能：出售
7：武将经验书（不可堆叠），功能：出售
11：幻翅，功能：激活，出售
]]--

-- 打开、合成均由配置读得，唯出售在此处定义
local function CanBeSold(id)
    if id == 10 then
        return false
    else
        return true
    end
end

function ui_itemInfo:SetItemInfo(itemInfo)
	local iItemID = itemInfo.id
	local lItemUniqueKey = itemInfo.uniqueKey
	self.m_currentUniqueKey = lItemUniqueKey
	self.m_currentID = iItemID

    local idType, idSubType = GetItemType(iItemID)

    -- {id, level(*equip), kind, advanceLevel(*equip), catalog, count, name, range, roleType, attrName1, attrValue1, attrName2, attrValue2, price, desc, \
    -- button = {open, compose, sell}}
    local arg = {}
    if idType == "equip" then
        local level = itemInfo.level or 0
        local equipBaseInfo = self.EquipCfg:GetEquipmentBaseInfo(iItemID)
        MyAssert(equipBaseInfo, iItemID, equipBaseInfo.m_iRange)
        local range = equipBaseInfo.m_iRange--self.EquipExtCfg:GetColorIdByQualityLevel(equipAdvanceLevel)
        local equipCfg = self.EquipCfg:GetEquipmentBaseInfo(iItemID)
        MyAssert(equipCfg, iItemID)
        -- -- name
        arg.id = iItemID
        arg.level = level
        arg.kind = "equip"
        arg.advanceLevel = equipAdvanceLevel
        arg.name = equipBaseInfo.m_szEquipName
        arg.range = range
        arg.roleType = equipCfg.m_iRoleType

        local attrIndex = 0
        for k, v in pairs(equipBaseInfo.m_mapAttrBase) do
            local l_attrValue = v
            if equipBaseInfo.m_mapAttrUpgrade[k] then
                l_attrValue = l_attrValue + equipBaseInfo.m_mapAttrUpgrade[k] * level
            end
            if l_attrValue > 0 then
                attrIndex = attrIndex + 1
                arg["attrName" .. attrIndex] = GetAttrName(k)
                arg["attrValue" .. attrIndex] = l_attrValue
            end
        end
        arg.desc = {
            [1] = {text = equipBaseInfo.m_strDescription, color = Color.spgrey}
        }

        arg.button = {}
    else
        -- 配置
        local itemCfg = self.ItemCfg:GetItemCfg(iItemID)
        MyAssert(itemCfg, iItemID)
        local itemCount = 0
        if lItemUniqueKey == nil then
            itemCount = self.CachePlayer:GetItemCount(iItemID)
        else
            itemCount = self.CachePlayer:GetItemCountByUniqueKey(lItemUniqueKey)
        end
        -- {id, kind, advanceLevel, catalog, count, name, range, roleType, attrName1, attrValue1, attrName2, attrValue2, price, desc}
        arg.id = iItemID
        arg.kind = "item"
        arg.catalog = itemCfg.m_iCatalog
        arg.count = itemCount
        arg.name = itemCfg.m_szItemName
        arg.range = itemCfg.m_iRange
        arg.roleType = -1
        arg.price = itemCfg.m_iSellPrice
        arg.desc = {
            [1] = {text = itemCfg.m_szAttrDesc, color = Color.spgrey}
        }

        arg.button = {}

        if CanBeSold(arg.catalog) then
            arg.button.sell = self.m_currentUniqueKey
        end

        -- -- 属性
        for k, v in pairs(itemCfg.m_astAttrInfo) do
            if k <= 2 then
                arg["attrName" .. k] = GetAttrName(v.m_iAttrType)
                arg["attrValue" .. k] = v.m_iAttrValue
            end
        end

        -- -- 开箱描述
        local inList = itemCfg.m_stInItemList
        local descIndex = 1
        if inList:Size() > 0 then
            descIndex = descIndex + 1
            arg.desc[descIndex] = {text = "\n" .. common.utils.text_by_key("item_open_can_get"), color = Color.spgrey}
            arg.button.open = self.m_currentUniqueKey
        end
        for i = 0, inList:Size() - 1 do
            local inItem = inList:ObjectAt(i)
            local name = nil
            if GetItemType(inItem.m_iID) == "valueType" then
                name = GetMoneyName(inItem.m_iID)
            else
                local inItemCfg = self.ItemCfg:GetItemCfg(inItem.m_iID)
                MyAssert(inItemCfg, inItem.m_iID)
                name = inItemCfg.m_szItemName
            end
            descIndex = descIndex + 1
            arg.desc[descIndex] = {text = "\n" .. tostring(name), color = Color.spyellow}
            descIndex = descIndex + 1
            arg.desc[descIndex] = {text = " X " .. tostring(inItem.m_iCount), color = Color.rice}
        end

        -- -- 合成
        if itemCfg.m_iComposeTargetItemID ~= 0 then
            arg.button.compose = itemCfg.m_iComposeTargetItemID
        end

        -- -- 合成物将
        if idSubType == "generalSoul" then
            local generalID = CPP():GetGeneralCfgMgr():GetCardIDBySoulStoneID(iItemID)
            if generalID == -1 then
                echoError("invalid item id " .. tostring(iItemID))
            end

            -- 武将则可合成
            local generalInfo = GeneralManager:GetInstance():GetGeneralCardByID(generalID)
            if generalInfo == nil then
                arg.button.composeGeneral = generalID
            end
		elseif idSubType == "wing" then
			arg.button.active = iItemID
        end
    end

	arg.belongUI = itemInfo.belongUI
    arg.shortof = itemInfo.shortof


    self:FillUI(arg)
end

-- {id, kind, advanceLevel, catalog, count, name, range, roleType, attrName1, attrValue1, attrName2, attrValue2, price, desc}
function ui_itemInfo:FillUI(arg)

    -- 上部信息
    -- -- layout
    local attrNumber = (arg.attrName1 and 1 or 0) + (arg.attrName2 and 1 or 0)
    for i = 1, 2 do
        self["m_Image_attrBottom" .. i]:setVisible(i <= attrNumber)
        if i <= attrNumber then
            self["m_Image_attrBottom" .. i]:setPositionX(
                self.m_Panel_infoBottomWithAttr:getContentSize().width / 2 + (i * 2 - attrNumber - 1) / 2 * 120
            )
        end
    end
    -- -- id
    if CCApplication:getInstance():getTargetPlatform() == cc.PLATFORM_OS_WINDOWS then
        self.m_Label_id:setText("id：" .. arg.id)
    else
        self.m_Label_id:setText("")
    end
    -- -- name
    local realName = arg.name
    if arg.kind == "equip" then
        if (arg.level or 0) > 1 then
            realName = arg.name .. "+" .. tostring(arg.level)
        end
    end
    self.m_Label_itemName:setText(realName)
    self.m_Label_itemName:setTextColor(Color["quality" .. arg.range])
    -- -- icon
    local curReplaceObj = self.m_Locate_icon
    if self.ItemIcon ~= nil then
        curReplaceObj = self.ItemIcon
    end
    if arg.kind == "equip" then
        self.ItemIcon = CreateIcon({id = arg.id, kind = "equip", advanceLevel = arg.advanceLevel, replaceObj = curReplaceObj})
    else
        -- self.ItemIcon = CreateIcon({id = arg.id, kind = "item", num = arg.count, replaceObj = curReplaceObj})
        -- 物品详细信息框不显示物品数量，只在背包中显示
        self.ItemIcon = CreateIcon({id = arg.id, kind = "item", replaceObj = curReplaceObj})
    end
    -- -- quality
    self.m_Label_quality:setText(GetItemRangeName(arg.range))
    self.m_Label_quality:setTextColor(Color["quality" .. arg.range])
    -- -- role type
    self.m_Label_roleType:setText(GetRoleTypeName(arg.roleType))
    -- -- attr
    local hasAttr = (attrNumber > 0)
    self.m_Panel_infoBottom:setVisible(not hasAttr)
    self.m_Panel_infoBottomWithAttr:setVisible(hasAttr)
    for i = 1, 2 do
        if arg["attrName" .. i] ~= nil then
            self["m_Label_attrName" .. i]:setText(arg["attrName" .. i])
            self["m_Label_attrValue" .. i]:setText("+" .. arg["attrValue" .. i])
        end
    end

    -- 下部按钮
    local btnMaxNumber = 2
    local downButton = {
        self.m_Button_left,
        self.m_Button_right
    }
    for i = 1, btnMaxNumber do
        downButton[i]:setVisible(false)
    end



    local btnNumber = 0
    self.DownButton = {}
    if not self.m_bNotOpenInPack then
        for k, v in pairs(arg.button) do
            btnNumber = btnNumber + 1

            local btn = downButton[btnNumber]
            table.insert(self.DownButton, btn)
            tolua.setpeer(btn, {buttonType = k, value = v})
            btn : setVisible(true)
            btn : getChildByName("m_Label") : setText(l_buttonInfo[k].name)
            btn : addTouchEventListener(
                function (btn, eventType)
                    if eventType == ccui.TouchEventType.ended then
                        self[l_buttonInfo[k].func](self, v)
                    end
                end)

            if btnNumber >= btnMaxNumber then
                break
            end

        end

        for i = 1, btnMaxNumber do
            local btn = downButton[i]

            btn : setPositionX(
                self.m_Panel_bottom_z1:getContentSize().width / 2 + (i * 2 - btnNumber - 1) / 2 * 120
            )
        end
    end
    local hasButton = (btnNumber > 0)

    -- 中间滚动层
    -- -- layout
    if self.ListView == nil then
        self.ListView = CreateMultiListView({
            numOneLine = 1,
            itemsMargin = 6,
            unshowScrollBar = true,
        })
        ReplaceWidgetPS(self.ListView, self.m_Locate_listView)
    end
    self:ClearListViewAndStorePanel()
    self:ReflashListView(hasButton, hasAttr)

    -- -- desc
    self.m_Panel_desc : removeAllChildren()
    local richExtraWidth = 20
    local richExtraUpHeight = 10
    local richTextDescription = ccui.RichText:create()
    local descSize = self.m_Panel_desc : getContentSize()
    richTextDescription : setContentSize(cc.size(descSize.width - richExtraWidth * 2, 0))
    for i = 1, #arg.desc do
        richTextDescription : pushBackElement(ccui.RichElementText:create(1, arg.desc[i].color, 255, arg.desc[i].text, DEFAULT_FONT, 16))
    end

    richTextDescription : ignoreContentAdaptWithSize(false)
    richTextDescription : formatText()
    descSize.height = richTextDescription:getVirtualRendererSize().height + richExtraUpHeight
    richTextDescription : setPosition(cc.p(descSize.width / 2, (descSize.height - richExtraUpHeight) / 2))
    self.m_Panel_desc : setContentSize(descSize)
    self.m_Panel_desc : addChild(richTextDescription)
    PushPanelIntoListView(self.m_Panel_desc, self.ListView)
    -- -- price
    if arg.price then
        self.m_Image_price:setText(arg.price)
        PushPanelIntoListView(self.m_Panel_price, self.ListView)
    end

    -- -- path
    local path = {}
    if arg.kind == "item" then
        path = GetPathsByItemID(arg.id)
    end
    -- 为了安全起见，先只加个装备的，秘籍和武将以后再说
    if arg.kind == "equip" then
        path = GetPathsByItemID(arg.id)
    end
    self.ShowPathButton = {}
    if #path > 0 then
        for i = 1, #path do
            self:InitPathInfo(self["m_Button_fuben" .. i], path[i], arg.belongUI, arg.id, arg.shortof)
            self["m_Button_fuben" .. i] : setVisible(true)
            self.ShowPathButton[i] = self["m_Button_fuben" .. i]
        end
        for i = #path + 1, TOTAL_PATH_BUTTON_NUMBER do
            self["m_Button_fuben" .. i] : setVisible(false)
        end
        local psz = self.m_Panel_path : getContentSize()
        local delta = self.m_Button_fuben1:getPositionY() - self.m_Button_fuben2:getPositionY()
        self.m_Panel_path : setContentSize({width = psz.width, height = 33 + #path * delta})
        self.m_Panel_path_contain : setPositionY(-(TOTAL_PATH_BUTTON_NUMBER - #path) * delta)
        PushPanelIntoListView(self.m_Panel_path, self.ListView)

        self:RefreshPathInfo()
    end

    self:RefreshBottomButtonInfo()
end

function ui_itemInfo:RefreshPathInfo()
    for k, v in ipairs(self.ShowPathButton) do
        local btn = v
        local dat = btn.data
        if dat.type == "HeCheng" then
            if dat.list:Size() <= 0 then
                return
            end
            local canCompose = true
            local text = ""
            for i = 0, dat.list:Size() - 1 do
                local ele = dat.list:ObjectAt(i)
                local cfg = self.ItemCfg:GetItemCfg(ele.m_iID)
                local curNumber = self.CachePlayer:GetItemCount(ele.m_iID)
                text = text .. "[" .. cfg.m_szItemName .. "(" .. curNumber .. "/" .. ele.m_iCount .. ")]"
                if curNumber < ele.m_iCount then
                    canCompose = false
                end
            end

            btn:getChildByName("m_Label_fuben_name"):setText(LANG("item_info_compose_by__s", text))
            EnableButton(btn, canCompose)
            btn:getChildByName("m_Label_fuben_name"): setTextColor(canCompose and Color.spyellow or Color.grey)
        elseif dat.type == "FubenOutput" then
            local prog = self.CachePlayer.m_astDungeonProgress[dat.m_iDungeonType]
            local mapInfo = CMapConfig:GetInstance():GetMapInfoByDungeon(dat.m_iDungeonType, dat.m_iChapterID, dat.m_iDungeonID)
            local labelName = btn:getChildByName("m_Label_fuben_name")
            local l_DungeonTypeLabel = nil
            if dat.m_iDungeonType == DUNGEONTYPE_COMMON then
                l_DungeonTypeLabel = common.utils.text_by_key("general_fragment_normal_dungeon")
            elseif dat.m_iDungeonType == DUNGEONTYPE_ELITE then
                l_DungeonTypeLabel = common.utils.text_by_key("general_fragment_elite_dungeon")
            elseif dat.m_iDungeonType == DUNGEONTYPE_DEVIL then
                l_DungeonTypeLabel = common.utils.text_by_key("general_fragment_devil_dungeon")
            end
            labelName:setText(l_DungeonTypeLabel .. LANG("item_info_chapter__s", DigitToWord(dat.m_iChapterID)) .. ":" .. mapInfo.m_szDungeonName)

            local canGo = prog.m_iChapterID >= dat.m_iChapterID and (prog.m_iChapterID ~= dat.m_iChapterID or prog.m_iDungeonID >= dat.m_iDungeonID)

            -- 判断类型开启
            if dat.m_iDungeonType == DUNGEONTYPE_ELITE then
                if self.CachePlayer:IsModuleOpen("JingYingFuBen") == false then
                    canGo = false
                end
            elseif dat.m_iDungeonType == DUNGEONTYPE_DEVIL then
                if self.CachePlayer:IsModuleOpen("MoWangFuben") == false then
                    canGo = false
                end
            end

            -- 判断前置章节开启
            local maxFinishedDungeonIDToCompare =
            {
                [DUNGEONTYPE_COMMON] = NUMBER_INFINITE,
                [DUNGEONTYPE_ELITE] = GetMaxFinishedDungeonID(DUNGEONTYPE_COMMON, dat.m_iChapterID),
                [DUNGEONTYPE_DEVIL] = GetMaxFinishedDungeonID(DUNGEONTYPE_ELITE, dat.m_iChapterID),
            }
            --if mapInfo.m_iRequiredDungeonID > maxFinishedDungeonIDToCompare[dat.m_iDungeonType] then
            --    canGo = false
            --end
            EnableButton(btn, canGo)
            labelName : setTextColor(canGo and Color.spyellow or Color.grey)
        elseif dat.type == "DailyFuben" then
            local labelName = btn:getChildByName("m_Label_fuben_name")
            local canGo = CDailyDungeonCfgMgr:GetInstance():IsDailyDungeonOpen(dat.id, GetNowTimeSeconds())
            labelName:setText(LANG("module_daily_dungeon") .. " : " .. dat.name)
            EnableButton(btn, canGo)
            btn:getChildByName("m_Label_fuben_name"): setTextColor(canGo and Color.spyellow or Color.grey)
        elseif dat.type == "JueDou" then
            local labelName = btn:getChildByName("m_Label_fuben_name")
            labelName:setText("决斗神殿")
        elseif dat.type == "Shop" then
            local canGo = dat.isShopOpen
            btn:getChildByName("m_Label_fuben_name"):setText(common.utils.text_by_key("ct_title_shop_" .. dat.shopType))
            EnableButton(btn, canGo)
        end
    end

end

function ui_itemInfo:ClearListViewAndStorePanel()
    local panelSet =
    {
        [1] = self.m_Panel_path,
        [2] = self.m_Panel_price,
        [3] = self.m_Panel_desc
    }


    if self.ListView then
        for k, v in pairs(panelSet) do
            v:retain()
        end
        self.ListView:removeAllItems()
        for k, v in pairs(panelSet) do
            ReAddParent(v, self.m_Panel_store)
            v:release()
        end
    end
end

function ui_itemInfo:InitPathInfo(btn, dat, belongUI, itemID, shortof)
    tolua.setpeer(btn, {data = dat})
    if dat.type == "FubenOutput" then
        btn:addTouchEventListener(
        function(btn, eventType)
            if eventType == ccui.TouchEventType.ended then
                require "ui/ui_fuben"
                ShowFuBenUIAndOpenDungeon(dat.m_iDungeonType, dat.m_iChapterID, dat.m_iDungeonID, belongUI, itemID, shortof)
                --self:close()
            end
        end)

    elseif dat.type == "HeCheng" then
        btn:addTouchEventListener(
            function(btn, eventType)
                if eventType == ccui.TouchEventType.ended then
                    self:OnClickComposeItem(dat.target)
                end
            end
        )
    elseif dat.type == "DailyFuben" then
        btn:addTouchEventListener(
            function(btn, eventType)
                if eventType == ccui.TouchEventType.ended then
                    require "ui/ui_activity"
                    ShowDailyDungeon(dat.id)
                end
            end
        )
    elseif dat.type == "JueDou" then
        btn:addTouchEventListener(
            function(btn, eventType)
                if eventType == ccui.TouchEventType.ended then
                    CrossServerPK()
                end
            end
        )
    elseif dat.type == "Shop" then
        btn:addTouchEventListener(
            function(btn, eventType)
                if eventType == ccui.TouchEventType.ended then
                    require("ui/ui_shop")
                    ShowShopUI(dat.shopID)
                end
            end
        )
    end
end


function ui_itemInfo:SetItemUniqueKey(lItemUniqueKey)

	-- 物品
	local stCurrentItem = CPP():GetMyPlayerCache() : GetItem(lItemUniqueKey)
	if stCurrentItem == nil then
		echoInfo("no unique key "..lItemUniqueKey)
		return
	end

	--默认背包调用
	self:SetItemInfo({id = stCurrentItem.m_iItemID, uniqueKey = lItemUniqueKey, belongUI = "背包"})
end

return ui_itemInfo
