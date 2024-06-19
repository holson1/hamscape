stats = {
    xp=0,
    hp=10,
    combat=1,
    attack=1,
    accuracy=0.75,
    defense=1,
    speed=1,
    evasion=0.05,
    woodcutting=1,
    fishing=1,
    mining=1
}

xp = {
    woodcutting=0,
    fishing=0,
    mining=0,
    combat=0,

    icons = {
        woodcutting = 025,
        fishing = 024,
        mining = 026,
        combat = 023
    },

    add=function(self, skill, value)
        self[skill] += value
        
        -- check level up
        local current_level = stats[skill]
        local next_threshold = 2^(current_level - 1) * 100

        if self[skill] > next_threshold then
            sfx(46)
            stats[skill] += 1
        end
    end,
}


