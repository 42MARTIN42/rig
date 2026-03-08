--[[
--------------------------------------------------

This file is part of RIG.
Please retain this header in all files.
Support honest open source development.

Author: Case @ BOII Development
Website: https://boii.dev
GitHub: https://github.com/rig-framework/rig
License: LGPL-3.0

--------------------------------------------------
]]

--- @module configs.injuries
--- @description Handles all injuries related config settings

return {
    
    --- Default injuries applied to players
    --- Currently no system is implemented to modify these through gameplay, the data just exists.
    _defaults = {
        head = 0.0,
        upper_torso = 0.0,
        lower_torso = 0.0,
        forearm_right = 0.0,
        forearm_left = 0.0,
        hand_right = 0.0,
        hand_left = 0.0,
        thigh_right = 0.0,
        thigh_left = 0.0,
        calf_right = 0.0,
        calf_left = 0.0,
        foot_right = 0.0,
        foot_left = 0.0
    }

}