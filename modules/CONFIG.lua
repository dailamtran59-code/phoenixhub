local M = {}

M.Config = {
    Theme = { Background = Color3.fromRGB(16,12,24), Accent = Color3.fromRGB(140,58,200), Text = Color3.fromRGB(230,230,230) },
    ESP = { Enabled = true, Color = "purple", FillTransparency = 0.6 },
    Aimbot = { Enabled = false, Key = Enum.UserInputType.MouseButton1, FOV = 150, Smoothness = 5, AimHead = true },
    Movement = { WalkspeedEnabled = false, Walkspeed = 30, FlyEnabled = false, FlySpeed = 3, JetpackSpeed = 6 },
    Teleport = { AutoTP = false, TPKey = Enum.KeyCode.F, TPBack = 3 },
    Rope = { Enabled = true },
    UI = { Visible = false },
}

return M

