--随机返奖模块
RandomReturnAward = RandomReturnAward or {
	randomAwardCount = 0, --全局的随机奖励次数，用于重置随机种子
}

local function initExtDataMember(extData, level, betAmountList, jackpot)
	extData[level] = {
		jackpot = jackpot,	--玩家共享奖池
		jackpotRobot = 0,	--机器人共享奖池
	}
	for i,_ in ipairs(betAmountList) do
		extData[level][i] = {
			awardMultipleList = {},				--调控周期返奖序列
			awardMultiplePool = 0,				--上一局结余的返奖倍数
			normalAwardMultiplePool = 0,		--普通返奖池
			specialAwardMultiplePool = 0,		--特殊返奖池
		}
	end
end

--初始化扩展存档数据
function RandomReturnAward.InitExtRecordData(bInitJackpot)
	local extData = {
		awardMultipleList = {},				--调控周期返奖序列
		version = TableBaseRuleConfigList[1].extDataVersion
	}
	for k,v in ipairs(TableBaseRuleConfigList) do
		local jackpot = bInitJackpot and v.jackpot
		initExtDataMember(extData, k, v.betAmountList, jackpot)
	end
	return extData
end

--初始化返奖数据
function RandomReturnAward.Init()
	local extDataField = TableBaseRuleConfigList[1].extDataField
	RandomReturnAward.data = {
		[extDataField] = RandomReturnAward.InitExtRecordData(true)
	}	--玩家返奖数据
	RandomReturnAward.dataRobot = {
		[extDataField] = RandomReturnAward.InitExtRecordData(true)
	}	--机器人返奖数据
	local history = LotteryHistory.GetLotteryHistoryByIndex(1, 1)
	if history and history.version == TableBaseRuleConfigList[1].extDataVersion then
		RandomReturnAward.data[extDataField] = history
	end
end

local function randomAwardByConfigBase(tableReturnAwardProbability, level, awardRatio)
	local awardMultiple = 0
	local returnAwardProbability = tableReturnAwardProbability[1]
	local randomNum = math.random(1, returnAwardProbability.probabilityMax)
	local lastProbability = 0
	local tableLen = #tableReturnAwardProbability
	for i = 1, tableLen do
		returnAwardProbability = tableReturnAwardProbability[i]
		local probability = returnAwardProbability.probability + lastProbability
		lastProbability = probability
		if randomNum <= probability then
			break
		end
	end
	awardMultiple = math.random(returnAwardProbability.returnAwardMin, returnAwardProbability.returnAwardMax)
	--根据不同游戏变化配置中的线数形式
	awardMultiple = RandomReturnAward.TransformAwardMultipleByLine(level, awardMultiple, awardRatio)

	return awardMultiple, returnAwardProbability
end

--单人控制
local function checkSingleControl(userInfo, awardMultiple, tableReturnAwardProbability, betTotalPoint, awardRatio, level)
	local controlJackpot, controlLevel, bwIndex = BlackWhiteManager:GetControlJackpot(userInfo:GetId())
	if controlJackpot == 0 then
		return awardMultiple, 0
	end
	local awardMultipleNew = awardMultiple
	local triggerProbability = TableGlobalControlConfig.triggerProbabilityList[controlLevel] or Define.EnumGlobalControlLevel.Middle
	if random.selectByPercent(triggerProbability) then
		local awardMultiple1 = awardMultiple
		if controlJackpot > 0 and controlLevel == Define.EnumGlobalControlLevel.High then
			--放水高强度直接产生随机投注倍数的奖励
			local multiple = math.random(TableGlobalControlConfig.highLevelMultipleObj.min, TableGlobalControlConfig.highLevelMultipleObj.max)
			awardMultiple1 = RandomReturnAward.CalculationAwardMultiple(betTotalPoint, awardRatio, betTotalPoint*multiple)
			--userInfo:Info(string.format("SingleControl high controlJackpot:%s before:%s, after:%s, last:%s, bwIndex:%d", tostring(controlJackpot), tostring(awardMultiple), tostring(awardMultiple1), tostring(awardMultipleNew), bwIndex))
		else
			awardMultiple1 = randomAwardByConfigBase(tableReturnAwardProbability, level, awardRatio)
		end
		awardMultipleNew = controlJackpot > 0 and math.max(awardMultiple, awardMultiple1) or math.min(awardMultiple, awardMultiple1)
		if controlJackpot < 0 and controlLevel == Define.EnumGlobalControlLevel.High then
			--抽水高强度若奖励倍数大于限定则重置为0
			local awardPoint = RandomReturnAward.CalculationReward(betTotalPoint, awardRatio, awardMultipleNew)
			if awardPoint > TableGlobalControlConfig.highLevelMultipleObj.limit*betTotalPoint then
				awardMultipleNew = 0
				--userInfo:Info(string.format("SingleControl high controlJackpot:%s before:%s, after:%s, last:%s, bwIndex:%d", tostring(controlJackpot), tostring(awardMultiple), tostring(awardMultiple1), tostring(awardMultipleNew), bwIndex))
			end
		end
	end

	--先处理投注额
	if controlJackpot > 0 then
		controlJackpot = controlJackpot + betTotalPoint
	else
		controlJackpot = math.abs(controlJackpot) > betTotalPoint and controlJackpot + betTotalPoint or 0
		--抽水涉及到奖池不足投注的情况，后面看有没有必要处理 TODO wangahao
	end
	--再处理返奖
	local awardPoint = RandomReturnAward.CalculationReward(betTotalPoint, awardRatio, awardMultipleNew, userInfo)
	if controlJackpot > 0 then
		if awardPoint > controlJackpot then --精确控制
			awardPoint = controlJackpot
			awardMultipleNew = RandomReturnAward.CalculationAwardMultiple(betTotalPoint, awardRatio, awardPoint)
		end
	end
	controlJackpot = controlJackpot - awardPoint
	BlackWhiteManager:SetControlJackpot(bwIndex, userInfo:GetId(), controlJackpot)
	--userInfo:Info(string.format("SingleControl end betTotalPoint:%s, controlJackpot:%s default:%s, new:%s, awardPoint:%s, bwIndex:%d", tostring(betTotalPoint), tostring(controlJackpot), tostring(awardMultiple), tostring(awardMultipleNew), tostring(awardPoint), bwIndex))
	return awardMultipleNew, bwIndex
end

local function checkSceneControl(userInfo, awardMultiple, tableReturnAwardProbability, betTotalPoint, awardRatio, sceneControlMember, level)
	local awardMultipleNew = awardMultiple
	local controlJackpot, gameId = sceneControlMember.controlJackpot, Define.EnumBlackWhiteListIndex.SceneControl
	local initValue = sceneControlMember.initValue
	local controlJackpotMin = initValue*sceneControlMember.downThreshold
	local controlJackpotMax = initValue*sceneControlMember.upThreshold
	local controlJackpotMinSum = (controlJackpotMin + initValue)/2
	local controlJackpotMaxSum = (controlJackpotMax + initValue)/2
	local percent, mathfun = 0, nil
	if controlJackpot <= controlJackpotMin then
		percent, mathfun = 20, math.min
	elseif controlJackpot <= controlJackpotMinSum then
		percent, mathfun = 10, math.min
	elseif controlJackpot <= initValue then
		percent, mathfun = 5, math.min
	elseif controlJackpot <= controlJackpotMaxSum then
		percent, mathfun = 5, math.max
	elseif controlJackpot <= controlJackpotMax then
		percent, mathfun = 10, math.max
	else
		percent, mathfun = 20, math.max
	end
	if BlackWhiteManager:CheckIsInBlackWhiteList(Define.EnumBlackWhiteListIndex.SameIpUser, Define.EnumBlackWhiteListType.White, userInfo:GetId()) then
		--防刷名单中的玩家处理
		percent, mathfun = 10, math.min
	else
		--放水只针对输的玩家，抽水只针对赢的玩家
		local rankInfo = BlackWhiteManager:GetWinRankInfo(userInfo:GetId())
		if (rankInfo.profit >= 0 and mathfun == math.max)
			or (rankInfo.profit < 0 and mathfun == math.min) then
			return awardMultipleNew
		end
	end
	--userInfo:Debug(string.format("SceneControl non controlJackpot:%s, controlJackpotDefault:%s controlJackpotMin:%s, controlJackpotMax:%s, controlJackpotMinSum:%s, controlJackpotMaxSum:%s, percent:%s", tostring(controlJackpot), tostring(initValue), tostring(controlJackpotMin), tostring(controlJackpotMax), tostring(controlJackpotMinSum), tostring(controlJackpotMaxSum), tostring(percent)))
	if percent ~= 0 and random.selectByPercent(percent) then
		local awardMultiple1 = randomAwardByConfigBase(tableReturnAwardProbability, level, awardRatio)
		awardMultipleNew = mathfun(awardMultiple, awardMultiple1)
	--	userInfo:Info(string.format("SceneControl hit betTotalPoint:%s, controlJackpot:%s default:%s, secd:%s, new:%s, math:%s", tostring(betTotalPoint), tostring(controlJackpot), tostring(awardMultiple), tostring(awardMultiple1), tostring(awardMultipleNew), (mathfun == math.min and "min" or "max")))
	end
	if awardMultipleNew > 0 then
		local awardPoint = RandomReturnAward.CalculationReward(betTotalPoint, awardRatio, awardMultipleNew)
		local mul = awardPoint / betTotalPoint
		if awardPoint > (controlJackpot - controlJackpotMin) and mul >= 16 then
			mul = 16 + math.sqrt(mul - 16)
			awardPoint = betTotalPoint * mul
			awardMultipleNew = RandomReturnAward.CalculationAwardMultiple(betTotalPoint, awardRatio, awardPoint)
		end
	end
	return awardMultipleNew
end

local function checkSceneControlExt(userInfo, value)
	if userInfo:IsRobot() then
		return true
	end
	local room = userInfo:GetRoom()
	--场次控制
	local sceneControlMember = BlackWhiteManager:GetMemberSceneControl(room:GetDisLevel())
	if not sceneControlMember then
		return true
	end

	local controlJackpot = sceneControlMember.controlJackpot --当前水池
	local initValue = sceneControlMember.initValue			--初始水池
	local controlJackpotMin = initValue*sceneControlMember.downThreshold --触发下线
	local controlJackpotMax = initValue*sceneControlMember.upThreshold--触发上线

	--当前水池 - 水池下触发值
	local jackpotMaxLimitValue = controlJackpot - controlJackpotMin
	if value >= jackpotMaxLimitValue then
		return false
	end
	return true
end

--场次水池更新
local function updateSceneControlJackpot(sceneControlMember, betTotalPoint, awardPoint)
	if not sceneControlMember then
		return
	end
	local controlJackpot = sceneControlMember.controlJackpot
	controlJackpot = controlJackpot + (betTotalPoint - awardPoint) - (betTotalPoint*sceneControlMember.taxRate/100)
	BlackWhiteManager:SetControlJackpot(Define.EnumBlackWhiteListIndex.SceneControl, sceneControlMember.charid, controlJackpot)
	return controlJackpot
end

--获取Jackpot值
--@params level:房间等级
function RandomReturnAward.GetJackpot(level)
	--机器人的jackpot + 玩家的jackpot
	local v = RandomReturnAward.GetJackpotRobot(level) + RandomReturnAward.GetJackpotReal(level)
	return v
end

--获取机器人的jackpot值
function RandomReturnAward.GetJackpotRobot(level)
	local extData = RandomReturnAward.data[TableBaseRuleConfigList[level].extDataField]
	return extData[level].jackpotRobot
end

--获真正玩家的jackpot的值
function RandomReturnAward.GetJackpotReal(level)
	local extData = RandomReturnAward.data[TableBaseRuleConfigList[level].extDataField]
	return extData[level].jackpot
end

--设置Jackpot值
--@params level:房间等级
--@params addValue:Jackpot的增加值
function RandomReturnAward.AddJackpot(level, addValue, isRobot, notSave)
	local extData = RandomReturnAward.data[TableBaseRuleConfigList[level].extDataField]
	extData[level].jackpot = extData[level].jackpot + (not isRobot and addValue or 0)
	extData[level].jackpotRobot = extData[level].jackpotRobot + (isRobot and addValue or 0)
	if notSave then
		return
	end
	LotteryHistory.AddLotteryHistory(extData, 1)
end

--设置Jackpot值
--@params level:房间等级
--@params addValue:Jackpot的减加值
function RandomReturnAward.SubJackpot(level, subValue, isRobot, notSave)
	local extData = RandomReturnAward.data[TableBaseRuleConfigList[level].extDataField]
	local leftValue = isRobot and extData[level].jackpotRobot or extData[level].jackpot
	if leftValue < subValue then
		return false
	end
	leftValue = leftValue - subValue
	extData[level].jackpot = not isRobot and leftValue or extData[level].jackpot
	extData[level].jackpotRobot = isRobot and leftValue or extData[level].jackpotRobot

	if notSave then
		return true
	end
	LotteryHistory.AddLotteryHistory(extData, 1)
	return true
end

function RandomReturnAward.RandomSpecialIdJackpots(level, isRobot, gameLevel)

	local TableJackpotSpecialSymbolConfigTmp = (TableJackpotSpecialSymbolConfigPartial and gameLevel) and TableJackpotSpecialSymbolConfigPartial[gameLevel] or TableJackpotSpecialSymbolConfig
	local isReturnAwardJack = false
	local jackpotTotalValue = isRobot and RandomReturnAward.GetJackpot(level) or RandomReturnAward.GetJackpotReal(level)
	local jackpotInitValue = TableBaseRuleConfigList[level].jackpot
	local specialSymbolIdJackpot = nil
	local probabilityMaxLimit = TableJackpotSpecialSymbolConfigTmp[0].triggerProbabilityMaxLimit and TableJackpotSpecialSymbolConfigTmp[0].triggerProbabilityMaxLimit or 1000000
	local probabilityRandom = math.random(1,probabilityMaxLimit)
	local probabilityLast = 0

	for i=0,#TableJackpotSpecialSymbolConfigTmp,1 do
		local triggerProbabilityLimitTmp = isRobot and TableJackpotSpecialSymbolConfigTmp[i].robotTriggerProbabilityLimit or TableJackpotSpecialSymbolConfigTmp[i].triggerProbabilityLimit
		if isRobot then
			local tmp = (triggerProbabilityLimitTmp * 0.01) * jackpotTotalValue
			if (triggerProbabilityLimitTmp > 0) and RandomReturnAward.GetJackpotRobot(level) >= tmp then
				isReturnAwardJack = true
				specialSymbolIdJackpot = i
			end
		else
			probabilityLast = math.floor(probabilityLast + triggerProbabilityLimitTmp)
			if (probabilityRandom <= probabilityLast) then
				isReturnAwardJack = true
				specialSymbolIdJackpot = i
				break
			end
		end
	end
	return isReturnAwardJack,specialSymbolIdJackpot
end

--Jackpot计算
--@param userInfo 玩家对象,
--@param level 等级
--@param specialSymbolIdJackpot Jackpot的奖池索引,
--@param betPointConfig 玩家配置押注额,
--@param data 返回给玩家的消息对象
--@param awardRatio 玩家押注线数
--@param jackpotPullRule jackpot拉取的规则
--@param jackpotReturnParam 奖池返奖的动态参数
--@param betTotalPoint 玩家真正押注额
--@param gameLevel 游戏内等级
--@return ret 是否奖池广播,场控不允许出现奖池
function RandomReturnAward.CalcJackpotValue(userInfo, level, specialSymbolIdJackpot, betPointConfig, betTotalPoint, data, awardRatio, jackpotPullRule, jackpotReturnParam, gameLevel)
	local ret = false
	local ret1 = true
	local TableJackpotSpecialSymbolConfigTmp = (TableJackpotSpecialSymbolConfigPartial and gameLevel) and TableJackpotSpecialSymbolConfigPartial[gameLevel] or TableJackpotSpecialSymbolConfig
	local labaMode = TableGameRuleConfigList[level].awardMultipleTransformMode or Define.AwardMultipleTranformMode.MaxLineMaxAwardMultiple
	local tableBaseRuleConfig = TableBaseRuleConfigList[level]
	local tableGameRuleConfig = TableGameRuleConfigList[level]
	local isRobot = userInfo:IsRobot()
	local returnPointJackpot = 0
	local room = userInfo:GetRoom()
	local sceneControlMember = BlackWhiteManager:GetMemberSceneControl(room:GetDisLevel())

	local betAmountListTmp = table.clone(tableBaseRuleConfig.betAmountList)
	table.sort(betAmountListTmp,function(a,b)
		return a < b
	end)

	awardRatio = awardRatio or tableGameRuleConfig.awardRatio
	jackpotPullRule = jackpotPullRule or Define.JackpotPullMode.BetPointMax
	jackpotReturnParam = jackpotReturnParam or 1
	betTotalPoint = betTotalPoint or betPointConfig
	local jackpotValue = isRobot and RandomReturnAward.GetJackpotRobot(level) or RandomReturnAward.GetJackpotReal(level)
	--彩金计算
	--最大押注拉取奖池
	if jackpotPullRule == Define.JackpotPullMode.BetPointMax and (TableJackpotSpecialSymbolConfigTmp[specialSymbolIdJackpot].jackpotReturnPercent > 0) then
		if betPointConfig == betAmountListTmp[#betAmountListTmp] then
			local retrunAwardRatioJackpot = isRobot and 1 or TableJackpotSpecialSymbolConfigTmp[specialSymbolIdJackpot].jackpotReturnPercent * 0.01
			returnPointJackpot = math.floor(retrunAwardRatioJackpot * jackpotValue)
			ret = true
		else
			--如果不是最大押注,不拉取奖池,但是返还物品相应的倍率
			data.jackpotSpecialSymbolType=0
		end
	elseif jackpotPullRule == Define.JackpotPullMode.BetPointRatio and (TableJackpotSpecialSymbolConfigTmp[specialSymbolIdJackpot].jackpotReturnPercent > 0) then
		local jackpotParam = betPointConfig / betAmountListTmp[#betAmountListTmp] * jackpotReturnParam or 1
		local retrunAwardRatioJackpot = isRobot and 1 or TableJackpotSpecialSymbolConfigTmp[specialSymbolIdJackpot].jackpotReturnPercent * 0.01 * jackpotParam
		returnPointJackpot = math.floor(retrunAwardRatioJackpot * jackpotValue)
		ret = true
	end
	data.awardPoint = data.awardPoint + returnPointJackpot
	--如果奖池的值不够扣或者jackpot值不够,怎直接返回
	if (jackpotValue < returnPointJackpot) or (not checkSceneControlExt(userInfo, data.awardPoint)) then
		if not isRobot then
			updateSceneControlJackpot(sceneControlMember, betTotalPoint, 0)
		end
		if (Define.DebugMode == 1 and userInfo:IsRobot())
		or (Define.DebugMode >= 2 and not userInfo:IsRobot()) then
			--统计不能将上一次未返部分加上了
			RandomReturnAward.awardMultiple = (RandomReturnAward.awardMultiple or 0)
			RandomReturnAward.count = (RandomReturnAward.count or 0) + 1
			RandomReturnAward.input = (RandomReturnAward.input or 0) + betTotalPoint
			RandomReturnAward.output = (RandomReturnAward.output or 0) --jackpot本身固有价值和奖池值
			RandomReturnAward.jackpotId = 0
			RandomReturnAward.jackpot = 0
			RandomReturnAward.awardMultipleJackpotTotal = (RandomReturnAward.awardMultipleJackpotTotal or 0)
			RandomReturnAward.jackpotTotal = (RandomReturnAward.jackpotTotal or 0)
			RandomReturnAward.jackpotCount = (RandomReturnAward.jackpotCount or 0)
		end
		return false,false
	end
	--jackpot扣金币
	RandomReturnAward.SubJackpot(level, returnPointJackpot, isRobot)
	--jackpot扣减当前水池值
	if not isRobot then
		updateSceneControlJackpot(sceneControlMember, betTotalPoint, data.awardPoint)
	end
	if (Define.DebugMode == 1 and userInfo:IsRobot())
		or (Define.DebugMode >= 2 and not userInfo:IsRobot()) then
		--统计不能将上一次未返部分加上了
		local awardMultipleJackpot = data.awardMultipleReal
		local awardPoint = RandomReturnAward.CalculationReward(betTotalPoint, awardRatio, awardMultipleJackpot)

		RandomReturnAward.awardMultiple = (RandomReturnAward.awardMultiple or 0) + awardMultipleJackpot
		RandomReturnAward.count = (RandomReturnAward.count or 0) + 1
		RandomReturnAward.input = (RandomReturnAward.input or 0) + betTotalPoint
		RandomReturnAward.output = (RandomReturnAward.output or 0) + awardPoint + returnPointJackpot --jackpot本身固有价值和奖池值
		RandomReturnAward.jackpotId = specialSymbolIdJackpot
		RandomReturnAward.jackpot = returnPointJackpot
		RandomReturnAward.awardMultipleJackpotTotal = (RandomReturnAward.awardMultipleJackpotTotal or 0) + awardMultipleJackpot
		RandomReturnAward.jackpotTotal = (RandomReturnAward.jackpotTotal or 0) + returnPointJackpot
		RandomReturnAward.jackpotCount = (RandomReturnAward.jackpotCount or 0) + 1
		userInfo:Debug(string.format("level:%d jackpotId:%d jackpotPullMode:%d betTotalPoint:%d awardRatio:%d awardMultiple:%d jackpot:%d count:%d awardMultipleTotal:%d jackpotTotal:%d", level, RandomReturnAward.jackpotId, jackpotPullRule,betTotalPoint,awardRatio,awardMultipleJackpot, RandomReturnAward.jackpot, RandomReturnAward.jackpotCount, RandomReturnAward.awardMultipleJackpotTotal, RandomReturnAward.jackpotTotal))
	end

	return ret,ret1
end

--检查是否处于返利期间
function RandomReturnAward.CheckInNovicePeriod(userInfo, level, rebateMode)
	local ret = false
	--处于同ip用户列表中不享受新手模式
	if not BlackWhiteManager:CheckIsInBlackWhiteList(Define.EnumBlackWhiteListIndex.SameIpUser, Define.EnumBlackWhiteListType.White, userInfo:GetId()) then
		local extDataField = TableBaseRuleConfigList[level].extDataField
		local tableGameRuleConfig = TableGameRuleConfigList[level]
		if rebateMode == tableGameRuleConfig.noviceModeObj.mode then
			local rebateCount = userInfo.data[extDataField].rebateCount or 0
			local totalBetAmount = userInfo.data[extDataField].totalBetAmount or 0
			if tableGameRuleConfig.noviceModeObj.round > 0 and tableGameRuleConfig.noviceModeObj.totalBetAmount > 0 then
				ret = rebateCount < tableGameRuleConfig.noviceModeObj.round and totalBetAmount < tableGameRuleConfig.noviceModeObj.totalBetAmount
			elseif tableGameRuleConfig.noviceModeObj.round > 0 then
				ret = rebateCount < tableGameRuleConfig.noviceModeObj.round
			elseif tableGameRuleConfig.noviceModeObj.totalBetAmount > 0 then
				ret = totalBetAmount < tableGameRuleConfig.noviceModeObj.totalBetAmount
			end
		end
	end
	return ret
end

--获取返奖数据
--@param userInfo UserInfo实例
--@param level 房间等级
--@param betTotalPointIndex 下注索引
function RandomReturnAward.GetExtData(userInfo, level, betTotalPointIndex)
	local extData = nil
	--从配置位置读取返奖序列数据
	local extDataField = TableBaseRuleConfigList[level].extDataField
	local returnAwardListRecordMode = TableGameRuleConfigList[level].returnAwardListRecordMode
	if RandomReturnAward.CheckInNovicePeriod(userInfo, level, Define.RebateMode.ReadConfig) then
		return userInfo.data[extDataField]
	elseif returnAwardListRecordMode == Define.ReturnAwardListRecordMode.Personal then
		if not userInfo.data[extDataField][level]
			or not userInfo.data[extDataField][level][betTotalPointIndex] then --这里兼容一下场次与投注额列表动态更新
			initExtDataMember(userInfo.data[extDataField], level, TableBaseRuleConfigList[level].betAmountList)
		end
		extData = userInfo.data[extDataField][level][betTotalPointIndex]
	else
		--机器人与玩家不共用返奖数据
		if userInfo:IsRobot() then
			extData = RandomReturnAward.dataRobot[extDataField]
		else
			extData = RandomReturnAward.data[extDataField]
		end
		if returnAwardListRecordMode == Define.ReturnAwardListRecordMode.ShareMultiple then
			extData = extData[level][betTotalPointIndex]
		end
	end
	return extData
end

--检查返奖分布位置是否有效
--@param extData 返奖存档数据
--@param returnAwardControlCount 返奖调控周期
--@param indexs 已占用位置列表
--@param randIndex 随机位置
--@param middleFrontCountLimit 中前区域分布数量限制
--@param interval 分布最小间距
--@return true | false
function RandomReturnAward.checkRandomIndex(extData, returnAwardControlCount, indexs, randIndex, middleFrontCountLimit, interval)
	local middleFrontCount = 0 --中前区域分布计数，用于控制分布到中后区域
	local middleIndex = math.floor(returnAwardControlCount/2)
	for _,v in pairs(indexs) do
		if v > middleIndex then
			middleFrontCount = middleFrontCount + 1
		end
		if middleFrontCount >= middleFrontCountLimit and randIndex > middleIndex then
			return false
		end
		if math.abs(v - randIndex) < interval then
			return false
		end
		if extData.awardMultipleList[randIndex] ~= 0 then
			return false
		end
	end
	return true
end

--控制返奖分布位置
--@param extData 返奖存档数据
--@param rangeIndexMin 区域位置下限
--@param rangeIndexMax 区域位置上限
--@param middleFrontCountLimit 中前区域分布数量限制
--@param awardMultipleList 返奖列表
--@param returnAwardControlCount 返奖调控周期
--@param interval 分布最小间距
function RandomReturnAward.randomAwardDistribution(extData, rangeIndexMin, rangeIndexMax, middleFrontCountLimit, awardMultipleList, returnAwardControlCount, interval)
	if rangeIndexMax == 0 then
		rangeIndexMax = returnAwardControlCount
	end
	local tempIndexs = {}
	for _,v in ipairs(awardMultipleList) do
		local randIndex = math.random(rangeIndexMin, rangeIndexMax)
		local whileCount = 0
		while(not RandomReturnAward.checkRandomIndex(extData, returnAwardControlCount, tempIndexs, randIndex, middleFrontCountLimit, interval)) do
			randIndex = math.random(rangeIndexMin, rangeIndexMax)
			whileCount = whileCount + 1
			if whileCount > rangeIndexMax then
				--找不到合适的位置就跳出，防止死循环
				break
			end
		end
		extData.awardMultipleList[randIndex] = extData.awardMultipleList[randIndex] + v
		tempIndexs[randIndex] = randIndex
	end
end

--按照配置拆分返奖
--@param awardMultiple 返奖倍数
--@param returnAwardControlCount 调控周期
--@param controlObj 控制条件
--@return 剩余返奖倍数, 控制返奖列表
function RandomReturnAward.splitAwardByConfig(awardMultiple, returnAwardControlCount, controlObj)
	local awardMultipleList = {}
	if awardMultiple > 0 then
		local awardPercent = math.random(controlObj.minPercent, controlObj.maxPercent)
		local awardCount = math.floor(returnAwardControlCount*(awardPercent/100) + 0.5) --四舍五入
		for i = 1, awardCount do
			local randAwardMultiple = math.random(controlObj.min, controlObj.max)
			if randAwardMultiple > awardMultiple then
				randAwardMultiple = awardMultiple
			end
			table.insert(awardMultipleList, randAwardMultiple)
			awardMultiple = awardMultiple - randAwardMultiple
			if awardMultiple == 0 then
				break
			end
		end
	end
	return awardMultiple, awardMultipleList
end

--根据返奖配置生成返奖倍数
--@param tableReturnAwardProbability 返奖表格配置
--@param randomSeedInterval 随机种子重置间隔
--@return 返奖倍数, 返奖表格配置项
function RandomReturnAward.randomAwardByConfig(tableReturnAwardProbability, randomSeedInterval, userInfo, level, awardRatio, betTotalPoint)
	--随机奖励倍数
	local awardMultiple,returnAwardProbability = randomAwardByConfigBase(tableReturnAwardProbability, level, awardRatio)
	if not userInfo or userInfo:IsRobot() then
		return awardMultiple, returnAwardProbability
	end
	local awardMultipleDefault, bwIndex = awardMultiple, 0
	--单人控制
	awardMultiple, bwIndex = checkSingleControl(userInfo, awardMultiple, tableReturnAwardProbability, betTotalPoint, awardRatio, level)

	--场次控制
	local room = userInfo:GetRoom()
	local sceneControlMember = BlackWhiteManager:GetMemberSceneControl(room:GetDisLevel())
	if sceneControlMember and returnAwardProbability.level ~= 0 and bwIndex == 0 then --新手模式|单人控制模式下不再经场控制开奖
		awardMultiple = checkSceneControl(userInfo, awardMultiple, tableReturnAwardProbability, betTotalPoint, awardRatio, sceneControlMember, level)
	end

	--更新场次控制水池
	if sceneControlMember then
		--if returnAwardProbability.level ~= 0 then --新手模式输赢不计入当前场次控制水池
		local awardPoint = RandomReturnAward.CalculationReward(betTotalPoint, awardRatio, awardMultiple)
		local controlJackpot = updateSceneControlJackpot(sceneControlMember, betTotalPoint, awardPoint)
		--end
		--[[
		if awardMultipleDefault ~= awardMultiple then
			userInfo:Info(string.format("SceneControl end level:%d, betTotalPoint:%s, controlJackpot:%s default:%s, new:%s, awardPoint:%s, bwIndex:%d", level, tostring(betTotalPoint), tostring(controlJackpot), tostring(awardMultipleDefault), tostring(awardMultiple), tostring(awardPoint), bwIndex))
		end
		--]]
	end

	--处理随机数种子
	if randomSeedInterval > 0 then
		RandomReturnAward.randomAwardCount = RandomReturnAward.randomAwardCount + 1
		if (RandomReturnAward.randomAwardCount % randomSeedInterval) == 0 then
			local randomseed = tostring(go.time.Msec()+99999):reverse():sub(1, 6)
			math.randomseed(randomseed)
		end
	end
	return awardMultiple, returnAwardProbability
end

--奖励公式
--@param betTotalPoint 注额
--@param awardRatio 奖励系统
--@param awardMultiple 奖励倍数
function RandomReturnAward.CalculationReward(betTotalPoint, awardRatio, awardMultiple)
	local awardPoint = (betTotalPoint / awardRatio) * awardMultiple --奖励货币 = 下注总额 / 奖励系数 * 去掉余数的返奖倍数
	return awardPoint
end

function RandomReturnAward.CalculationAwardMultiple(betTotalPoint, awardRatio, awardPoint)
	local awardMultiple = awardPoint / (betTotalPoint / awardRatio) --奖励货币 = 下注总额 / 奖励系数 * 去掉余数的返奖倍数
	return awardMultiple
end

--返奖倍率根据押注线数进行调整
--@param level 房间等级
--@param awardMultiple 根据最大线数生成的赔率
--@param userBetLine 用户的押注线数
--@return 用户在当前押注线的返奖赔率
function RandomReturnAward.TransformAwardMultipleByLine(level, awardMultiple,userBetLine)
	--根据不同拉霸,转化配置中线数形式
	--默认形式:配置中满线,配置满押注额
	local awardMultipleTransFormMode = TableGameRuleConfigList[level].awardMultipleTransformMode or Define.AwardMultipleTranformMode.MaxLineMaxAwardMultiple
	if awardMultipleTransFormMode == Define.AwardMultipleTranformMode.ChangeLineMaxAwardMultiple then
		--配置中线数根据押注线数变化,押注额不变
		return awardMultiple * (userBetLine/TableGameRuleConfigList[level].awardRatio)
	elseif awardMultipleTransFormMode == Define.AwardMultipleTranformMode.ChangeLineSingleAwardMultiple then
		--配置中线数不变,押注额更据线数变化。为了有小数,兼容设计
		return awardMultiple * 0.1
	end
	return awardMultiple
end
--生成返奖
--@param userInfo UserInfo实例
--@param level 房间等级
--@param betTotalPointIndex 下注额索引
--@param awardMultipleLimit 单次最大返奖倍数
--@param betTotalPoint 玩家总的押注额
--@param awardRatio 玩家押注线数
--@return 奖励倍数, 免费游戏，返奖配置表格数据项
function RandomReturnAward.RandomAward(userInfo, level, betTotalPointIndex, awardMultipleLimit, betTotalPoint, awardRatio)
	--拉霸模式:默认都是最大线押注,水浒:单线押注额,配置中线数是改变的.连环夺宝:押注额是变的,线是单线配置
	local labaMode = TableGameRuleConfigList[level].awardMultipleTransformMode or Define.AwardMultipleTranformMode.MaxLineMaxAwardMultiple
	local tableBaseRuleConfig = TableBaseRuleConfigList[level]
	local tableGameRuleConfig = TableGameRuleConfigList[level]
	betTotalPoint = betTotalPoint or tableBaseRuleConfig.betAmountList[betTotalPointIndex]
	awardRatio = awardRatio or tableGameRuleConfig.awardRatio--变线时,系数是动态的

	local noviceModeReadConfig = RandomReturnAward.CheckInNovicePeriod(userInfo, level, Define.RebateMode.ReadConfig)
	local extData = RandomReturnAward.GetExtData(userInfo, level, betTotalPointIndex)
	local returnAwardProbability = nil
	if #extData.awardMultipleList == 0 then
		--调控周期由返奖配置模式决定
		local index = level
		if noviceModeReadConfig then
			index = Define.TableReturnAwardProbabilityIndex.Novice
		elseif tableGameRuleConfig.abModeSwitchRatio and tableGameRuleConfig.abModeSwitchRatio > 0
			and userInfo:GetPoint() > betTotalPoint * tableGameRuleConfig.abModeSwitchRatio then
			index = Define.TableReturnAwardProbabilityIndex.BMode
		end
		if not userInfo:IsRobot() then
			--userInfo:Info("========================================index = " .. index .. " noviceModeReadConfig = " .. tostring(noviceModeReadConfig) .. " rebateCount = " .. (userInfo.data[TableBaseRuleConfigList[level].extDataField].rebateCount or 0) .. " totalBetAmount = " .. (userInfo.data[TableBaseRuleConfigList[level].extDataField].totalBetAmount or 0))
		end
		local tableReturnAwardProbability = TableReturnAwardProbabilityPartial[index]
		local returnAwardControlCount = tableReturnAwardProbability[1].returnAwardControlCount

		--生成一轮的返奖倍数
		local awardMultiple = 0
		awardMultiple,returnAwardProbability = RandomReturnAward.randomAwardByConfig(tableReturnAwardProbability, tableBaseRuleConfig.randomSeedInterval, userInfo, level, awardRatio, betTotalPoint)
		extData.awardMultiple = awardMultiple

		if returnAwardControlCount == 1 then
			table.insert(extData.awardMultipleList, awardMultiple)
		else
			--根据配置生成周期内返奖分布
			local awardMultipleListMin = {}	--小奖
			awardMultiple, awardMultipleListMin = RandomReturnAward.splitAwardByConfig(awardMultiple, returnAwardControlCount, returnAwardProbability.minAwardObj)
			local awardMultipleListProfit = {}	--盈利奖
			awardMultiple, awardMultipleListProfit = RandomReturnAward.splitAwardByConfig(awardMultiple, returnAwardControlCount, returnAwardProbability.returnAwardObj)
			local awardMultipleListMax = {} --大奖
			if awardMultipleLimit and awardMultipleLimit > 0 then
				while(awardMultiple > awardMultipleLimit) do
					awardMultiple = awardMultiple - awardMultipleLimit
					table.insert(awardMultipleListMax, awardMultipleLimit)
				end
				table.insert(awardMultipleListMax, awardMultiple)
			else
				table.insert(awardMultipleListMax, awardMultiple)
			end


			--初始化返奖列表
			extData.awardMultipleList = {}
			for i = 1, returnAwardControlCount do
				table.insert(extData.awardMultipleList, 0)
			end

			--小奖随机分布
			RandomReturnAward.randomAwardDistribution(extData, 1, returnAwardControlCount, 99, awardMultipleListMin, returnAwardControlCount, 1)

			--盈利奖随机分布
			local rangePercent = returnAwardProbability.returnAwardObj.range/100
			if rangePercent == 0 then
				rangePercent = 1
			end
			local rangeIndexMin = 1
			local rangeIndexMax = math.floor(returnAwardControlCount*rangePercent)		--分布区域位置
			local middleFrontCountLimit = 99--math.floor(#awardMultipleListProfit*(returnAwardProbability.returnAwardObj.range/100))	--中前区域分布数量，暂时不控制
			RandomReturnAward.randomAwardDistribution(extData, rangeIndexMin, rangeIndexMax, middleFrontCountLimit, awardMultipleListProfit, returnAwardControlCount, returnAwardProbability.returnAwardObj.interval)

			--大奖随机分布
			rangeIndexMin = 1
			rangePercent = (1 - returnAwardProbability.returnAwardObj.range/100)
			rangeIndexMax = math.floor(returnAwardControlCount*rangePercent)		--分布区域位置
			middleFrontCountLimit = 99--math.floor(#awardMultipleListMax*(1-returnAwardProbability.returnAwardObj.range/100))	--中前区域分布数量，暂时不控制
			RandomReturnAward.randomAwardDistribution(extData, rangeIndexMin, rangeIndexMax, middleFrontCountLimit, awardMultipleListMax, returnAwardControlCount, returnAwardProbability.returnAwardObj.interval)
		end

		if (Define.DebugMode == 1 and userInfo:IsRobot())
			or (Define.DebugMode >= 2 and not userInfo:IsRobot()) then
			RandomReturnAward.hitList = RandomReturnAward.hitList or {} --Debug
			RandomReturnAward.hitList[returnAwardProbability.id] = (RandomReturnAward.hitList[returnAwardProbability.id] or 0) + 1
		end
	end

	--生成一局的返奖倍数
	local index = #extData.awardMultipleList
	local awardMultiple = extData.awardMultipleList[index]
	table.remove(extData.awardMultipleList, index)

	local extDataField = tableBaseRuleConfig.extDataField
	local noviceModeLimitRound = RandomReturnAward.CheckInNovicePeriod(userInfo, level, Define.RebateMode.LimitRound) and awardMultiple > 0
	if noviceModeReadConfig or noviceModeLimitRound then
		--新手返利-更新局数计数
		userInfo.data[extDataField].rebateCount = (userInfo.data[extDataField].rebateCount or 0) + 1
		--新手返利-更新总投注额
		userInfo.data[extDataField].totalBetAmount = (userInfo.data[extDataField].totalBetAmount or 0) + betTotalPoint
		--新手返利-限定局数模式
		awardMultiple = noviceModeLimitRound and awardMultiple * tableGameRuleConfig.multiple or awardMultiple
	end

	if (Define.DebugMode == 1 and userInfo:IsRobot())
		or (Define.DebugMode >= 2 and not userInfo:IsRobot()) then
		--统计不能将上一次未返部分加上了
		awardPoint = RandomReturnAward.CalculationReward(betTotalPoint, awardRatio, awardMultiple)
		RandomReturnAward.awardMultiple = (RandomReturnAward.awardMultiple or 0) + awardMultiple
		RandomReturnAward.count = (RandomReturnAward.count or 0) + 1
		RandomReturnAward.input = (RandomReturnAward.input or 0) + betTotalPoint
		RandomReturnAward.output = (RandomReturnAward.output or 0) + awardPoint
	end


	--免费游戏
	local isFree = false
	if awardMultiple > 0 and #TableReturnAwardShowConfigPartial > 0 then
		for _,v in ipairs(TableReturnAwardShowConfigPartial[level]) do
			if v.freeProbability > 0 and awardMultiple >= v.returnAwardMin and awardMultiple <= v.returnAwardMax then
				isFree = random.selectByPercent(v.freeProbability)
				break
			end
		end
	end
	return awardMultiple, isFree, returnAwardProbability
end

--统计
--@param userInfo UserInfo实例
--@param level 房间等级
--@param value 消耗值
function RandomReturnAward.Statistics(userInfo, level, betTotalPointIndex, value, awardMultiple, awardMultipleExt)
	if (Define.DebugMode == 1 and userInfo:IsRobot())
		or (Define.DebugMode >= 2 and not userInfo:IsRobot()) then
		RandomReturnAward.awardMultipleReal = (RandomReturnAward.awardMultipleReal or 0) + awardMultiple
		RandomReturnAward.outputReal = (RandomReturnAward.outputReal or 0) + value
		local percent = ((RandomReturnAward.input - RandomReturnAward.output)/RandomReturnAward.input)*100
		local percentReal = ((RandomReturnAward.input - RandomReturnAward.outputReal)/RandomReturnAward.input)*100
		RandomReturnAward.awardMultipleExt = (RandomReturnAward.awardMultipleExt or 0) + (awardMultipleExt or 0)

		unilight.warn(string.format("count:%d input:%d awardMultiple:%d output:%d percent:%s awardMultipleReal:%d outputReal:%d percentReal:%s awardMultipleExt:%d", RandomReturnAward.count, RandomReturnAward.input, RandomReturnAward.awardMultiple, RandomReturnAward.output, percent,RandomReturnAward.awardMultipleReal, RandomReturnAward.outputReal, percentReal, RandomReturnAward.awardMultipleExt))
	end
end

--统计
--@param userInfo UserInfo实例
--@param level 房间等级
--@param value 消耗值
function RandomReturnAward.StatisticsDoubly(userInfo, level,doublyInfo)
	RandomReturnAward.countDoubly = (RandomReturnAward.countDoubly or 0) + 1 --比倍触发次数
	RandomReturnAward.countDoublyReal = (RandomReturnAward.countDoublyReal or 0) + doublyInfo.countReal --比倍实际次数
	RandomReturnAward.inputDoublyTotal = (RandomReturnAward.inputDoublyTotal or 0) + doublyInfo.input--拉霸中赢取金币总和
	RandomReturnAward.outDoublyTotal = (RandomReturnAward.outDoublyTotal or 0) + doublyInfo.output--比倍中赢取金币总和
	userInfo:Debug(string.format("doublyInfo:input:%d, out:%d, count:%d, countReal:%d, inputTotal:%d, outTotal:%d:",doublyInfo.input, doublyInfo.output, RandomReturnAward.countDoubly, RandomReturnAward.countDoublyReal, RandomReturnAward.inputDoublyTotal,RandomReturnAward.outDoublyTotal))
end

---------------------------begin 显示控制相关-------------------------
--基于二分查找法找出最趋近的返奖倍数索引
--@param array 预生成的返奖倍数列表
--@param key 根据概率生成的返奖倍数
--@return array的索引
function RandomReturnAward.SearchApproachMultipleIndex(array, key)
	local low,high,mid = 1,#array-1,0
	while(low <= high) do
		mid = math.ceil((low + high)/2)

		if array[mid+1].multiple == array[mid].multiple then
			--兼容值重复
			high = high - 1
			mid = math.ceil((low + high)/2)
			while(array[mid+1].multiple == array[mid].multiple) do
				high = high - 1
				mid = math.ceil((low + high)/2)
			end
		end

		if math.abs(array[mid+1].multiple - key) > math.abs(array[mid].multiple - key) then
			high = mid - 1
		else
			low = mid + 1
		end
	end
	local middle = math.abs(array[mid+1].multiple - key) > math.abs(array[mid].multiple - key) and mid or (mid+1)
	return middle
end

--基于二分查找法找出最趋近的返奖倍数索引
--@param array 预生成的返奖倍数列表
--@param key 根据概率生成的返奖倍数
--@return array的索引
function RandomReturnAward.SearchApproachMultipleIndex1(array, key)
	local low,high,mid = 1,#array-1,0
	while(low <= high) do
		mid = math.ceil((low + high)/2)

		if tonumber(array[mid+1]) == tonumber(array[mid]) then
			--兼容值重复
			high = high - 1
			mid = math.ceil((low + high)/2)
			while(tonumber(array[mid+1]) == tonumber(array[mid])) do
				high = high - 1
				mid = math.ceil((low + high)/2)
			end
		end

		if math.abs(tonumber(array[mid+1]) - key) > math.abs(tonumber(array[mid]) - key) then
			high = mid - 1
		else
			low = mid + 1
		end
	end
	local middle = math.abs(tonumber(array[mid+1]) - key) > math.abs(tonumber(array[mid]) - key) and mid or (mid+1)
	return middle
end

--控制返奖展示
--@param awardMultiple 返奖倍数
--@return 假免费，拼盘
function RandomReturnAward.RandomItemLineShow(level, awardMultiple)
	awardMultiple = math.floor(awardMultiple)
	local isFalseFree = false
	local isPinpan = false
	for _,v in ipairs(TableReturnAwardShowConfigPartial[level]) do
		if awardMultiple >= v.returnAwardMin and awardMultiple <= v.returnAwardMax then
			if v.falseFreeProbability > 0 then
				isFalseFree = random.selectByPercent(v.falseFreeProbability)
			end
			isPinpan = random.selectByPercent(v.pinpanProbability)
			break
		end
	end
	return isFalseFree, isPinpan
end

--控制返奖展示,互斥显示
--@param awardMultiple 返奖倍数
--return 是否是免费,是否是假免费,是否bonus,是否是假bonus,itemId
function RandomReturnAward.RandomItemLineOnlyShow(level, awardMultiple)
	awardMultiple = math.floor(awardMultiple)
	local isFree = false
	local isFalseFree = false
	local isPinpan = false
	local isFlasePinpan = false
	local itemId = nil
	for _,v in ipairs(TableReturnAwardShowConfigPartial[level]) do
		if awardMultiple >= v.returnAwardMin and awardMultiple <= v.returnAwardMax then
			if v.freeProbability and (v.freeProbability > 0) then
				if random.selectByPercent(v.freeProbability) then
					isFree = true
					itemId = v.id
					break
				end
			end
			if v.falseFreeProbability and (v.falseFreeProbability > 0) then
				if random.selectByPercent(v.falseFreeProbability) then
					isFalseFree = true
					itemId = v.id
					break
				end
			end
			if v.pinpanProbability and (v.pinpanProbability > 0) then
				if random.selectByPercent(v.pinpanProbability) then
					isPinpan = true
					itemId = v.id
					break
				end
			end
			if v.falsePinpanProbability and (v.falsePinpanProbability > 0) then
				if random.selectByPercent(v.falsePinpanProbability) then
					isFlasePinpan = true
					itemId = v.id
					break
				end
			end
		end
	end
	return isFree,isFalseFree,isPinpan,isFlasePinpan,itemId
end

--返回客户端结果随机排列一下
function RandomReturnAward.RandomItemLineFreeResultSort(dataList, dataListTemp, bKeepFirstPos)
	--特殊符号盘面保持在首位置
	if bKeepFirstPos then
		dataList[#dataList+1] = dataListTemp[1]
		table.remove(dataListTemp, 1)
	end

	while(#dataListTemp ~= 0) do
		local randIndex = math.random(1, #dataListTemp)
		table.insert(dataList, dataListTemp[randIndex])
		table.remove(dataListTemp, randIndex)
	end
end

--触发奖励跑马灯
function RandomReturnAward.TriggerWinNotice(userInfo, level, betTotalPoint, awardPoint, isFree, JackpotConfigId)
	if awardPoint == 0 then
		return
	end
	UserWinNoticeMgr.AddWinNotice(userInfo:GetId(), level, awardPoint, 1)
	if JackpotConfigId then
		local jackpotNoticeType = JackpotConfigId==1 and 4 or (JackpotConfigId==2 and 5 or 6)
		UserWinNoticeMgr.AddWinNotice(userInfo:GetId(), level, awardPoint, jackpotNoticeType)
	end
	local actionType = isFree and 3 or 2
	obj = TableBaseRuleConfigList[level].noticeTriggers[actionType]
	if obj then
		if (awardPoint/betTotalPoint) > obj.id then
			UserWinNoticeMgr.AddWinNotice(userInfo:GetId(), level, awardPoint, actionType)
		end
	end


	UserWinNoticeMgr.BroadcastWinNotice()
end
---------------------------end 显示控制相关-------------------------
