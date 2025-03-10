//---------------------------------------------------
//         *****!Do not edit this file!*****
//---------------------------------------------------
//    ___  _           _
//   / __|| |_   __ _ | |_
//  | (__ | ' \ / _` ||  _|
//   \___||_||_|\__,_| \__|                  _      _
//   / __| ___  _ __   _ __   __ _  _ _   __| | ___(_)
//  | (__ / _ \| '  \ | '  \ / _` || ' \ / _` |(_-< _
//   \___|\___/|_|_|_||_|_|_|\__,_||_||_|\__,_|/__/(_)
//---------------------------------------------------
// Purpose: Enable commands through the chat box.
//---------------------------------------------------

// TODO:
// 1. Fix how we work out arguments for
//    players with spaces in their names

if (Config_UseChatCommands) {
    // This can only be enabled when the plugin is loaded
    if (PluginLoaded) {
        if (GetDeveloperLevel()) {
            printl("(P2:MM): Adding chat callback for chat commands.")
        }
        AddChatCallback("ChatCommands")
    } else {
        if (GetDeveloperLevel()) {
            printl("(P2:MM): Can't add chat commands since no plugin is loaded!")
        }
        return
    }
} else {
    printl("(P2:MM): Config_UseChatCommands is false. Not adding chat callback for chat commands!")
    // If AddChatCallback() was called at one point during the session, the game will still check for chat callback even after map changes.
    // So, if someone doesn't want CC midgame, just redefine the function to do nothing.
    function ChatCommands(ccuserid, ccmessage) {}
    return
}

// The whole filtering process for the chat commands
function ChatCommands(ccuserid, ccmessage) {

    local Message = RemoveDangerousChars(ccmessage)
    local Player = GetPlayerFromUserID(ccuserid)
    local Inputs = SplitBetween(Message, "!@", true)
    local PlayerClass = FindPlayerClass(Player)
    local Username = PlayerClass.username
    local AdminLevel = GetAdminLevel(Player)
    
    local Commands = []
    local Runners = []

    // The real chat command doesn't have the "!"
    function Rem(s) {
        return Replace(s, "!", "")
    }

    function GetCommandFromString(str) {
        foreach (cmd in CommandList) {
            if (StartsWith(str.tolower(), cmd.name)) {
                return cmd
            }
        }
        return null
    }

    //--------------------------------------------------

    // Be able to tell what is and isn't a chat command
    foreach (Input in Inputs) {
        if (Message.len() < 2) {
            return
        } else {
            if (StartsWith(Input, "!") && Message != "!") {
                if (Message.slice(0, 2) != "!!" && Message.slice(0, 2) != "! ") {
                    if (Message.len() >= 4) {
                        if (Message.slice(0, 4) == "!SAR") {
                            return // speedrun plugin events can interfere
                        }
                        Commands.push(Rem(Input))
                    } else {
                        Commands.push(Rem(Input))
                    }
                } else {
                    return
                }
            } else {
                return
            }
        }
    }

    // Register the activating player
    if (Runners.len() == 0) {
        Runners.push(Player)
    }

    foreach (Command in Commands) {
        // Split arguments
        Command = Strip(Command)
        local Args = SplitBetween(Command, " ", true)
        if (Args.len() > 0) {
            Args.remove(0)
        }

        // Does the exact command exist?
        if (GetCommandFromString(Command) == null) {
            return SendChatMessage("[ERROR] Command not found.")
        }

        // Do we have the correct admin level for this command?
        Command = GetCommandFromString(Command)
        if (!(Command.level <= AdminLevel)) {
            return SendChatMessage("[ERROR] You do not have permission to use this command.")
        }

        // We met the criteria, run it
        foreach (CurPlayer in Runners) {
            RunChatCommand(Command, Args, CurPlayer)
        }
    }
}

//=======================================
// Chat command content
//=======================================

CommandList <- [
    class {
        name = "noclip"
        level = 4
        
        // !noclip
        function CC(p, args) {
            local pclass = FindPlayerClass(p)
            if (pclass.noclip) {
                EnableNoclip(false, p)
            } else {
                EnableNoclip(true, p)
            }
        }
    }
    ,
    class {
        name = "kill"
        level = 0

        // !kill
        function CC(p, args) {
            if (GetAdminLevel(p) < 2) {
                EntFireByHandle(p, "sethealth", "-100", 0, p, p)
                EntFireByHandle(p2mm_clientcommand, "Command", "say Killed yourself.", 0, p, p)
            }
            else if (GetAdminLevel(p) >= 2) {
                try {
                    args[0] = Strip(args[0])

                    if (args[0] != "all") {
                        local q = FindPlayerByName(args[0])
                        if (q != null) {
                            EntFireByHandle(q, "sethealth", "-100", 0, q, q)
                            EntFireByHandle(p2mm_clientcommand, "Command", "say Killed player.", 0, p, p)
                        } else {
                            EntFireByHandle(p2mm_clientcommand, "Command", "say [ERROR] Player not found.", 0, p, p)
                        }
                    } else {
                        local p2 = null
                        while (p2 = Entities.FindByClassname(p2, "player")) {
                            EntFireByHandle(p2, "sethealth", "-100", 0, p2, p2)
                        }
                        EntFireByHandle(p2mm_clientcommand, "Command", "say Killed all players.", 0, p, p)
                    }
                } catch (exception) {
                    EntFireByHandle(p, "sethealth", "-100", 0, p, p)
                    EntFireByHandle(p2mm_clientcommand, "Command", "say Killed yourself.", 0, p, p)
                }
            }
        }
    }
    ,
    class {
        name = "changeteam"
        level = 0

        // !changeteam (optionally with args)
        function CC(p, args) {
            try {
                args[0] = Strip(args[0])

                if (args[0] == "0" || args[0] == "2" || args[0] == "3" ) {

                    teams <- [
                        "Singleplayer",
                        "Spectator", // This is not used at all since respawning is broken
                        "Red",
                        "Blue"
                    ]

                    if (p.GetTeam() == args[0].tointeger()) {
                        return EntFireByHandle(p2mm_clientcommand, "Command", "say [ERROR] You are already on this team.", 0, p, p)
                    } else {
                        p.SetTeam(args[0].tointeger())
                        return EntFireByHandle(p2mm_clientcommand, "Command", "say Team is now set to " + teams[args[0].tointeger()] + ".", 0, p, p)
                    }
                }
                EntFireByHandle(p2mm_clientcommand, "Command", "say [ERROR] Enter a valid team number: 0, 2, or 3.", 0, p, p)
            } catch (exception) {
                // No argument, so just cycle through the teams
                if (args.len() == 0) {
                    if (p.GetTeam() == 0) {
                        p.SetTeam(2)
                        EntFireByHandle(p2mm_clientcommand, "Command", "say Toggled to Red team.", 0, p, p)
                    }
                    else if (p.GetTeam() == 2) {
                        p.SetTeam(3)
                        EntFireByHandle(p2mm_clientcommand, "Command", "say Toggled to Blue team.", 0, p, p)
                    }
                    // if the player is in team 3 or above it will just reset them to team 0
                    else {
                        p.SetTeam(0)
                        EntFireByHandle(p2mm_clientcommand, "Command", "say Toggled to Singleplayer team.", 0, p, p)
                    }
                }
            }
        }
    }
    ,
    class {
        name = "speed"
        level = 4

        // !speed (float arg)
        function CC(p, args) {
            try {
                SetSpeed(p, args[0].tofloat())
            } catch (exception) {
                EntFireByHandle(p2mm_clientcommand, "Command", "say [ERROR] Input a number.", 0, p, p)
            }
        }
    }
    ,
    class {
        name = "teleport"
        level = 4

        // !teleport (going to this username) (bring this player or "all")
        function CC(p, args) {
            if (args.len() != 0) {
                args[0] = Strip(args[0])
                local plr = FindPlayerByName(args[0])
                if (plr != null) {
                    try {
                        // See if there's a third argument
                        args[1] = Strip(args[1])
                        local plr2 = FindPlayerByName(args[1])
                        if (args[1] == "all") {
                            // Third argument was "all"
                            local q = null
                            while (q = Entities.FindByClassname(q, "player")) {
                                // Don't modify the player we are teleporting to
                                if (q != plr) {
                                    q.SetOrigin(plr.GetOrigin())
                                    q.SetAngles(plr.GetAngles().x, plr.GetAngles().y, plr.GetAngles().z)
                                }
                            }
                            if (plr == p) {
                                SendChatMessage("Brought all players.")
                            } else {
                                SendChatMessage("Teleported all players.")
                            }
                        }
                        else if (plr2 != null) {
                            // We found a username in the third argument
                            if (plr2 != plr) {
                                plr2.SetOrigin(plr.GetOrigin())
                                plr2.SetAngles(plr.GetAngles().x, plr.GetAngles().y, plr.GetAngles().z)
                                if (plr2 == p) {
                                    return SendChatMessage("Teleported to player.")
                                } else {
                                    return SendChatMessage("Teleported player.")
                                }
                            }
                            if (plr == p || plr == plr2) {
                                return SendChatMessage("[ERROR] Can't teleport player to the same player.")
                            }
                        } else {
                            SendChatMessage("[ERROR] Third argument is invalid! Use \"all\" or a player's username.")
                        }
                    } catch (exception) {
                        // There was no third argument
                        if (plr == p) {
                            SendChatMessage("[ERROR] You are already here lol.")
                        } else {
                            p.SetOrigin(plr.GetOrigin())
                            p.SetAngles(plr.GetAngles().x, plr.GetAngles().y, plr.GetAngles().z)
                            SendChatMessage("Teleported to player.")
                        }
                    }
                } else {
                    SendChatMessage("[ERROR] Player not found.")
                }
            } else {
                SendChatMessage("[ERROR] Input a player name.")
            }
        }
    }
    ,
    class {
        name = "rcon"
        level = 6

        // !rcon (args)
        function CC(p, args) {
            try {
                args[0] = Strip(args[0])
                local cmd = Join(args, "")
                SendToConsoleP232(cmd)
            } catch (exception) {
                EntFireByHandle(p2mm_clientcommand, "Command", "say [ERROR] Input a command.", 0, p, p)
            }
        }
    }
    ,
    class {
        name = "restartlevel"
        level = 5

        // !restartlevel
        function CC(p, args) {
            local p = null
            if (!IsOnSingleplayerMaps) {
                while (p = Entities.FindByClassname(p, "player")) {
                    EntFireByHandle(p2mm_clientcommand, "Command", "playvideo_end_level_transition coop_bots_load", 0, p, p)
                }
            }
            EntFire("p2mm_servercommand", "command", "changelevel " + GetMapName(), 0.5, null)
        }
    }
    ,
    class {
        name = "help"
        level = 0

        // !help (optionally with command name arg)
        function CC(p, args) {
            try {
                args[0] = Strip(args[0])
                if (commandtable.rawin(args[0])) {
                    EntFireByHandle(p2mm_clientcommand, "Command", "say [HELP] " + args[0] + ": " + commandtable[args[0]], 0, p, p)
                }
                else {
                    EntFireByHandle(p2mm_clientcommand, "Command", "say [HELP] Unknown chat command: " + args[0], 0, p, p)
                }
            } catch (exception) {
                SendChatMessage("[HELP] Your available commands:")
                foreach (command in CommandList) {
                    if (command.level <= GetAdminLevel(p)) {
                        SendChatMessage("[HELP] " + command.name)
                    }
                }
                SendChatMessage("[HELP] This command can also print a description for another if supplied with it.")
            }
        }
    }
    ,
    class {
        name = "spchapter"
        level = 5

        // !spchapter (integer arg)
        function CC(p, args) {
            try{
                args[0] = args[0].tointeger()
            } catch (err){
                SendChatMessage("Type in a valid number from 1 to 9.")
                return
            }

            if (args[0].tointeger() < 1 || args[0].tointeger() > 9) {
                SendChatMessage("Type in a valid number from 1 to 9.")
                return
            }

            EntFire("p2mm_servercommand", "command", "changelevel " + spchapternames[args[0]-1], 0, p)
        }
    }
    ,
    class {
        name = "mpcourse"
        level = 5

        // !mpcourse (integer arg)
        function CC(p, args) {
            try{
                args[0] = args[0].tointeger()
            } catch (err){
                SendChatMessage("Type in a valid number from 1 to 6.")
                return
            }

            local allp = Entities.FindByClassname(null, "player")

            if (args.len() == 0 || args[0].tointeger() < 1 || args[0].tointeger() > 6) {
                SendChatMessage("Type in a valid number from 1 to 6.")
                return
            }

            EntFireByHandle(p2mm_clientcommand, "Command", "playvideo_end_level_transition coop_bots_load", 0, allp, allp)
            EntFire("p2mm_servercommand", "command", "changelevel " + mpcoursenames[args[0]-1], 0.25, p)
        }
    }
    ,
    class {
        name = "playercolor"
        level = 0

        // !playercolor (r) (g) (b) (optional: someone's name)
        function CC(p, args) {
            function IsCustomColorIntegerValid(x) {
                // if x is a string it will throw an error so we'll set it to -1 so it returns false
                try {
                    x = x.tointeger()
                } catch (err) {
                    x = -1
                }

                if (x >= 0 && x <= 255) {
                    return true
                }
                return false
            }

            if (args.len() < 3) {
                return SendChatMessage("Type in three valid RGB integers from 0 to 255 separated by a space.")
            }

            // make sure that all args are ints
            for (local i = 0; i < 3 ; i++) {
                if (IsCustomColorIntegerValid(args[i]) != true ) {
                    return SendChatMessage("Type in three valid RGB integers from 0 to 255 separated by a space.")
                }
                args[i] = args[i].tointeger()
            }

            local r = args[0]
            local g = args[1]
            local b = args[2]

            // Is there a name specified?
            try {
                args[3] = Strip(args[3])
                if (GetAdminLevel(p) >= 2) {
                    local plr = FindPlayerByName(args[3])
                    if (plr != null) {
                        p = plr
                    } else {
                        return SendChatMessage("[ERROR] Player not found.")
                    }
                } else {
                    return SendChatMessage("[ERROR] You need to have admin level 2 or higher to use on others.")
                }
            } catch (exception) {}

            // TODO: Change the player class stuff

            EntFireByHandle(p, "color", r + " " + g + " " + b, 0, p, p)
            SendChatMessage("Successfully changed color.")
        }
    }
    ,
    class {
        name = "adminmodify"
        level = 6

        // !adminmodify (player name) (new admin level)
        function CC(p, args) {
            try {
                args[0] = Strip(args[0])
                local plr = FindPlayerByName(args[0])
                try {
                    args[1] = Strip(args[1])
                    try {
                        if (typeof(args[1].tointeger()) == "integer") {
                            if (args[1].tointeger() >= 0 && args[1].tointeger() <= 6) {
                                Admins.push("[" + args[1].tointeger().tostring() + "]" + GetSteamID(plr.entindex()))
                            }
                        }
                    } catch (exception) {
                        SendChatMessage("[ERROR] Input a number after the player name to set a new admin level.")
                        return
                    }
                } catch (exception) {
                    if (plr != null) {
                        SendChatMessage(GetPlayerName(plr.entindex()) + "'s admin level: " + GetAdminLevel(plr))
                    } else {
                        SendChatMessage("[ERROR] Player not found.")
                    }
                }
            } catch (exception) {
                EntFireByHandle(p2mm_clientcommand, "Command", "say [ERROR] Input a player name.", 0, p, p)
            }
        }
    }
    // ,
    // class {
    //     name = "spectate"
    //     level = 0

    //     // !spectate
    //     function CC(p, args) {
    //         EntFireByHandle(p, "addoutput", "teamnumber 3", 0, p, p)
    //         EntFireByHandle(p2mm_clientcommand, "command", "spectate", 0, p, p)
    //         EntFireByHandle(p, "addoutput", "teamnumber 3", 3.71, p, p)
    //         EntFireByHandle(p2mm_clientcommand, "command", "spectate", 3.72, p, p)
    //     }
    // }
]

//--------------------------------------
// Chat command function dependencies
//
// Note: These aren't in functions.nut
// since there's no need to define them
// if the player chooses not to use CC
//--------------------------------------

function SendChatMessage(message, delay = 0) {
    EntFire("p2mm_servercommand", "command", "say " + message, delay)
}

function RunChatCommand(cmd, args, plr) {
    printl("(P2:MM): Running chat command: " + cmd.name)
    printl("(P2:MM): Player: " + GetPlayerName(plr.entindex()))
    cmd.CC(plr, args)
}

function GetPlayerFromUserID(userid) {
    local p = null
    while (p = Entities.FindByClassname(p, "player")) {
        if (p.entindex() == userid) {
            return p
        }
    }
    return null
}

function RemoveDangerousChars(str) {
    str = Replace(str, "%n", "") // Can cause crashes!
    if (StartsWith(str, "^")) {
        return ""
    }
    return str
}

// preserve = true : means that the symbol at the beginning of the string will be included in the first part
function SplitBetween(str, keysymbols, preserve = false) {
    local keys = StrToList(keysymbols)
    local lst = StrToList(str)

    local contin = false
    foreach (key in keys) {
        if (Contains(str, key)) {
            contin = true
            break
        }
    }

    if (!contin) {
        return []
    }


    // FOUND SOMETHING

    local split = []
    local curslice = ""

    foreach (indx, letter in lst) {
        local contains = false
        foreach (key in keys) {
            if (letter == key) {
                contains = key
                if (indx == 0 && preserve) {
                    curslice = curslice + letter
                }
            }
        }

        if (contains != false) {
            if (Len(curslice) > 0 && indx > 0) {
                split.push(curslice)
                if (preserve) {
                    curslice = contains
                } else {
                    curslice = ""
                }
            }
        } else {
            curslice = curslice + letter
        }
    }

    if (Len(curslice) > 0) {
        split.push(curslice)
    }

    return split
}

function FindPlayerByName(name) {
    name = name.tolower()
    local best = null
    local bestnamelen = 99999
    local bestfullname = ""

    local p = null
    while (p = Entities.FindByClassname(p, "player")) {
        local username = FindPlayerClass(p).username
        username = username.tolower()

        if (username == name) {
            return p
        }

        if (Len(Replace(username, name, "")) < Len(username) && Len(Replace(username, name, "")) < bestnamelen) {
            best = p
            bestnamelen = Len(Replace(username, name, ""))
            bestfullname = username
        } else if (Len(Replace(username, name, "")) < Len(username) && Len(Replace(username, name, "")) == bestnamelen) {
            if (Find(username, name) < Find(bestfullname, name)) {
                best = p
                bestnamelen = Len(Replace(username, name, ""))
                bestfullname = username
            }
        }
    }
    return best
}

function GetAdminLevel(plr) {
    foreach (admin in Admins) {
        // Seperate the SteamID and the admin level
        local level = split(admin, "[]")[0]
        local SteamID = split(admin, "]")[1]

        if (SteamID == FindPlayerClass(plr).steamid.tostring()) {
            if (SteamID == GetSteamID(1).tostring()) {
                // Host always has max perms even if defined lower
                if (level.tointeger() < 6) {
                    return 6
                }
                // In case we add more admin levels, return values defined higher than 6
                return level.tointeger()
            } else {
                // Use defined value for others
                return level.tointeger()
            }
        }
    }

    // For people who were not defined, check if it's the host
    if (FindPlayerClass(plr).steamid.tostring() == GetSteamID(1).tostring()) {
        // It is, so we automatically give the host max perms
        Admins.push("[6]" + GetSteamID(1))
        SendChatMessage("Added max permissions for " + GetPlayerName(1) + " as server operator.")
        return 6
    } else {
        // Not in Admins array nor are they the host
        return 0
    }
}
