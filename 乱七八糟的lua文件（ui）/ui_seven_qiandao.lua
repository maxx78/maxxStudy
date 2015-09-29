local ui_seven_qiandao = class("ui_seven_qiandao", ui_base)
ui_seven_qiandao.uiJson = "ui/OthersUI/SevenSignAwardUI.csb"

local l_aWeekDays = 7
g_town1_stSevenQianDao = nil

function IsSevenSignInToday()
    local playerCache = CPP():GetMyPlayerCache()
    local oneDaySeconds = 24 * 3600
    if playerCache == nil then
        return
    end
    -- 上一次七日签到的时间戳
    local lastSevenSignInTime =  playerCache.m_stLoginInfo.m_iLastSevenSignInTime
    -- 判断是否是今天
    local isSignInToday = common.utils.checkIsTheTimeToday(lastSevenSignInTime)
    return isSignInToday
end
function ui_seven_qiandao:ctor()
    self = self.super.ctor(self)
    self.m_FashionReward = {}
    self.m_SignReward = {}
    self:refreshSevenSignInUI()
    self.m_Panel_Huanchi:setLocalZOrder(3)
    return self
end


function ui_seven_qiandao:refreshSevenSignInUI() 
    self.m_cfgSignIn = CSignInCfgMgr:GetInstance()
    self.m_loginInfo = CPP():GetMyPlayerCache().m_stLoginInfo
    self.m_Button_close:addTouchEventListener( function (sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            HideSevenQianDaoUI()
        end
    end)

    local sevenSignInDays = self.m_loginInfo.m_iSevenSignInTimes
    self.l_Button_lingqu = self.m_Panel_show : getChildByName("m_Button_lingqu")
    self.l_isSignToday = IsSevenSignInToday()
    local sevenSignItems = self.m_cfgSignIn.seven_sign_
    if self.l_isSignToday then
        self.todaySevenSignId = sevenSignInDays
    else
        self.todaySevenSignId = sevenSignInDays + 1
    end

    if self.todaySevenSignId > 7 then
        self.todaySevenSignId = 7
    end

    self:ShowDayInfo(self.todaySevenSignId)

    self.m_DaysProgressBar : setPercent (100 * sevenSignInDays / 8)
    if sevenSignInDays == 7 then
        self.m_DaysProgressBar : setPercent (100)
    end
    
    -- 初始化进度
    for i = 1, l_aWeekDays do
        local l_Panel_day = self["m_Panel_day" .. i]
        local l_SevenSignInAwardName = self.m_cfgSignIn:GetSevenSignInAwardName(i)
        --echoInfo2("ID:" .. sevenSignItems.id)
        --echoInfo2("NAME:" .. sevenSignItems[i].name)
        --echoInfo2(tostring(sevenSignItems.name))

        local l_FashionReward = self.m_cfgSignIn:GetSevenSignInFashionReward(self.CachePlayer.m_stRoleInfo.m_nRoleType, i)
        local awardList = self : GetSignRewardInfo(i)
        local simpleItem = awardList:ObjectAt(0)
        if l_FashionReward then 
            l_Panel_day:getChildByName("m_ImageItem"):loadTexture( GetIconPath({id = l_FashionReward:ObjectAt(0).m_iID, kind = "fashion"}), UI_TEX_TYPE_PLIST )
        else
            l_Panel_day:getChildByName("m_ImageItem"):loadTexture( GetIconPath({id = simpleItem.m_iID, kind = "item"}), UI_TEX_TYPE_PLIST )
            
        end

        l_Panel_day:getChildByName("m_Label_name") : setString (l_SevenSignInAwardName)
        l_Panel_day:getChildByName("m_Image_has_sign") : setVisible(false)
        --l_Panel_day:getChildByName("m_Image_bright") :setVisible(false)

        if l_FashionReward then
            l_SevenSignInAwardName = self.m_cfgSignIn:GetSevenSignInFashionRewardName(self.CachePlayer.m_stRoleInfo.m_nRoleType, i)
            l_Panel_day:getChildByName("m_Label_name") : setString (l_SevenSignInAwardName)
        end

        if i <= sevenSignInDays then
            l_Panel_day:getChildByName("m_Image_has_sign") : setVisible(true)
        end 
        -- 当天的设为蓝色
        if i == self.todaySevenSignId then
            -- #0CC5E6
            l_Panel_day:getChildByName("m_Label_name") : setTextColor(cc.c4b(12, 197, 230, 255))
            l_Panel_day:getChildByName("Label_day") : setTextColor(cc.c4b(12, 197, 230, 255))
            -- l_Panel_day:getChildByName("m_Image_bright") :setVisible(true)
        end
        
        local me = self
        l_Panel_day:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                me:ShowDayInfo(i)
            end
        end)
    end
end

-- 获取时装奖励配置信息
function ui_seven_qiandao:GetFashionRewardInfo(dayIndex)
    local l_Reward = self.m_FashionReward[dayIndex]
    if l_Reward then
        return l_Reward
    else
        self.m_FashionReward[dayIndex] = self.m_cfgSignIn:GetSevenSignInFashionReward(self.CachePlayer.m_stRoleInfo.m_nRoleType, dayIndex)
        return self.m_FashionReward[dayIndex]
    end
end

-- 获取签到奖励配置信息
function ui_seven_qiandao:GetSignRewardInfo(dayIndex)
    local l_Reward = self.m_SignReward[dayIndex]
    if l_Reward then
        return l_Reward
    else
        self.m_SignReward[dayIndex] = self.m_cfgSignIn:GetSevenSignInAwardList(dayIndex)
        return self.m_SignReward[dayIndex]
    end
end

-- 展示具体某登录天数的信息
function ui_seven_qiandao:ShowDayInfo(dayIndex)
    self.m_Panel_show : getChildByName("m_Label_day") : setString(dayIndex)

    -- 导航区域
    for i = 1, l_aWeekDays do
        local l_Panel_day = self["m_Panel_day" .. i]
        if dayIndex == i then
            l_Panel_day:getChildByName("m_Image_bright") :setVisible(true)
        else
            l_Panel_day:getChildByName("m_Image_bright") :setVisible(false)
        end
    end

    local l_AwardList = self : GetSignRewardInfo(dayIndex)
    local l_HuanchiID = 0
    -- 初始化奖品栏
    self.m_Panel_ItemList : removeAllChildren()
    for k = 0, l_AwardList:Size() - 1 do
        local simpleItem = l_AwardList:ObjectAt(k)
        local locateIcon = CreateButton({id = simpleItem.m_iID, kind = "item", num = simpleItem.m_iCount, showInfo = {infoType = ITEM_INFO_TYPE_TIP}})
        local lType, lSubType = GetItemType(simpleItem.m_iID)
        if lSubType == "wing" then
            l_HuanchiID = simpleItem.m_iID
        end
        --[[
        if 0 == k then 
            AddZhuanParticle(locateIcon)
        end
        ]]--
        locateIcon : setPosition(88 * k + 50 , 45)
        self.m_Panel_ItemList : addChild(locateIcon)
    end

    -- 下方区域
    local l_FashionReward = self : GetFashionRewardInfo(dayIndex)
 
    self.m_Panel_Huanchi:setVisible(false)
    if self.m_stCharacter then
        self.m_stCharacter : setVisible(false)
    end

    if l_FashionReward then
        self.m_Image_faguang:setVisible(false)
        self.m_Image_ItemShow:setVisible(false)
        -- 时装展示
        if not self.m_stCharacter then
            self.FashionCfg = CFashionConfigManager:GetInstance()
            local info = self.FashionCfg:GetFashionInfo(l_FashionReward:ObjectAt(0).m_iID)
            self.m_stCharacter = CCharacterCreator:CreateCharacter(CPP():GetMyPlayerCache().m_stRoleInfo.m_nRoleType, info.m_Resource)
            ReplaceWidgetP( self.m_stCharacter, self.m_Panel_player )
        else 
            self.m_stCharacter : setVisible(true)
        end
    elseif l_HuanchiID > 0 then
        self.m_Image_faguang:setVisible(false)
        self.m_Image_ItemShow:setVisible(false)
        local wingConfig = CWingConfigManager:GetInstance():GetFashionWingConfig(l_HuanchiID)
        if nil ~= wingConfig and self.m_CurWingModelID ~= wingConfig.model_id then
            self.m_Panel_Huanchi:setVisible(true)
            if  nil ~= self.m_stWing then
                self.m_stWing : removeFromParent()
            end
            self.m_CurWingModelID = wingConfig.model_id
            if nil == self.m_stHuanchiModel then
                self.m_stHuanchiModel = CCharacterCreator:CreateCharacter(self.CachePlayer.m_stRoleInfo.m_nRoleType, GetFashionResourceID(self.CachePlayer:GetFashionID()))
                self.m_stHuanchiModel : SetFace(false)
                self.m_Panel_Huanchi : addChild(self.m_stHuanchiModel, 10)
                self.m_stHuanchiModel : setPosition(cc.p(self.m_Panel_Huanchi:getContentSize().width*0.5, 20))
            end
            self.m_stWing = CSkeletonAnimationCache:GetInstance():CreateAnimation("players/" .. self.m_CurWingModelID, true)
		    self.m_Panel_Huanchi:addChild(self.m_stWing, 0)
		    self.m_stWing:setName("chibang")
		    self.m_stWing:setPosition(cc.p(self.m_Panel_Huanchi:getContentSize().width*0.5, 20))
		    self.m_stWing:setAnimation(0, 'IDLE', true)
        else
            self.m_Panel_Huanchi:setVisible(true)
        end
    else
        local l_SimpleItem = l_AwardList:ObjectAt(0)
        local l_Button_ItemShow = CreateButton({id = l_SimpleItem.m_iID, kind = "item", showInfo = {infoType = ITEM_INFO_TYPE_TIP}})
        ReplaceWidgetP(l_Button_ItemShow, self.m_Image_ItemShow)
        self.m_Image_ItemShow = l_Button_ItemShow
        
        self.m_Image_faguang:setVisible(true)
        -- self.m_Image_ItemShow:setVisible(true)
        if self.m_stCharacter then
            self.m_stCharacter : setVisible(false)
        end
    end

    -- 领取按钮
    if self.l_isSignToday or dayIndex ~= self.todaySevenSignId then
        if dayIndex > self.todaySevenSignId then
            self.l_Button_lingqu : setVisible(false)
        else
            self.l_Button_lingqu : setVisible(true)
            self.l_Button_lingqu : setBright (false)
            self.l_Button_lingqu : getChildByName("m_Label_award") : setString ( LANG("button_has_lingqu") )
        end
        
        -- todaySevenSignId = sevenSignInDays
        self.m_Button_lingqu:addTouchEventListener(function (sender, eventType) end)

        -- 隐藏粒子效果
        if self["particle_info"] then
            local l_particleCount = #self["particle_info"]
            for i = 1, l_particleCount do
		        self["m_Particle_Get_" .. i] : setVisible(false)
	        end
        end
    else
        self.l_Button_lingqu : setVisible(true)
        self.l_Button_lingqu : setBright (true)
        self.l_Button_lingqu : getChildByName("m_Label_award") : setString ( LANG("get_award_now") )
        -- todaySevenSignId = sevenSignInDays + 1
        self.m_Button_lingqu:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                CPP():GetLogicProtoMgr():RequestGetSevenSignInReward()
            end
        end)

        --充值按钮上面粒子效果
        if not self["particle_info"] then
            self["particle_info"] = {
		        {file = "particle/create_role_start1.plist", pos = {x = 20, y = 33}},
		        {file = "particle/create_role_start1.plist", pos = {x = 190, y = 33}},
		        {file = "particle/create_role_start2.plist", pos = {x = 11, y = 33}},
		        {file = "particle/create_role_start2.plist", pos = {x = 205, y = 33}},
		        {file = "particle/create_role_start3.plist", pos = {x = 105, y = 33}},
	        }

            local l_particleCount = #self["particle_info"]
            for i = 1, l_particleCount do
		        local startParticle = cc.ParticleSystemQuad:create(self.particle_info[i].file)
		        self.l_Button_lingqu : addChild(startParticle, 10)
            
		        startParticle : setPosition(cc.p(self.particle_info[i].pos.x, self.particle_info[i].pos.y))
                if i == 5 then
                    startParticle : setScale(0.7, 0.9)
                end
		        self["m_Particle_Get_" .. i] = startParticle
	        end
        else
            for i = 1, #self["particle_info"] do
		        self["m_Particle_Get_" .. i] : setVisible(true)
	        end
        end
    end
end

function ui_seven_qiandao:OnSevenSignInSuccess()
    self:refreshSevenSignInUI()
end

function OnSevenSignInSuccess()
    if g_town1_stSevenQianDao then
        g_town1_stSevenQianDao:OnSevenSignInSuccess()
    end
end


function GetSevenQianDaoUI()
    return g_town1_stSevenQianDao
end

function ShowSevenQianDaoUI()
--    require "ui/tiny_ui/ui_common_title"
--	g_town1_stSevenQianDao = ShowCommonTitle({"servenQiandao"}, "servenQiandao")

    if not g_town1_stSevenQianDao then
        g_town1_stSevenQianDao = ui_seven_qiandao:new()
        AddToMainScene(g_town1_stSevenQianDao, UI_TAG_TOWN)
    end
end

function HideSevenQianDaoUI()
    if g_town1_stSevenQianDao then
        g_town1_stSevenQianDao:removeFromParent()
        g_town1_stSevenQianDao = nil
    end
    ReloadFile("ui/ui_seven_qiandao")
end


return ui_seven_qiandao