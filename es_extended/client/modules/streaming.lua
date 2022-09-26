function ESX.Streaming.RequestModel(modelHash, cb)
	modelHash = (type(modelHash) == 'number' and modelHash or GetHashKey(modelHash))
	if not IsModelInCdimage(modelHash) then
		ReportError(("Model %s is not in CdImage!"):format(modelHash), { model = modelHash })
		return
	end

	if not HasModelLoaded(modelHash) and IsModelInCdimage(modelHash) then
		RequestModel(modelHash)

		while not HasModelLoaded(modelHash) do
			Citizen.Wait(100)
		end
	end

	if cb ~= nil then
		cb()
	end
end

function ESX.Streaming.RequestStreamedTextureDict(textureDict, cb)
	if not HasStreamedTextureDictLoaded(textureDict) then
		RequestStreamedTextureDict(textureDict)

		while not HasStreamedTextureDictLoaded(textureDict) do
			Citizen.Wait(1)
		end
	end

	if cb ~= nil then
		cb()
	end
end

function ESX.Streaming.RequestNamedPtfxAsset(assetName, cb)
	if not HasNamedPtfxAssetLoaded(assetName) then
		RequestNamedPtfxAsset(assetName)

		while not HasNamedPtfxAssetLoaded(assetName) do
			Citizen.Wait(1)
		end
	end

	if cb ~= nil then
		cb()
	end
end

function ESX.Streaming.RequestAnimSet(animSet, cb)
	if not HasAnimSetLoaded(animSet) then
		RequestAnimSet(animSet)

		while not HasAnimSetLoaded(animSet) do
			Citizen.Wait(1)
		end
	end

	if cb ~= nil then
		cb()
	end
end

function ESX.Streaming.RequestAnimDict(animDict, cb)
	if not DoesAnimDictExist(animDict) then
		print(("^1ERROR: Animdict %s doens't exist!^0"):format(animDict))
		if cb ~= nil then
			cb()
		end
		return
	end
	if not HasAnimDictLoaded(animDict) then
		RequestAnimDict(animDict)

		while not HasAnimDictLoaded(animDict) do
			Citizen.Wait(1)
		end
	end

	if cb ~= nil then
		cb()
	end
end

function ESX.Streaming.RequestWeaponAsset(weaponHash, cb)
	if not HasWeaponAssetLoaded(weaponHash) then
		RequestWeaponAsset(weaponHash)

		while not RequestWeaponAsset(weaponHash) do
			Citizen.Wait(1)
		end
	end

	if cb ~= nil then
		cb()
	end
end
