-- Configuration file for LÖVE2D
function love.conf(t)
    t.title = "Tactics Explorer"        -- The title of the window
    t.version = "11.3"                  -- The LÖVE version this game was made for
    t.window.width = 1920               -- Window width (increased to 1080p)
    t.window.height = 1080              -- Window height (increased to 1080p)
    
    t.window.resizable = true           -- Let the window be user-resizable
    t.window.minwidth = 1280            -- Minimum window width (increased)
    t.window.minheight = 800            -- Minimum window height (increased)
    
    t.console = true                    -- Attach a console (Windows only)
    
    -- For debugging
    t.window.vsync = 1                  -- Enable vertical sync
    t.window.msaa = 0                   -- MSAA (anti-aliasing) samples
    
    -- Modules
    t.modules.audio = true              -- Enable the audio module
    t.modules.data = true               -- Enable the data module
    t.modules.event = true              -- Enable the event module
    t.modules.font = true               -- Enable the font module
    t.modules.graphics = true           -- Enable the graphics module
    t.modules.image = true              -- Enable the image module
    t.modules.joystick = true           -- Enable the joystick module
    t.modules.keyboard = true           -- Enable the keyboard module
    t.modules.math = true               -- Enable the math module
    t.modules.mouse = true              -- Enable the mouse module
    t.modules.physics = false           -- Disable the physics module
    t.modules.sound = true              -- Enable the sound module
    t.modules.system = true             -- Enable the system module
    t.modules.thread = true             -- Enable the thread module
    t.modules.timer = true              -- Enable the timer module
    t.modules.touch = false             -- Disable the touch module
    t.modules.video = false             -- Disable the video module
    t.modules.window = true             -- Enable the window module
end
