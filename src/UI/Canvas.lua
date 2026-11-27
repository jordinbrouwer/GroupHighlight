-- Puts the four boxes of the editor together, and keeps them in step with the settings.
local GH = GroupHighlight
local UI = GH.UI
local GetOptions = GH.GetOptions
local S = UI.state

-- Builds the boxes into `parent`. The window (Layout.lua) places them.
function UI.BuildCanvas(parent)
  S.boxes = {
    who = UI.BuildWhoBox(parent),
    look = UI.BuildLookBox(parent),
    preview = UI.BuildPreviewBox(parent),
    members = UI.BuildMembersBox(parent),
  }
  return S.boxes
end

-- Shows the settings in every box.
function UI.SyncEditor()
  local options = GetOptions()
  if not options or not S.boxes then return end
  S.syncing = true
  UI.SyncWhoBox(options)
  UI.SyncLookBox(options)
  S.syncing = false
  -- The list first: the preview shows its first name.
  UI.SyncMembersBox(options)
  UI.UpdatePreview()
end
