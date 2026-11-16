local addonName, addon = ...
local TEXTURES = "Interface/AddOns/" .. addonName .. "/Textures/Card/"

local style = {}
addon.openxpStyle = style

style.colors = {
    bg = {0.041, 0.074, 0.101, 0.96},
    header = {0.066, 0.122, 0.155, 1},
    panel = {0.065, 0.106, 0.137, 1},
    border = {0.24, 0.37, 0.41, 1},
    surface = {0.12, 0.22, 0.25, 1},
    primary = {0.10, 0.28, 0.28, 1},
    text = {0.94, 0.96, 0.95},
    dim = {0.68, 0.76, 0.78},
    faint = {0.55, 0.65, 0.69},
    accent = {0.49, 0.90, 0.79},
    gold = {0.96, 0.77, 0.47},
    blue = {0.46, 0.72, 1},
    orange = {1, 0.55, 0.39},
    cyan = {0.36, 0.84, 0.94},
    purple = {0.77, 0.66, 0.94},
    green = {0.40, 0.84, 0.61},
}

function style.Mark(parent, size)
    local mark = CreateFrame("Frame", nil, parent)
    mark:SetSize(size, size)

    local disc = mark:CreateTexture(nil, "BACKGROUND")
    disc:SetTexture(TEXTURES .. "disc")
    disc:SetAllPoints()
    disc:SetVertexColor(unpack(style.colors.primary))

    local ring = mark:CreateTexture(nil, "BORDER")
    ring:SetTexture(TEXTURES .. "ring")
    ring:SetAllPoints()
    ring:SetVertexColor(unpack(style.colors.accent))

    local needle = mark:CreateTexture(nil, "ARTWORK")
    needle:SetTexture(TEXTURES .. "diamond")
    needle:SetPoint("CENTER")
    needle:SetSize(size * 0.42, size * 0.60)
    needle:SetVertexColor(unpack(style.colors.gold))

    return mark
end
