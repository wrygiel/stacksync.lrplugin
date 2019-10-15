local LrApplication = import 'LrApplication'
local LrTasks = import 'LrTasks'
local LrDialogs = import 'LrDialogs'
local LrLogger = import 'LrLogger'
local LrProgressScope = import 'LrProgressScope'
local LrFunctionContext = import 'LrFunctionContext'

local logger = LrLogger('StackSync')
logger:enable("logfile")

logger:trace("StackSync plugin - SyncNow init")

local function set(list)
	local set = {}
	for _, l in ipairs(list) do set[l] = true end
	return set
end

local function map(tbl, f)
    local t = {}
    for k, v in pairs(tbl) do
        t[k] = f(v)
    end
    return t
end

local function onFatalError(_, errorMessage)
	logger:trace(string.format("onFatalError called with: %s", errorMessage))
	LrDialogs.message("StackSync crashed :(", errorMessage, "critical")
end

local function getPhotoName(photo, makeItUnique)
	fileName = photo:getFormattedMetadata('fileName')
	if fileName then
		return fileName
	end
	uuid = photo:getRawMetadata('uuid')
	return uuid
end

local function process(functionContext)
	logger:trace("Running process...")

	functionContext:addFailureHandler(onFatalError)

	local catalog = LrApplication.activeCatalog()
	logger:trace(string.format("- Catalog: %s", catalog))

	local selected = catalog:getTargetPhotos()
	local selectedIds = set(map(
		selected,
		function(photo) return photo:getRawMetadata('uuid') end
	))
	local selectedTotal = #selected
	logger:trace(string.format("- Number of selected photos: %s", selectedTotal))

	local progress = LrProgressScope({
		title = "Copying flags across stacks",
	});
	local function progressCancel()
		progress:cancel()
	end
	functionContext:addFailureHandler(progressCancel)

	local photosDone = 0
	progress:setPortionComplete(photosDone, selectedTotal)

	local skippedSelectedPhotos = 0

	local function processInternal(internalFunctionContext)

		for i, photo in ipairs(selected) do
			local photoUuid = photo:getRawMetadata('uuid');
			logger:trace(string.format("- Processing selected photo: %s", getPhotoName(photo)))
			
			local pickStatus = photo:getRawMetadata("pickStatus")
			logger:trace(string.format("  - It's pickStatus is: %s", pickStatus))

			local allInStack = photo:getRawMetadata("stackInFolderMembers")
			skipThisPhoto = false
			if #allInStack == 0 then
				logger:trace("  - This photo is not in a stack. Ignoring it.")
			elseif #allInStack == 1 then
				error("Should never happen")
			else
				logger:trace(string.format("  - The size if its stack is: %s", #allInStack))
				-- Search for conflicts
				for j, otherPhoto in ipairs(allInStack) do
					otherPhotoUuid = otherPhoto:getRawMetadata('uuid');
					if otherPhotoUuid == photoUuid then
						-- that's myself in my stack
					elseif selectedIds[otherPhotoUuid] then
						-- more than one photo in the same stack has been selected
						-- let's check for conflicts
						otherPickStatus = otherPhoto:getRawMetadata("pickStatus")
						if otherPickStatus == pickStatus then
							-- it's fine, not really a conflict
					    else
					    	logger:warn(string.format(
					    		"  - Conflict detected. User selected another photo (%s) in the " ..
					    		"same stack, and it has a different pickStatus (%s). " ..
					    		"We will skip this stack.",
					    		getPhotoName(otherPhoto), otherPickStatus
					    	))
					    	skippedSelectedPhotos = skippedSelectedPhotos + 1
					    	skipThisPhoto = true
					    end
					end
				end
				if skipThisPhoto == false then
					for j, otherPhoto in ipairs(allInStack) do
						otherPhotoUuid = otherPhoto:getRawMetadata('uuid');
						otherPickStatus = otherPhoto:getRawMetadata("pickStatus")
						if pickStatus == otherPickStatus then
							logger:trace(string.format(
								"    - Not replacing pickStatus (%s -> %s) in photo %s.",
								otherPickStatus, pickStatus, getPhotoName(otherPhoto)
							))
						else
							logger:info(string.format(
								"    - Replacing pickStatus (%s -> %s) in photo %s.",
								otherPickStatus, pickStatus, getPhotoName(otherPhoto)
							))
							otherPhoto:setRawMetadata("pickStatus", pickStatus)
						end
					end
				end
			end

			photosDone = photosDone + 1;
			progress:setPortionComplete(photosDone, selectedTotal);
			logger:trace(string.format(
				"  - Advancing progress to %s/%s.",
				photosDone, selectedTotal
			))
			LrTasks.yield();
		end
	end

	catalog:withWriteAccessDo("Copy flags across stacks", processInternal);

	progress:done()

	if skippedSelectedPhotos > 0 then
		LrDialogs.message(
			string.format("Skipped %s out of %s photos", skippedSelectedPhotos, selectedTotal), 
			string.format(
				"Some of the selected photos would have caused conflicts across their stacks. " ..
				"StackSync skipped these photos, and their stacks were unchanged.\n\n" ..
				"A conflict happens when you select two (or more) photos from a single stack, " ..
				"and these selected photos have different flags set. StackSync cannot determine " ..
				"which of these different flag values you want synced across the stack."
			),
			"warning"
		)
	end
end

LrFunctionContext.postAsyncTaskWithContext("process", process)
